# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(app LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "app")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# The master's engine, once built in its own repo (`dart build cli` in packages/lyra_node):
# LocalServerService looks for it in lyra_node/bin beside app.exe. Without it this computer
# can't become a master, and an offline sign in only shows the "no connection" placeholder.
set(LYRA_NODE_BUNDLE "${CMAKE_CURRENT_SOURCE_DIR}/../../../packages/lyra_node/build/cli/windows_x64/bundle")
if(EXISTS "${LYRA_NODE_BUNDLE}/bin/lyra_node.exe")
  # The engine outlives the app (plan D4), and Windows refuses to overwrite a running executable
  # or a library it loaded: a rebuild after closing the app would fail on them. When a file
  # changed, the installed engine is asked to stop cleanly first (`lyra_node stop`); the app
  # starts the new one when it opens. One that doesn't stop is moved aside (Windows lets a
  # running image be renamed), so the copy never fails; the `.old` files go on the next install.
  install(CODE "
    set(engine_dir \"${CMAKE_INSTALL_PREFIX}/lyra_node\")
    file(GLOB stale \"\${engine_dir}/bin/*.old\" \"\${engine_dir}/lib/*.old\")
    foreach(file IN LISTS stale)
      execute_process(COMMAND \"${CMAKE_COMMAND}\" -E rm -f \"\${file}\" RESULT_VARIABLE ignored ERROR_QUIET)
    endforeach()

    set(changed FALSE)
    foreach(part bin/lyra_node.exe lib/sqlcipher.dll)
      if(EXISTS \"\${engine_dir}/\${part}\")
        execute_process(COMMAND \"${CMAKE_COMMAND}\" -E compare_files \"\${engine_dir}/\${part}\" \"${LYRA_NODE_BUNDLE}/\${part}\" RESULT_VARIABLE differs)
        if(differs)
          set(changed TRUE)
        endif()
      endif()
    endforeach()

    if(changed)
      execute_process(COMMAND \"\${engine_dir}/bin/lyra_node.exe\" stop TIMEOUT 30 OUTPUT_VARIABLE answer ERROR_QUIET)
      if(NOT answer MATCHES \"\\\"stopped\\\":true\")
        message(WARNING \"lyra_node didn't stop (\${answer}): its files are moved aside\")
        string(TIMESTAMP moved \"%Y%m%d%H%M%S\")
        foreach(part bin/lyra_node.exe lib/sqlcipher.dll)
          if(EXISTS \"\${engine_dir}/\${part}\")
            file(RENAME \"\${engine_dir}/\${part}\" \"\${engine_dir}/\${part}.\${moved}.old\")
          endif()
        endforeach()
      endif()
    endif()
  " COMPONENT Runtime)
  install(DIRECTORY "${LYRA_NODE_BUNDLE}/"
    DESTINATION "${CMAKE_INSTALL_PREFIX}/lyra_node"
    COMPONENT Runtime)
else()
  message(WARNING "lyra_node is not built (${LYRA_NODE_BUNDLE}): this build can't host a master.")
endif()

# The web build the master serves to browsers (`flutter build web --release --no-web-resources-cdn`
# in this repo): NodeCommands.locateWeb looks for lyra_node/web beside app.exe. Without it a
# browser that reaches the master gets a 404; native devices work the same.
set(LYRA_WEB_BUILD "${CMAKE_CURRENT_SOURCE_DIR}/../build/web")
if(EXISTS "${LYRA_WEB_BUILD}/index.html")
  install(DIRECTORY "${LYRA_WEB_BUILD}/"
    DESTINATION "${CMAKE_INSTALL_PREFIX}/lyra_node/web"
    COMPONENT Runtime)
else()
  message(WARNING "The web build is missing (${LYRA_WEB_BUILD}): browsers can't open this master.")
endif()

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)

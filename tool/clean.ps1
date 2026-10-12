# Leaves the Windows app as on a first run: build cache, session and local preferences.
#   .\tool\clean.ps1           build + app data (Hive boxes, secure storage)
#   .\tool\clean.ps1 -Engine   also the master's engine data (%LOCALAPPDATA%\Lyra\node): its store, keys and paired devices
#   .\tool\clean.ps1 -NoBuild  app data only, keeps the build cache
param([switch]$Engine, [switch]$NoBuild)

Set-Location (Split-Path $PSScriptRoot)
$running = Get-Process app, lyra_node -ErrorAction SilentlyContinue
$running | Stop-Process -Force
# A killed process keeps its file handles until it has fully exited: deleting right away fails on home.hive.
$running | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue

$paths = @(
  (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'lyra'),   # Hive.initFlutter('lyra')
  (Join-Path $env:APPDATA 'com.example\app'),                          # flutter_secure_storage.dat
  (Join-Path $env:LOCALAPPDATA 'com.example\app')
)
if ($Engine) { $paths += Join-Path $env:LOCALAPPDATA 'Lyra\node' }

foreach ($p in $paths) {
  if (-not (Test-Path $p)) { continue }
  try { Remove-Item $p -Recurse -Force -ErrorAction Stop; Write-Host "removed $p" }
  catch { Write-Warning "could not remove ${p}: $($_.Exception.Message)" }
}

if (-not $NoBuild) {
  flutter clean
  flutter pub get
}

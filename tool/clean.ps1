# Leaves the Windows app as on a first run: build cache, session and local preferences.
#   .\tool\clean.ps1           build + app data (Hive boxes, secure storage)
#   .\tool\clean.ps1 -Engine   also the master's engine data (%LOCALAPPDATA%\Lyra\node): its store, keys and paired devices
#   .\tool\clean.ps1 -NoBuild  app data only, keeps the build cache
param([switch]$Engine, [switch]$NoBuild)

Set-Location (Split-Path $PSScriptRoot)
Get-Process app, lyra_node -ErrorAction SilentlyContinue | Stop-Process -Force

$paths = @(
  (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'lyra'),   # Hive.initFlutter('lyra')
  (Join-Path $env:APPDATA 'com.example\app'),                          # flutter_secure_storage.dat
  (Join-Path $env:LOCALAPPDATA 'com.example\app')
)
if ($Engine) { $paths += Join-Path $env:LOCALAPPDATA 'Lyra\node' }

foreach ($p in $paths) {
  if (Test-Path $p) { Remove-Item $p -Recurse -Force; Write-Host "removed $p" }
}

if (-not $NoBuild) {
  flutter clean
  flutter pub get
}

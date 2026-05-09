param(
  [Parameter(Mandatory = $false)]
  [string]$OutDir = '',

  [Parameter(Mandatory = $false)]
  [switch]$Clean
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }

if (-not $OutDir) {
  $OutDir = Join-Path $root 'dist'
}

$kitRoot = Join-Path $root 'package'
$metaPath = Join-Path $kitRoot 'gaeh-kit.json'
if (-not (Test-Path -LiteralPath $metaPath)) { throw "Missing kit metadata: $metaPath" }

$meta = (Get-Content -Raw -LiteralPath $metaPath) | ConvertFrom-Json
$version = $meta.version
if (-not $version) { throw "Missing version field in: $metaPath" }

Ensure-Dir $OutDir

$zipName = "gaeh-kit-v$version.zip"
$zipPath = Join-Path $OutDir $zipName

if ($Clean -and (Test-Path -LiteralPath $zipPath)) {
  Remove-Item -Force -LiteralPath $zipPath
}
if (Test-Path -LiteralPath $zipPath) {
  Write-Host "Already built: $zipPath"
  exit 0
}

Write-Host "Building: $zipPath"
Compress-Archive -Path (Join-Path $kitRoot '*') -DestinationPath $zipPath -CompressionLevel Optimal
Write-Host "Done."
Write-Host "Next: create a GitHub Release and upload: $zipName"

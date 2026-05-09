param(
  [Parameter(Mandatory = $true)]
  [string]$RepoOwner,

  [Parameter(Mandatory = $true)]
  [string]$RepoName,

  [Parameter(Mandatory = $false)]
  [string]$Tag = 'latest',

  [Parameter(Mandatory = $false)]
  [string]$Token = $null,

  [Parameter(Mandatory = $false)]
  [string]$AssetName = $null,

  [Parameter(Mandatory = $false)]
  [switch]$InstallShim,

  [Parameter(Mandatory = $false)]
  [switch]$AddToPathCurrentSession
)

$ErrorActionPreference = 'Stop'

function New-Headers([string]$Token) {
  $h = @{
    'Accept' = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
    'User-Agent' = 'gaeh-installer'
  }
  if ($Token) { $h['Authorization'] = "Bearer $Token" }
  return $h
}

function Fail([string]$Message) {
  Write-Host "GAEH install: FAIL - $Message" -ForegroundColor Red
  exit 2
}

function Info([string]$Message) {
  Write-Host "GAEH install: $Message"
}

$headers = New-Headers -Token $Token

if ($Tag -eq 'latest') {
  $releaseUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases/latest"
} else {
  $releaseUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases/tags/$Tag"
}

Info "Fetching release metadata: $releaseUrl"
try {
  $release = Invoke-RestMethod -Headers $headers -Uri $releaseUrl -Method Get
} catch {
  Fail "Cannot fetch release metadata. If this is a private repo, pass -Token <PAT>. Error: $($_.Exception.Message)"
}

if (-not $release.assets) { Fail "No assets found in the release. Upload gaeh-kit-v<version>.zip to the Release first." }

if (-not $AssetName) {
  $asset = $release.assets | Where-Object { $_.name -like 'gaeh-kit-v*.zip' } | Select-Object -First 1
  if (-not $asset) { $asset = $release.assets | Select-Object -First 1 }
} else {
  $asset = $release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
}

if (-not $asset) { Fail "Release asset not found." }

$downloadUrl = $asset.url  # API asset endpoint (requires Accept: octet-stream)
Info "Selected asset: $($asset.name)"

$tmpRoot = Join-Path $env:TEMP ("gaeh_install_" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null
$zipPath = Join-Path $tmpRoot $asset.name
$extractPath = Join-Path $tmpRoot 'kit'

Info "Downloading asset to: $zipPath"
try {
  $dlHeaders = New-Headers -Token $Token
  $dlHeaders['Accept'] = 'application/octet-stream'
  Invoke-WebRequest -Headers $dlHeaders -Uri $downloadUrl -OutFile $zipPath -Method Get | Out-Null
} catch {
  Fail "Download failed. If this is a private repo, pass -Token <PAT>. Error: $($_.Exception.Message)"
}

Info "Extracting..."
Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

$gaehPs1 = Join-Path $extractPath 'gaeh.ps1'
if (-not (Test-Path -LiteralPath $gaehPs1)) { Fail "Invalid kit zip: missing gaeh.ps1 at root of zip." }

if ($InstallShim) {
  Info "Installing shim to ~/.gaeh ..."
  & powershell -ExecutionPolicy Bypass -File $gaehPs1 install
  if ($AddToPathCurrentSession) {
    $binPath = Join-Path $env:USERPROFILE '.gaeh\bin'
    $env:PATH = "$binPath;$env:PATH"
    Info "Added to PATH for current session: $binPath"
  }
  Info "Done. Try: gaeh doctor -TargetPath <PROJECT>"
} else {
  Info "Kit extracted at: $extractPath"
  Info "Next:"
  Info "  - To install shim: powershell -ExecutionPolicy Bypass -File `"$gaehPs1`" install"
  Info "  - To init a project: powershell -ExecutionPolicy Bypass -File `"$gaehPs1`" init -TargetPath <PROJECT> -Adapters codex,cursor"
}


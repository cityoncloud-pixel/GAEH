param(
  [Parameter(Mandatory = $true)]
  [string]$RepoOwner,

  [Parameter(Mandatory = $true)]
  [string]$RepoName,

  [Parameter(Mandatory = $true)]
  [string]$Tag,

  [Parameter(Mandatory = $true)]
  [string]$Token,

  [Parameter(Mandatory = $false)]
  [string]$Name = $null,

  [Parameter(Mandatory = $false)]
  [string]$Body = '',

  [Parameter(Mandatory = $false)]
  [string]$AssetPath = (Join-Path (Join-Path $PSScriptRoot 'dist') 'gaeh-kit-v0.3.zip')
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
  Write-Host "GAEH release: FAIL - $Message" -ForegroundColor Red
  exit 2
}

function Info([string]$Message) {
  Write-Host "GAEH release: $Message"
}

if (-not (Test-Path -LiteralPath $AssetPath)) { Fail "Asset not found: $AssetPath" }
if (-not $Name) { $Name = $Tag }

$headers = @{
  'Accept' = 'application/vnd.github+json'
  'Authorization' = "Bearer $Token"
  'X-GitHub-Api-Version' = '2022-11-28'
  'User-Agent' = 'gaeh-release-script'
}

$apiBase = "https://api.github.com/repos/$RepoOwner/$RepoName"

Info "Creating release $Tag ..."
$payload = @{
  tag_name = $Tag
  name = $Name
  body = $Body
  draft = $false
  prerelease = $false
} | ConvertTo-Json -Depth 10

try {
  $release = Invoke-RestMethod -Headers $headers -Uri "$apiBase/releases" -Method Post -Body $payload -ContentType 'application/json'
} catch {
  Info "Create release failed (may already exist). Trying to fetch by tag: $Tag"
  try {
    $release = Invoke-RestMethod -Headers $headers -Uri "$apiBase/releases/tags/$Tag" -Method Get
  } catch {
    Fail "Create release failed and cannot fetch existing release by tag. Error: $($_.Exception.Message)"
  }
}

if (-not $release.upload_url) { Fail "Missing upload_url in response." }

$uploadUrl = ($release.upload_url -replace '{\\?name,label}', '')
$assetName = Split-Path -Leaf $AssetPath

Info "Uploading asset: $assetName"
$uploadUri = "$uploadUrl?name=$([Uri]::EscapeDataString($assetName))"

try {
  Invoke-RestMethod -Headers ($headers + @{ 'Content-Type' = 'application/zip' }) -Uri $uploadUri -Method Post -InFile $AssetPath
} catch {
  Fail "Upload asset failed. Error: $($_.Exception.Message)"
}

Info "Done. Release created: $($release.html_url)"

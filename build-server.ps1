param (
  [Parameter(Position=0, Mandatory)]
  [string]
  $HostImageName,
  [Parameter(Position=1, Mandatory)]
  [string]
  $HostTag,

  [Parameter(Position=2)]
  [string]
  $ImageName,

  [Parameter(Position=3)]
  [string]
  $BundleImageName,

  [Parameter(Position=4)]
  [string]
  $BundleTag,

  [Parameter(ValueFromRemainingArguments)]
  [string[]]
  $Options
)
$ErrorActionPreference = 'Stop';

$ImageName = if ($ImageName) { $ImageName } else { 'minecraft-server' }
$BundleImageName = if ($BundleImageName) { $BundleImageName } else { 'bundle' }
$BundleTag = if ($BundleTag) { $BundleTag } else { 'ltsc2019' }

$tag = '{0}:{1}-{2}' -f $ImageName, $HostImageName, $HostTag
Write-Host ('Build {0}' -f $tag) -ForegroundColor Green

$bundle = Get-Content '.\bundle.json' | ConvertFrom-Json
$pwsh = $bundle.items | Where-Object 'name' -EQ 'pwsh'
$pwshDirectory = '{0}' -f $pwsh.directory
$java = $bundle.items | Where-Object 'name' -EQ 'java'
$javaDirectory = '{0}' -f $java.directory

docker build -t $tag `
  --build-arg HOST_TAG=$HostTag `
  --build-arg BUNDLE_IMAGE_NAME=$BundleImageName `
  --build-arg BUNDLE_TAG=$BundleTag `
  --build-arg PWSH_BUNDLE_DIRECTORY=$pwshDirectory `
  --build-arg JAVA_BUNDLE_DIRECTORY=$javaDirectory `
  -f .\$HostImageName\Dockerfile `
  $Options .

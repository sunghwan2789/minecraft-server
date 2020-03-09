param (
  # Tag of bundle host
  [Parameter(Position=0, Mandatory)]
  [string]
  $HostTag,
  # Name of bundle image
  [Parameter(Position=1)]
  [string]
  $ImageName,
  # Extra options for docker build
  [Parameter(ValueFromRemainingArguments)]
  [string[]]
  $Options
)
# Not actually stop on local execution
$ErrorActionPreference = 'Stop';

$ImageName = if ($ImageName) { $ImageName } else { 'bundle' }

$bundle = Get-Content '.\bundle.json' | ConvertFrom-Json
foreach ($item in $bundle.items) {
  $tag = '{0}:{1}-{2}' -f $ImageName, $item.name, $HostTag
  Write-Host ('Build {0}' -f $tag) -ForegroundColor Green

  $buildArgs = @()
  if ($item.directory) {
    $buildArgs += '--build-arg'
    $buildArgs += 'BUILD_DESTINATION={0}' -f $item.directory
  }
  if ($item.home) {
    $buildArgs += '--build-arg'
    $buildArgs += 'BUNDLE_HOME={0}' -f $item.home
  }
  if ($item.url) {
    $buildArgs += '--build-arg'
    $buildArgs += 'BUNDLE_URL={0}' -f $item.url
  }
  if ($item.environment_variables) {
    $sb = [System.Text.StringBuilder]::new()
    foreach ($var in $item.environment_variables) {
      if ($sb.Length) {
        [void]$sb.Append('|')
      }
      [void]$sb.AppendFormat('{0}={1}', $var.name, $var.value)
    }
    $buildArgs += '--build-arg'
    $buildArgs += 'ENVIRONMENT_VARIABLES={0}' -f $sb.ToString()
  }
  if ($item.verify_command) {
    $buildArgs += '--build-arg'
    $buildArgs += 'VERIFY_COMMAND={0}' -f $item.verify_command
  }

  docker build -t $tag --pull `
    --build-arg HOST_TAG=$HostTag `
    $buildArgs `
    $Options bundle
}

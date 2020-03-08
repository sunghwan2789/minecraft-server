$ErrorActionPreference = 'Stop';
$ProgressPreference = 'SilentlyContinue';

if ($env:REPLACE_ENV_VARIABLES -eq "TRUE") {
  Write-Host "Replacing env variables in configs that match the prefix $env:ENV_VARIABLE_PREFIX..."
  # check if name of env variable matches the prefix
  # sanity check environment variables to avoid code injections
  # ???????????
  $variables = Get-ChildItem env: | Where-Object Name -Match "$env:ENV_VARIABLE_PREFIX*"
  foreach ($variable in $variables) {
    $name = $variable.Name
    $value = $variable.Value
    Write-Host "Replacing $name with $value ..."
    Get-ChildItem "/data/" -Filter "*.yml|*.yaml|*.txt|*.cfg|*.conf|*.properties" `
      | ForEach-Object {
        (Get-Content -Raw $_) -replace "`${$name}", $value | Out-File $_
      }
  }
}

& "$PSScriptRoot\start-minecraftFinalSetup.ps1"

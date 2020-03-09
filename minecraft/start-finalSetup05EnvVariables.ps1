$ErrorActionPreference = 'Stop';
$ProgressPreference = 'SilentlyContinue';

if ($env:REPLACE_ENV_VARIABLES -eq "TRUE") {
  Write-Host "Replacing env variables in configs that match the prefix $env:ENV_VARIABLE_PREFIX..."
  # check if name of env variable matches the prefix
  # sanity check environment variables to avoid code injections
  # [[ "$name" = $ENV_VARIABLE_PREFIX* ]] \
  #   && [[ $value =~ ^[0-9a-zA-Z_:/=?.+\-]*$ ]] \
  #   && [[ $name =~ ^[0-9a-zA-Z_\-]*$ ]]
  $variables = Get-ChildItem -Path env: | Where-Object { $_.Name -like "$env:ENV_VARIABLE_PREFIX*" }
  foreach ($variable in $variables) {
    $name = $variable.Name
    $value = $variable.Value
    Write-Host "Replacing $name with $value ..."
    Get-ChildItem -Path "/data/" -File `
      | Where-Object { $_.Name -match '\.(yml|yaml|txt|cfg|conf|properties)$' } `
      | ForEach-Object {
        (Get-Content -Path $_ -Raw) -replace "\`$\{$name\}", $value | Out-File $_
      }
  }
}

& $PSScriptRoot\start-minecraftFinalSetup.ps1

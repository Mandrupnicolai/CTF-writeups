[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$tests = Join-Path $root "tests"

if (-not (Get-Module -ListAvailable Pester)) {
  Write-Error "Pester is not available. Install it or run tests in an environment that has it."
}

Import-Module Pester -ErrorAction Stop | Out-Null

Invoke-Pester -Path $tests -EnableExit -Verbose


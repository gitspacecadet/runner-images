################################################################################
##  File:  Install-ChocolateyPackages.ps1
##  Desc:  Install common Chocolatey packages
################################################################################

# Refresh environment variables to ensure choco is in PATH
Update-Environment

# Verify choco is available
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: choco command not found in PATH. Checking if Chocolatey is installed..."
    if (Test-Path "C:\ProgramData\Chocolatey\bin\choco.exe") {
        Write-Host "Found choco.exe at C:\ProgramData\Chocolatey\bin\choco.exe. Adding to PATH..."
        $env:PATH = "C:\ProgramData\Chocolatey\bin;$env:PATH"
    } else {
        throw "Chocolatey is not installed or choco.exe not found"
    }
}

Write-Host "Chocolatey version: $(choco --version)"

$commonPackages = (Get-ToolsetContent).choco.common_packages

foreach ($package in $commonPackages) {
    Install-ChocoPackage $package.name -Version $package.version -ArgumentList $package.args
}

Invoke-PesterTests -TestFile "ChocoPackages"

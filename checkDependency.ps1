# Direct script without the variable wrapper
$scriptPath = Join-Path $PSScriptRoot "images\windows\templates\build.windows-2022.pkr.hcl"
$content = Get-Content $scriptPath -Raw

# Extract active scripts
$pattern = '\$\{path\.root\}\/\.\.\/scripts\/build\/Install-[A-Za-z0-9-]+\.ps1'
$activeScripts = [regex]::Matches($content, $pattern) | 
    ForEach-Object { $_.Value.Split('/')[-1] } |
    Where-Object { -not $_.StartsWith('#') }

Write-Host "Active installation scripts:"
$activeScripts | ForEach-Object { Write-Host "- $_" }

# Check for potential missing dependencies
$knownDependencies = @{
    # Version Control
    "Install-Git.ps1" = @("Install-GitHub-CLI.ps1")
    
    # PowerShell
    "Install-PowershellAzModules.ps1" = @("Install-PowershellModules.ps1")
    
    # Runtime Dependencies
    "Install-DotnetSDK.ps1" = @("Install-DotnetTools.ps1")
    "Install-NodeJS.ps1" = @("Install-Npm.ps1", "Install-Yarn.ps1")
    "Install-Python.ps1" = @("Install-Pip.ps1", "Install-PyPy.ps1")
    "Install-Ruby.ps1" = @("Install-Rubygems.ps1")
    
    # Build Tools
    "Install-Toolset.ps1" = @("Configure-Toolset.ps1")
    "Install-VCTools.ps1" = @("Install-LLVM.ps1", "Install-DotnetTool.ps1")
    
    # WebDrivers
    "Install-Chrome.ps1" = @("Install-EdgeDriver.ps1", "Install-Selenium.ps1")
    "Install-Firefox.ps1" = @("Install-Selenium.ps1")
    
    # Cloud Tools
    "Install-AzureCli.ps1" = @("Install-AzureDevOpsCli.ps1")
    "Install-AWSTools.ps1" = @("Install-Powershell.ps1")
    
    # Containers
    "Install-Docker.ps1" = @("Install-DockerWincred.ps1")
    
    # Android Development
    "Install-AndroidSDK.ps1" = @("Install-JavaTools.ps1")
    
    # Database Tools
    "Install-MongoDB.ps1" = @("Install-MysqlCli.ps1")
    "Install-PostgreSQL.ps1" = @("Install-SQLPowerShellTools.ps1")
    
    # Core System Tools
    "Install-ActionsCache.ps1" = @("Install-Git.ps1")  # Actions cache requires Git
}

Write-Host "`nChecking for missing dependencies..." -ForegroundColor Cyan

$missingDependencies = $false
foreach ($script in $activeScripts) {
    foreach ($dependentScript in $knownDependencies.Keys) {
        if ($script -eq $dependentScript) {
            foreach ($dependency in $knownDependencies[$dependentScript]) {
                if ($activeScripts -notcontains $dependency) {
                    Write-Host "⚠️ Warning: $script is active but may require $dependency" -ForegroundColor Yellow
                    $missingDependencies = $true
                }
            }
        }
    }
}

if (-not $missingDependencies) {
    Write-Host "✅ No missing dependencies detected!" -ForegroundColor Green
}
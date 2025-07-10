# Invoke-PesterTests "*"

# Import the TestsHelpers module
Import-Module (Join-Path $PSScriptRoot "Helpers.psm1") -Force

# Define tests for minimal Azure VMSS runner image based on installed components
$requiredTests = @(
    # Core Windows & PowerShell
    "PowerShellModules",    # PowerShell modules + Azure PowerShell modules
    "WindowsFeatures",      # Windows features and defender config
    
    # Package Management
    "ChocoPackages",        # Chocolatey and packages installed via choco
    
    # Container Platform
    "Docker",               # Docker, DockerCompose, DockerWinCred, DockerImages
    
    # Development Tools & Runtimes
    "Tools",                # PowerShell Core, WebPI, OpenSSL, Git, EdgeDriver, 
                           # IEWebDriver, DotNet SDK, Sbt, TortoiseSvn, RootCA
    
    # Runner Infrastructure
    "RunnerCache",          # GitHub Actions cache and runner setup
    
    # CLI Tools
    "CLI.Tools"            # Azure CLI, Azure DevOps CLI, GitHub CLI
)

Write-Host "Running tests for minimal Azure VMSS runner image..." -ForegroundColor Cyan
Write-Host "Testing $($requiredTests.Count) component groups based on installed tools" -ForegroundColor Yellow

$failedTests = @()
$passedTests = @()

foreach ($testName in $requiredTests) {
    Write-Host "`nRunning test: $testName" -ForegroundColor Yellow
    try {
        # Use the helper function - it expects just the base name
        $result = Invoke-PesterTests -TestFile $testName
        
        if ($result -and $result.FailedCount -eq 0) {
            $passedTests += $testName
            Write-Host "✅ $testName test completed successfully" -ForegroundColor Green
        } else {
            $failedTests += $testName
            Write-Host "❌ $testName test failed" -ForegroundColor Red
        }
    }
    catch {
        $failedTests += $testName
        Write-Host "❌ $testName test failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Summary for Azure VMSS runner validation
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "AZURE VMSS RUNNER IMAGE VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "✅ Passed: $($passedTests.Count)" -ForegroundColor Green
Write-Host "❌ Failed: $($failedTests.Count)" -ForegroundColor Red

if ($failedTests.Count -eq 0) {
    Write-Host "`n🎉 All tests passed! Azure VMSS runner image is ready for deployment." -ForegroundColor Green
} else {
    Write-Host "`n💥 Some tests failed. Please review the Azure VMSS runner image configuration." -ForegroundColor Red
    $failedTests | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    throw "Azure VMSS runner image validation failed"
}

Write-Host "`nAzure VMSS runner image validation completed successfully!" -ForegroundColor Green
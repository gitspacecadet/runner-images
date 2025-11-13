[CmdletBinding()]
param()

# BcCache.Tests.ps1
# Validates Business Central cache priming performed by Create-BcContainer.ps1
# Skips gracefully if BC cache was intentionally disabled via BC_CACHE_SKIP

$ErrorActionPreference = 'Stop'

Describe "Business Central Cache" -Tag 'BC','Cache' {
    $skip = $env:BC_CACHE_SKIP -and $env:BC_CACHE_SKIP.ToString().ToLower() -in @('1','true','yes','y')
    if ($skip) {
        It "Skipped because BC_CACHE_SKIP is set" {
            $true | Should -BeTrue
        }
        return
    }

    It "BcContainerHelper module is available" {
        (Get-Module -ListAvailable -Name BcContainerHelper) | Should -Not -BeNullOrEmpty
    }

    $cacheDir = if ($env:BC_CACHE_DIR) { $env:BC_CACHE_DIR } else { 'C:\bcartifacts.cache' }

    It "Cache directory exists: $cacheDir" {
        Test-Path $cacheDir | Should -BeTrue
    }

    $metadataPath = Join-Path $cacheDir 'bc-cache-metadata.json'
    It "Metadata file exists" {
        Test-Path $metadataPath | Should -BeTrue
    }

    $metadata = if (Test-Path $metadataPath) { Get-Content $metadataPath -Raw | ConvertFrom-Json } else { $null }

    It "Metadata contains expected keys" {
        $expected = 'timestampUtc','hostOsVersion','genericImage','artifactUrl','country','type','select','cacheDir'
        $missing = $expected | Where-Object { -not ($metadata.PSObject.Properties.Name -contains $_) }
        $missing | Should -BeNullOrEmpty
    }

    Context "Docker image presence" {
        # docker may not be available in certain test contexts; handle gracefully
        $dockerExists = Get-Command docker -ErrorAction SilentlyContinue
        It "Docker CLI is present" -Skip:(!$dockerExists) {
            $dockerExists | Should -Not -BeNullOrEmpty
        }
        if ($dockerExists) {
            $genericImage = $metadata.genericImage
            It "Generic BC image '$genericImage' pulled" -Skip:([string]::IsNullOrWhiteSpace($genericImage)) {
                $images = docker images --format '{{json .}}' | ForEach-Object { $_ | ConvertFrom-Json }
                ($images | Where-Object { $_.Repository + ':' + $_.Tag -eq $genericImage }) | Should -Not -BeNullOrEmpty
            }
        }
    }
}

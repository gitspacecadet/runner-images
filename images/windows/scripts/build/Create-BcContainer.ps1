################################################################################
##  File:  Create-BcContainer.ps1
##  Desc:  Pre-caches Business Central (BC) generic image and artifacts so that
##         future container creation on the runner is faster.
##
##  Behavior:
##   - Skips execution if BC_CACHE_SKIP=true environment variable is set
##   - Parameterizable via env vars:
##       BC_COUNTRY (default: us)
##       BC_TYPE (default: Sandbox)
##       BC_SELECT (default: Latest)
##       BC_CACHE_DIR (default: C:\bcartifacts-cache)
##   - Writes a metadata file to C:\bcartifacts-cache\bc-cache-metadata.json
##
##  NOTE: This script purposefully does NOT create a running container to keep
##        image size lower; it only pulls the generic base image and downloads
##        artifacts including platform.
################################################################################
set-strictmode -version latest
$ErrorActionPreference = 'Stop'

if ($env:BC_CACHE_SKIP -and $env:BC_CACHE_SKIP.ToString().ToLower() -in @('1','true','yes','y')) {
	Write-Host "[BC CACHE] Skipping Business Central cache priming because BC_CACHE_SKIP=$($env:BC_CACHE_SKIP)"
	return
}

Write-Host "[BC CACHE] Starting Business Central cache priming" -ForegroundColor Cyan

function Invoke-Section {
	param(
		[Parameter(Mandatory)][string]$Name,
		[Parameter(Mandatory)][scriptblock]$Action
	)
	Write-Host "[BC CACHE] >>> $Name" -ForegroundColor Yellow
	& $Action
	Write-Host "[BC CACHE] <<< $Name" -ForegroundColor DarkYellow
}

Invoke-Section -Name 'Install BcContainerHelper' -Action {
	if (-not (Get-Module -ListAvailable -Name BcContainerHelper)) {
		Write-Host "Installing BcContainerHelper module"
		Install-Module -Name BcContainerHelper -Force -AllowClobber | Out-Null
	} else {
		Write-Host "BcContainerHelper already present"
	}
	Import-Module BcContainerHelper -Force
}

$hostOsVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
Write-Host "[BC CACHE] Host OS Version: $hostOsVersion"

$genericImageName = Get-BestGenericImageName -hostOsVersion $hostOsVersion
Write-Host "[BC CACHE] Generic image determined: $genericImageName"

Invoke-Section -Name 'Pull generic BC image' -Action {
	docker pull $genericImageName
	if ($LASTEXITCODE -ne 0) { throw "Failed to pull generic BC image $genericImageName (exit $LASTEXITCODE)" }
}

$country = if ($env:BC_COUNTRY) { $env:BC_COUNTRY } else { 'us' }
$type    = if ($env:BC_TYPE) { $env:BC_TYPE } else { 'Sandbox' }
$select  = if ($env:BC_SELECT) { $env:BC_SELECT } else { 'Latest' }
$cacheDir = if ($env:BC_CACHE_DIR) { $env:BC_CACHE_DIR } else { 'C:\\bcartifacts-cache' }

New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
Write-Host "[BC CACHE] Using cache directory: $cacheDir"

Invoke-Section -Name 'Resolve artifact URL' -Action {
	$script:artifactUrl = Get-BCArtifactUrl -type $type -country $country -select $select
	if (-not $script:artifactUrl) { throw 'Artifact URL resolution returned empty result' }
	Write-Host "[BC CACHE] Artifact URL: $script:artifactUrl"
}

Invoke-Section -Name 'Download artifacts' -Action {
	Download-Artifacts -artifactUrl $script:artifactUrl -includePlatform -force -basePath $cacheDir
}

Invoke-Section -Name 'Write metadata' -Action {
	$metadata = [ordered]@{
		timestampUtc = (Get-Date).ToUniversalTime().ToString('o')
		hostOsVersion = $hostOsVersion
		genericImage = $genericImageName
		artifactUrl = $script:artifactUrl
		country = $country
		type = $type
		select = $select
		cacheDir = $cacheDir
	}
	$metadataPath = Join-Path $cacheDir 'bc-cache-metadata.json'
	$metadata | ConvertTo-Json -Depth 5 | Out-File -FilePath $metadataPath -Encoding UTF8
	Write-Host "[BC CACHE] Metadata written: $metadataPath"
}

Write-Host "[BC CACHE] Completed Business Central cache priming" -ForegroundColor Green
param(
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $ResourceGroupName,
    [String] [Parameter (Mandatory=$true)] $ManagedImageName,
    [String] [Parameter (Mandatory=$true)] $GalleryName,
    [String] [Parameter (Mandatory=$true)] $GalleryResourceGroupName,
    [String] [Parameter (Mandatory=$true)] $GalleryImageName,
    [String] [Parameter (Mandatory=$true)] $GalleryImageVersion,
    [String] [Parameter (Mandatory=$true)] $Location,
    [String] [Parameter (Mandatory=$false)] $StorageAccountType = "Standard_LRS",
    [String] [Parameter (Mandatory=$false)] $ReplicationRegions = "",
    [String] [Parameter (Mandatory=$false)] $CleanupManagedImage = "true",
    [hashtable] [Parameter (Mandatory=$false)] $Tags = @{}
)

Write-Host "🚀 Starting Two-Stage Image Build Process - Stage 2: Uploading to Azure Compute Gallery"

# Set Azure context
Write-Host "🔐 Setting Azure subscription context"
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to set Azure subscription context"
    exit 1
}

# Get the managed image resource ID
Write-Host "🔍 Getting managed image resource ID"
$managedImageId = az image show `
    --resource-group $ResourceGroupName `
    --name $ManagedImageName `
    --query "id" `
    --output tsv

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($managedImageId)) {
    Write-Error "❌ Failed to find managed image '$ManagedImageName' in resource group '$ResourceGroupName'"
    exit 1
}

Write-Host "✅ Found managed image: $managedImageId"

# Prepare replication regions (default to the same location as the image)
$replicationRegionsList = @($Location)
if (-not [string]::IsNullOrEmpty($ReplicationRegions)) {
    $replicationRegionsList = $ReplicationRegions.Split(",") | ForEach-Object { $_.Trim() }
}

Write-Host "📍 Replication regions: $($replicationRegionsList -join ', ')"

# Build target regions parameter for Azure CLI (simplified approach)
$targetRegionsArgs = @()
foreach ($region in $replicationRegionsList) {
    $targetRegionsArgs += @("--target-regions", $region, "regionalReplicaCount=1", "storageAccountType=$StorageAccountType")
}

# Create image version in the gallery
Write-Host "📤 Uploading managed image to Azure Compute Gallery"
Write-Host "   → Gallery: $GalleryName"
Write-Host "   → Image Definition: $GalleryImageName"
Write-Host "   → Version: $GalleryImageVersion"

$uploadCommand = @(
    "az", "sig", "image-version", "create",
    "--resource-group", $GalleryResourceGroupName,
    "--gallery-name", $GalleryName,
    "--gallery-image-definition", $GalleryImageName,
    "--gallery-image-version", $GalleryImageVersion,
    "--managed-image", $managedImageId,
    "--output", "json"
)

# Add target regions
$uploadCommand += $targetRegionsArgs

# Add tags if provided
if ($Tags.Count -gt 0) {
    $tagsString = ($Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join " "
    $uploadCommand += @("--tags", $tagsString)
}

Write-Host "🔄 Executing upload command..."
$result = & $uploadCommand[0] $uploadCommand[1..($uploadCommand.Length-1)]
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "✅ Stage 2 Complete: Image successfully uploaded to Azure Compute Gallery"
    
    # Parse the result to get image information
    $imageInfo = $result | ConvertFrom-Json
    $imageId = $imageInfo.id
    $provisioningState = $imageInfo.provisioningState
    
    Write-Host "   → Image ID: $imageId"
    Write-Host "   → Provisioning State: $provisioningState"
    
    # Verify the image version exists
    Write-Host "🔍 Verifying image version in gallery..."
    az sig image-version show `
        --resource-group $GalleryResourceGroupName `
        --gallery-name $GalleryName `
        --gallery-image-definition $GalleryImageName `
        --gallery-image-version $GalleryImageVersion `
        --query "{id:id, provisioningState:provisioningState, publishingProfile:publishingProfile}" `
        --output table
    
    # Cleanup managed image if requested
    if ($CleanupManagedImage -eq "true") {
        Write-Host "🧹 Cleaning up managed image (as requested)"
        az image delete `
            --resource-group $ResourceGroupName `
            --name $ManagedImageName `
            --yes
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Managed image '$ManagedImageName' deleted successfully"
        } else {
            Write-Warning "⚠️ Failed to delete managed image '$ManagedImageName' - you may need to clean it up manually"
        }
    } else {
        Write-Host "ℹ️ Managed image '$ManagedImageName' retained (cleanup disabled)"
    }
    
    Write-Host "🎉 Two-stage build process completed successfully!"
    Write-Host "   → Managed image was created and uploaded to gallery"
    Write-Host "   → Image is now available for VMSS deployment"
    
} else {
    Write-Error "❌ Stage 2 Failed: Failed to upload managed image to gallery (exit code: $exitCode)"
    Write-Error "Result: $result"
    exit $exitCode
}

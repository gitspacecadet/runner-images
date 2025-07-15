param(
    [String] [Parameter (Mandatory=$true)] $TemplatePath,
    [String] [Parameter (Mandatory=$true)] $BuildTemplateName,
    [String] [Parameter (Mandatory=$true)] $ClientId,
    [String] [Parameter (Mandatory=$false)] $ClientSecret,
    [String] [Parameter (Mandatory=$true)] $Location,
    [String] [Parameter (Mandatory=$true)] $ImageName,
    [String] [Parameter (Mandatory=$true)] $ImageResourceGroupName,
    [String] [Parameter (Mandatory=$true)] $TempResourceGroupName,
    [String] [Parameter (Mandatory=$true)] $SubscriptionId,
    [String] [Parameter (Mandatory=$true)] $TenantId,
    [String] [Parameter (Mandatory=$true)] $ImageOS, # e.g. "ubuntu22", "ubuntu22" or "win19", "win22", "win25"
    [String] [Parameter (Mandatory=$false)] $UseAzureCliAuth = "false",
    [String] [Parameter (Mandatory=$false)] $PluginVersion = "2.3.3",
    [String] [Parameter (Mandatory=$false)] $VirtualNetworkName,
    [String] [Parameter (Mandatory=$false)] $VirtualNetworkRG,
    [String] [Parameter (Mandatory=$false)] $VirtualNetworkSubnet,
    [String] [Parameter (Mandatory=$false)] $AllowedInboundIpAddresses = "[]",
    [hashtable] [Parameter (Mandatory=$false)] $Tags = @{}
)

Write-Host "🚀 Starting Two-Stage Image Build Process - Stage 1: Building Managed Image"

if (-not (Test-Path $TemplatePath))
{
    Write-Error "'-TemplatePath' parameter is not valid. You have to specify correct Template Path"
    exit 1
}

$buildName = $($BuildTemplateName).Split(".")[1]
$InstallPassword = [System.GUID]::NewGuid().ToString().ToUpper()

$SensitiveData = @(
    'OSType',
    'StorageAccountLocation',
    'OSDiskUri',
    'OSDiskUriReadOnlySas',
    'TemplateUri',
    'TemplateUriReadOnlySas',
    ':  ->'
)

$azure_tags = $Tags | ConvertTo-Json -Compress

Write-Host "📋 Show Packer Version"
packer --version

Write-Host "📦 Download packer plugins"
packer plugins install github.com/hashicorp/azure $pluginVersion

Write-Host "✅ Validate packer template"
packer validate -syntax-only -only "$buildName*" $TemplatePath

Write-Host "🔨 Build $buildName Managed Image (Stage 1 of 2)"
Write-Host "   → Creating managed image only (no gallery upload)"
Write-Host "   → Gallery upload will be handled in Stage 2"

# Build the managed image only - disable gallery upload by not setting gallery variables
packer build    -only "$buildName*" `
                -var "client_id=$ClientId" `
                -var "client_secret=$ClientSecret" `
                -var "install_password=$InstallPassword" `
                -var "location=$Location" `
                -var "image_os=$ImageOS" `
                -var "managed_image_name=$ImageName" `
                -var "managed_image_resource_group_name=$ImageResourceGroupName" `
                -var "subscription_id=$SubscriptionId" `
                -var "temp_resource_group_name=$TempResourceGroupName" `
                -var "tenant_id=$TenantId" `
                -var "virtual_network_name=$VirtualNetworkName" `
                -var "virtual_network_resource_group_name=$VirtualNetworkRG" `
                -var "virtual_network_subnet_name=$VirtualNetworkSubnet" `
                -var "allowed_inbound_ip_addresses=$($AllowedInboundIpAddresses)" `
                -var "use_azure_cli_auth=$UseAzureCliAuth" `
                -var "azure_tags=$azure_tags" `
                -var "gallery_name=" `
                -var "gallery_resource_group_name=" `
                -var "gallery_image_name=" `
                -var "gallery_image_version=" `
                -color=false `
                $TemplatePath `
        | Where-Object {
            #Filter sensitive data from Packer logs
            $currentString = $_
            $sensitiveString = $SensitiveData | Where-Object { $currentString -match $_ }
            $sensitiveString -eq $null
        }

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Stage 1 Complete: Managed image '$ImageName' created successfully"
    Write-Host "   → Resource Group: $ImageResourceGroupName"
    Write-Host "   → Location: $Location"
    Write-Host "   → Next: Stage 2 will upload this managed image to Azure Compute Gallery"
} else {
    Write-Error "❌ Stage 1 Failed: Managed image creation failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

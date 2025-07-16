using module ./software-report-base/SoftwareReport.psm1
using module ./software-report-base/SoftwareReport.Nodes.psm1

$global:ErrorActionPreference = "Stop"
$global:ProgressPreference = "SilentlyContinue"
$ErrorView = "NormalView"
Set-StrictMode -Version Latest

# Import-Module (Join-Path $PSScriptRoot "SoftwareReport.Android.psm1") -DisableNameChecking
# Import-Module (Join-Path $PSScriptRoot "SoftwareReport.Browsers.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "SoftwareReport.CachedTools.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "SoftwareReport.Common.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "SoftwareReport.Databases.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "SoftwareReport.Helpers.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "SoftwareReport.Tools.psm1") -DisableNameChecking
# Import-Module (Join-Path $PSScriptRoot "SoftwareReport.Java.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "SoftwareReport.WebServers.psm1") -DisableNameChecking
# Import-Module (Join-Path $PSScriptRoot "SoftwareReport.VisualStudio.psm1") -DisableNameChecking

# Software report
$softwareReport = [SoftwareReport]::new($(Build-OSInfoSection))
$optionalFeatures = $softwareReport.Root.AddHeader("Windows features")
$optionalFeatures.AddToolVersion("Windows Subsystem for Linux (WSLv1):", "Enabled")
if (Test-IsWin25) {
    $optionalFeatures.AddToolVersion("Windows Subsystem for Linux (Default, WSLv2):", $(Get-WSL2Version))
}
$installedSoftware = $softwareReport.Root.AddHeader("Installed Software")

# Language and Runtime
$languageAndRuntime = $installedSoftware.AddHeader("Language and Runtime")
# $languageAndRuntime.AddToolVersion("Bash", $(Get-BashVersion))
# $languageAndRuntime.AddToolVersion("Go", $(Get-GoVersion))
# $languageAndRuntime.AddToolVersion("Julia", $(Get-JuliaVersion))
# $languageAndRuntime.AddToolVersion("Kotlin", $(Get-KotlinVersion))
# $languageAndRuntime.AddToolVersion("LLVM", $(Get-LLVMVersion))
# $languageAndRuntime.AddToolVersion("Node", $(Get-NodeVersion))
# $languageAndRuntime.AddToolVersion("Perl", $(Get-PerlVersion))
# $languageAndRuntime.AddToolVersion("PHP", $(Get-PHPVersion))
# $languageAndRuntime.AddToolVersion("Python", $(Get-PythonVersion))
# $languageAndRuntime.AddToolVersion("Ruby", $(Get-RubyVersion))

# Package Management
$packageManagement = $installedSoftware.AddHeader("Package Management")
$packageManagement.AddToolVersion("Chocolatey", $(Get-ChocoVersion))
# $packageManagement.AddToolVersion("Composer", $(Get-ComposerVersion))
# $packageManagement.AddToolVersion("Helm", $(Get-HelmVersion))
# $packageManagement.AddToolVersion("Miniconda", $(Get-CondaVersion))
# $packageManagement.AddToolVersion("NPM", $(Get-NPMVersion))
$packageManagement.AddToolVersion("NuGet", $(Get-NugetVersion))
# $packageManagement.AddToolVersion("pip", $(Get-PipVersion))         # Python not in minimal image
# $packageManagement.AddToolVersion("Pipx", $(Get-PipxVersion))       # Python not in minimal image
# $packageManagement.AddToolVersion("RubyGems", $(Get-RubyGemsVersion)) # Ruby not in minimal image
# $packageManagement.AddToolVersion("Vcpkg", $(Get-VcpkgVersion))     # C++ vcpkg not in minimal image
# $packageManagement.AddToolVersion("Yarn", $(Get-YarnVersion))  # Yarn removed from minimal image

$packageManagement.AddHeader("Environment variables").AddTable($(Build-PackageManagementEnvironmentTable))

# Project Management
$projectManagement = $installedSoftware.AddHeader("Project Management")
# $projectManagement.AddToolVersion("Ant", $(Get-AntVersion))        # Java build tool not in minimal image
# $projectManagement.AddToolVersion("Gradle", $(Get-GradleVersion))  # Java build tool not in minimal image
# $projectManagement.AddToolVersion("Maven", $(Get-MavenVersion))    # Java build tool not in minimal image
# $projectManagement.AddToolVersion("sbt", $(Get-SbtVersion))        # Scala build tool not in minimal image

# Tools
$tools = $installedSoftware.AddHeader("Tools")
$tools.AddToolVersion("7zip", $(Get-7zipVersion))                    # In Chocolatey packages
# $tools.AddToolVersion("aria2", $(Get-Aria2Version))                # Not in minimal image
$tools.AddToolVersion("azcopy", $(Get-AzCopyVersion))                # In Chocolatey packages
# $tools.AddToolVersion("Bazel", $(Get-BazelVersion))                # Not in minimal image
# $tools.AddToolVersion("Bazelisk", $(Get-BazeliskVersion))          # Not in minimal image
# $tools.AddToolVersion("Bicep", $(Get-BicepVersion))                # Not in minimal image
# $tools.AddToolVersion("Cabal", $(Get-CabalVersion))                # Haskell tool not in minimal image
# $tools.AddToolVersion("CMake", $(Get-CMakeVersion))                # Not in minimal image
# $tools.AddToolVersion("CodeQL Action Bundle", $(Get-CodeQLBundleVersion)) # Not in minimal image
$tools.AddToolVersion("Docker", $(Get-DockerVersion))                # In toolset
# $tools.AddToolVersion("Docker Compose v2", $(Get-DockerComposeVersionV2)) # Commented out in build template
$tools.AddToolVersion("Docker-wincred", $(Get-DockerWincredVersion)) # In build template
# $tools.AddToolVersion("ghc", $(Get-GHCVersion))                    # Haskell compiler not in minimal image
$tools.AddToolVersion("Git", $(Get-GitVersion))                      # In build template
$tools.AddToolVersion("Git LFS", $(Get-GitLFSVersion))              # Usually comes with Git
if (Test-IsWin19) {
    # $tools.AddToolVersion("Google Cloud CLI", $(Get-GoogleCloudCLIVersion)) # Not in minimal image
}
$tools.AddToolVersion("ImageMagick", $(Get-ImageMagickVersion))      # In Chocolatey packages
if (-not (Test-IsWin25)) {
    # $tools.AddToolVersion("InnoSetup", $(Get-InnoSetupVersion))      # Not in minimal image
}
$tools.AddToolVersion("jq", $(Get-JQVersion))                        # In Chocolatey packages
# $tools.AddToolVersion("Kind", $(Get-KindVersion))                   # Kubernetes tool not in minimal image
# $tools.AddToolVersion("Kubectl", $(Get-KubectlVersion))             # Kubernetes tool not in minimal image
if (-not (Test-IsWin25)) {
    # $tools.AddToolVersion("Mercurial", $(Get-MercurialVersion))     # Not in minimal image
}
# $tools.AddToolVersion("gcc", $(Get-GCCVersion))                     # C compiler not in minimal image
# $tools.AddToolVersion("gdb", $(Get-GDBVersion))                     # Debugger not in minimal image
# $tools.AddToolVersion("GNU Binutils", $(Get-GNUBinutilsVersion))   # Not in minimal image
# $tools.AddToolVersion("Newman", $(Get-NewmanVersion))               # Postman CLI not in minimal image
if (-not (Test-IsWin25)) {
    # $tools.AddToolVersion("NSIS", $(Get-NSISVersion))               # Installer tool in toolset but might not be installed yet
}
$tools.AddToolVersion("OpenSSL", $(Get-OpenSSLVersion))              # In toolset
$tools.AddToolVersion("Packer", $(Get-PackerVersion))                # In Chocolatey packages
if (Test-IsWin19) {
    # $tools.AddToolVersion("Parcel", $(Get-ParcelVersion))           # Node.js bundler not in minimal image
}
# $tools.AddToolVersion("Pulumi", $(Get-PulumiVersion))               # Infrastructure tool not in minimal image
# $tools.AddToolVersion("R", $(Get-RVersion))                         # R language not in minimal image
# $tools.AddToolVersion("Service Fabric SDK", $(Get-ServiceFabricSDKVersion)) # Not in minimal image
# $tools.AddToolVersion("Stack", $(Get-StackVersion))                 # Haskell tool not in minimal image
if (-not (Test-IsWin25)) {
    # $tools.AddToolVersion("Subversion (SVN)", $(Get-SVNVersion))    # Not in minimal image
}
# $tools.AddToolVersion("Swig", $(Get-SwigVersion))                   # Not in minimal image
# $tools.AddToolVersion("VSWhere", $(Get-VSWhereVersion))             # Visual Studio tool not needed in minimal image
# $tools.AddToolVersion("WinAppDriver", $(Get-WinAppDriver))          # Not in minimal image
# $tools.AddToolVersion("WiX Toolset", $(Get-WixVersion))             # Not in minimal image
# $tools.AddToolVersion("yamllint", $(Get-YAMLLintVersion))           # Python tool not in minimal image
# $tools.AddToolVersion("zstd", $(Get-ZstdVersion))                   # Not in minimal image
# $tools.AddToolVersion("Ninja", $(Get-NinjaVersion))                 # Build tool not in minimal image

# CLI Tools
$cliTools = $installedSoftware.AddHeader("CLI Tools")
if (-not (Test-IsWin25)) {
    # $cliTools.AddToolVersion("Alibaba Cloud CLI", $(Get-AlibabaCLIVersion)) # Not in minimal image
}
# $cliTools.AddToolVersion("AWS CLI", $(Get-AWSCLIVersion))           # Not in minimal image
# $cliTools.AddToolVersion("AWS SAM CLI", $(Get-AWSSAMVersion))       # Not in minimal image
# $cliTools.AddToolVersion("AWS Session Manager CLI", $(Get-AWSSessionManagerVersion)) # Not in minimal image
# $cliTools.AddToolVersion("Azure CLI", $(Get-AzureCLIVersion))       # Might be installed, but could fail
# $cliTools.AddToolVersion("Azure DevOps CLI extension", $(Get-AzureDevopsExtVersion)) # Extension might not be installed
if (Test-IsWin19) {
    # $cliTools.AddToolVersion("Cloud Foundry CLI", $(Get-CloudFoundryVersion)) # Not in minimal image
}
$cliTools.AddToolVersion("GitHub CLI", $(Get-GHVersion))             # In build template

# Rust Tools - Comment out entire section since Rust not in minimal image
# Initialize-RustEnvironment
# $rustTools = $installedSoftware.AddHeader("Rust Tools")
# $rustTools.AddToolVersion("Cargo", $(Get-RustCargoVersion))
# $rustTools.AddToolVersion("Rust", $(Get-RustVersion))
# $rustTools.AddToolVersion("Rustdoc", $(Get-RustdocVersion))
# $rustTools.AddToolVersion("Rustup", $(Get-RustupVersion))

# $rustToolsPackages = $rustTools.AddHeader("Packages")
# if (-not (Test-IsWin25)) {
#     $rustToolsPackages.AddToolVersion("bindgen", $(Get-BindgenVersion))
#     $rustToolsPackages.AddToolVersion("cargo-audit", $(Get-CargoAuditVersion))
#     $rustToolsPackages.AddToolVersion("cargo-outdated", $(Get-CargoOutdatedVersion))
#     $rustToolsPackages.AddToolVersion("cbindgen", $(Get-CbindgenVersion))
# }
# $rustToolsPackages.AddToolVersion("Clippy", $(Get-RustClippyVersion))
# $rustToolsPackages.AddToolVersion("Rustfmt", $(Get-RustfmtVersion))

# Browsers and Drivers - Comment out since browsers not in minimal image
# $browsersAndWebdrivers = $installedSoftware.AddHeader("Browsers and Drivers")
# $browsersAndWebdrivers.AddNodes($(Build-BrowserSection))
# $browsersAndWebdrivers.AddHeader("Environment variables").AddTable($(Build-BrowserWebdriversEnvironmentTable))

# Java - Comment out since Java not in minimal image  
# $installedSoftware.AddHeader("Java").AddTable($(Get-JavaVersions))

# Shells
$installedSoftware.AddHeader("Shells").AddTable($(Get-ShellTarget))

# MSYS2 - Comment out since MSYS2 not in minimal image
# $msys2 = $installedSoftware.AddHeader("MSYS2")
# $msys2.AddToolVersion("Pacman", $(Get-PacmanVersion))

# $notes = @'
# Location: C:\msys64

# Note: MSYS2 is pre-installed on image but not added to PATH.
# '@
# $msys2.AddHeader("Notes").AddNote($notes)

# BizTalk Server - Comment out since BizTalk not in minimal image
# if (Test-IsWin19)
# {
#     $installedSoftware.AddHeader("BizTalk Server").AddNode($(Get-BizTalkVersion))
# }

# Cached Tools - Comment out since likely not in minimal image
# $installedSoftware.AddHeader("Cached Tools").AddNodes($(Build-CachedToolsSection))

# Databases - Comment out since databases not in minimal image
# $databases = $installedSoftware.AddHeader("Databases")
# $databases.AddHeader("PostgreSQL").AddTable($(Get-PostgreSQLTable))
# $databases.AddHeader("MongoDB").AddTable($(Get-MongoDBTable))

# Database tools - Comment out since databases not in minimal image
# $databaseTools = $installedSoftware.AddHeader("Database tools")
# $databaseTools.AddToolVersion("Azure CosmosDb Emulator", $(Get-AzCosmosDBEmulatorVersion))
# $databaseTools.AddToolVersion("DacFx", $(Get-DacFxVersion))
# $databaseTools.AddToolVersion("MySQL", $(Get-MySQLVersion))
# $databaseTools.AddToolVersion("SQL OLEDB Driver", $(Get-SQLOLEDBDriverVersion))
# $databaseTools.AddToolVersion("SQLPS", $(Get-SQLPSVersion))
# if (Test-IsWin25) {
#     $databaseTools.AddToolVersion("MongoDB Shell (mongosh)", $(Get-MongoshVersion))
# }

# Web Servers - Comment out since web servers not in minimal image
# $installedSoftware.AddHeader("Web Servers").AddTable($(Build-WebServersSection))

# Visual Studio - Comment out since Visual Studio not in minimal image
# $vsTable = Get-VisualStudioVersion
# $visualStudio = $installedSoftware.AddHeader($vsTable.Name)
# $visualStudio.AddTable($vsTable)

# $workloads = $visualStudio.AddHeader("Workloads, components and extensions")
# $workloads.AddTable((Get-VisualStudioComponents) + (Get-VisualStudioExtensions))

# $msVisualCpp = $visualStudio.AddHeader("Microsoft Visual C++")
# $msVisualCpp.AddTable($(Get-VisualCPPComponents))

# $visualStudio.AddToolVersionsList("Installed Windows SDKs", $(Get-WindowsSDKs).Versions, '^.+')

# .NET Core Tools
$netCoreTools = $installedSoftware.AddHeader(".NET Core Tools")
if (Test-IsWin19) {
    # Visual Studio 2019 brings own version of .NET Core which is different from latest official version
    $netCoreTools.AddToolVersionsListInline(".NET Core SDK", $(Get-DotnetSdks).Versions, '^\d+\.\d+\.\d{2}')
} else {
    $netCoreTools.AddToolVersionsListInline(".NET Core SDK", $(Get-DotnetSdks).Versions, '^\d+\.\d+\.\d{3}')
}

# Only add .NET Framework versions if they exist (minimal build may not have Windows SDK)
$dotnetFrameworkVersions = Get-DotnetFrameworkVersions
if ($dotnetFrameworkVersions -and $dotnetFrameworkVersions.Count -gt 0) {
    $netCoreTools.AddToolVersionsListInline(".NET Framework", $dotnetFrameworkVersions, '^.+')
}

Get-DotnetRuntimes | ForEach-Object {
    $netCoreTools.AddToolVersionsListInline($_.Runtime, $_.Versions, '^.+')
}
$netCoreTools.AddNodes($(Get-DotnetTools))

# PowerShell Tools
$psTools = $installedSoftware.AddHeader("PowerShell Tools")
$psTools.AddToolVersion("PowerShell", $(Get-PowershellCoreVersion))

$psModules = $psTools.AddHeader("Powershell Modules")
$psModules.AddNodes($(Get-PowerShellModules))


# Android - Comment out since Android SDK not in minimal image
# $android = $installedSoftware.AddHeader("Android")
# $android.AddTable($(Build-AndroidTable))

# $android.AddHeader("Environment variables").AddTable($(Build-AndroidEnvironmentTable))

# Cached Docker images - Comment out since likely not in minimal image
if (-not (Test-IsWin25)) {
    $installedSoftware.AddHeader("Cached Docker images").AddTable($(Get-CachedDockerImagesTableData))
}

# Generate reports
$softwareReport.ToJson() | Out-File -FilePath "C:\software-report.json" -Encoding UTF8NoBOM
$softwareReport.ToMarkdown() | Out-File -FilePath "C:\software-report.md" -Encoding UTF8NoBOM

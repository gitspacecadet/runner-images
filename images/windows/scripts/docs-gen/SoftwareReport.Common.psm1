# function Initialize-RustEnvironment {
#     $env:RUSTUP_HOME = "C:\Users\Default\.rustup"
#     $env:CARGO_HOME = "C:\Users\Default\.cargo"
#     $env:Path += ";$env:CARGO_HOME\bin"
# }

function Get-OSName {
    return (Get-CimInstance -ClassName Win32_OperatingSystem).Caption | Get-StringPart -Part 1,2,3
}

function Get-OSVersion {
    $OSVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
    $OSBuild = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion' UBR).UBR
    return "$OSVersion Build $OSBuild"
}

function Build-OSInfoSection {
    $osInfoNode = [HeaderNode]::new($(Get-OSName))
    $osInfoNode.AddToolVersion("OS Version:", $(Get-OSVersion))
    $osInfoNode.AddToolVersion("Image Version:", $env:IMAGE_VERSION)
    return $osInfoNode
}

# function Get-BashVersion {
#     bash --% -c 'echo ${BASH_VERSION}'
# }

# function Get-RustVersion {
#     rustc --version | Get-StringPart -Part 1
# }

# function Get-RustupVersion {
#     cmd /c "rustup --version 2>NUL" | Get-StringPart -Part 1
# }

# function Get-RustCargoVersion {
#     cargo --version | Get-StringPart -Part 1
# }

# function Get-RustdocVersion {
#     rustdoc --version | Get-StringPart -Part 1
# }

# function Get-RustfmtVersion {
#     rustfmt --version | Get-StringPart -Part 1 | Get-StringPart -Part 0 -Delimiter ('-')
# }

# function Get-RustClippyVersion {
#     cargo clippy --version | Get-StringPart -Part 1
# }

# function Get-BindgenVersion {
#     bindgen --version | Get-StringPart -Part 1
# }

# function Get-CbindgenVersion {
#     cbindgen --version | Get-StringPart -Part 1
# }

# function Get-CargoAuditVersion {
#     cargo-audit --version | Get-StringPart -Part 1
# }

# function Get-CargoOutdatedVersion {
#     cargo outdated --version | Get-StringPart -Part 1
# }

# function Get-PythonVersion {
#     python --version | Get-StringPart -Part 1
# }

function Get-PowershellCoreVersion {
    pwsh --version | Get-StringPart -Part 1
}

# function Get-RubyVersion {
#     ruby --version | Get-StringPart -Part 1
# }

# function Get-GoVersion {
#     go version | Get-StringPart -Part 2 | Get-StringPart -Part 1 -Delimiter ('o')
# }

# function Get-KotlinVersion {
#     cmd /c "kotlinc -version 2>&1" | Get-StringPart -Part 2
# }

# function Get-PHPVersion {
#     php --version | Out-String | Get-StringPart -Part 1
# }

# function Get-JuliaVersion {
#     julia --version | Get-StringPart -Part 2
# }

# function Get-LLVMVersion {
#     (clang --version) -match "clang" | Get-StringPart -Part 2
# }

# function Get-PerlVersion {
#     ($(perl --version) | Out-String) -match "\(v(?<version>\d+\.\d+\.\d+)\)" | Out-Null
#     $perlVersion = $Matches.Version
#     return $perlVersion
# }

# function Get-NodeVersion {
#     node --version | Get-StringPart -Part 0 -Delimiter ('v')
# }

function Get-ChocoVersion {
    choco --version
}

function Get-VcpkgVersion {
    $commitId = git -C "C:\vcpkg" rev-parse --short HEAD
    return "(build from commit $commitId)"
}

# function Get-NPMVersion {
#     npm -version
# }

# function Get-YarnVersion {
#     # yarn -version  # Yarn removed from minimal image
#     return "Not installed"
# }

# function Get-RubyGemsVersion {
#     gem --version
# }

# function Get-HelmVersion {
#     ($(helm version --short) | Out-String) -match "v(?<version>\d+\.\d+\.\d+)" | Out-Null
#     $helmVersion = $Matches.Version
#     return $helmVersion
# }

# function Get-PipVersion {
#     (pip --version) -match "pip" | Get-StringPart -Part 1, 4, 5
# }

# function Get-CondaVersion {
#     $condaVersion = ((& "$env:CONDA\Scripts\conda.exe" --version) -replace "^conda").Trim()
#     return "$condaVersion (pre-installed on the image but not added to PATH)"
# }

# function Get-ComposerVersion {
#     composer --version | Get-StringPart -Part 2
# }

function Get-NugetVersion {
    (nuget help) -match "Nuget Version" | Get-StringPart -Part 2
}

# function Get-AntVersion {
#     ant -version | Get-StringPart -Part 3
# }

# function Get-MavenVersion {
#     (mvn -version) -match "Apache Maven" | Get-StringPart -Part 2
# }

# function Get-GradleVersion {
#     ($(gradle -version) | Out-String) -match "Gradle (?<version>\d+\.\d+)" | Out-Null
#     $gradleVersion = $Matches.Version
#     return $gradleVersion
# }

# function Get-SbtVersion {
#     sbt --script-version
# }

function Get-DotnetSdks {
    $sdksRawList = dotnet --list-sdks
    $sdkVersions = $sdksRawList | Foreach-Object { $_.Split()[0] }
    $sdkPath = $sdksRawList[0].Split(' ', 2)[1] -replace '\[|]'
    [PSCustomObject]@{
        Versions = $sdkVersions
        Path     = $sdkPath
    }
}

function Get-DotnetTools {
    $env:Path += ";C:\Users\Default\.dotnet\tools"
    $dotnetTools = (Get-ToolsetContent).dotnet.tools

    $toolsList = @()

    foreach ($dotnetTool in $dotnetTools) {
        $version = Invoke-Expression $dotnetTool.getversion
        $toolsList += [ToolVersionNode]::new($dotnetTool.name, $version)
    }
    return $toolsList
}

function Get-DotnetRuntimes {
    $runtimesRawList = dotnet --list-runtimes
    $runtimesRawList | Group-Object { $_.Split()[0] } | ForEach-Object {
        $runtimeName = $_.Name
        $runtimeVersions = $_.Group | Foreach-Object { $_.split()[1] }
        $runtimePath = $_.Group[0].Split(' ', 3)[2] -replace '\[|]'
        [PSCustomObject]@{
            "Runtime"  = $runtimeName
            "Versions" = $runtimeVersions
            "Path"     = $runtimePath
        }
    }
}

function Get-DotnetFrameworkVersions {
    $path = "${env:ProgramFiles(x86)}\Microsoft SDKs\Windows\*\*\NETFX * Tools"
    
    # Check if the path exists before trying to access it
    if (Test-Path $path) {
        return Get-ChildItem -Path $path -Directory | ForEach-Object { $_.Name | Get-StringPart -Part 1 }
    } else {
        # Return empty array for minimal build without Windows SDK
        return @()
    }
}

function Get-PowerShellAzureModules {
    [Array] $result = @()
    $defaultAzureModuleVersion = "2.1.0"

    [Array] $azInstalledModules = Get-ChildItem -Path "C:\Modules\az_*" -Directory | ForEach-Object { $_.Name.Split("_")[1] }
    if ($azInstalledModules.Count -gt 0) {
        $result += [ToolVersionsListNode]::new("Az", $($azInstalledModules), '^\d+\.\d+', "Inline")
    }

    [Array] $azureInstalledModules = Get-ChildItem -Path "C:\Modules\azure_*" -Directory | ForEach-Object { $_.Name.Split("_")[1] } | ForEach-Object { if ($_ -eq $defaultAzureModuleVersion) { "$($_) (Default)" } else { $_ } }
    if ($azureInstalledModules.Count -gt 0) {
        $result += [ToolVersionsListNode]::new("Azure", $($azureInstalledModules), '^\d+\.\d+', "Inline")
    }

    [Array] $azurermInstalledModules = Get-ChildItem -Path "C:\Modules\azurerm_*" -Directory | ForEach-Object { $_.Name.Split("_")[1] } | ForEach-Object { if ($_ -eq $defaultAzureModuleVersion) { "$($_) (Default)" } else { $_ } }
    if ($azurermInstalledModules.Count -gt 0) {
        $result += [ToolVersionsListNode]::new("AzureRM", $($azurermInstalledModules), '^\d+\.\d+', "Inline")
    }

    [Array] $azCachedModules = Get-ChildItem -Path "C:\Modules\az_*.zip" -File | ForEach-Object { $_.Name.Split("_")[1] }
    if ($azCachedModules.Count -gt 0) {
        $result += [ToolVersionsListNode]::new("Az (Cached)", $($azCachedModules), '^\d+\.\d+', "Inline")
    }

    [Array] $azureCachedModules = Get-ChildItem -Path "C:\Modules\azure_*.zip" -File | ForEach-Object { $_.Name.Split("_")[1] }
    if ($azureCachedModules.Count -gt 0) {
        $result += [ToolVersionsListNode]::new("Azure (Cached)", $($azureCachedModules), '^\d+\.\d+', "Inline")
    }

    [Array] $azurermCachedModules = Get-ChildItem -Path "C:\Modules\azurerm_*.zip" -File | ForEach-Object { $_.Name.Split("_")[1] }
    if ($azurermCachedModules.Count -gt 0) {
        $result += [ToolVersionsListNode]::new("AzureRM (Cached)", $($azurermCachedModules), '^\d+\.\d+', "Inline")
    }

    return $result
}

function Get-PowerShellModules {
    [Array] $result = @()

    $result += Get-PowerShellAzureModules

    $result += (Get-ToolsetContent).powershellModules.name | Sort-Object | ForEach-Object {
        $moduleName = $_
        $moduleVersions = Get-Module -Name $moduleName -ListAvailable | Select-Object -ExpandProperty Version | Sort-Object -Unique
        return [ToolVersionsListNode]::new($moduleName, $moduleVersions, '^\d+', "Inline")
    }

    return $result
}

function Get-CachedDockerImages {
    return (docker images --digests --format "* {{.Repository}}:{{.Tag}}").Split("*") | Where-Object { $_ }
}

function Get-CachedDockerImagesTableData {
    $allImages = docker images --digests --format "*{{.Repository}}:{{.Tag}}|{{.Digest}} |{{.CreatedAt}}"
    if (-not $allImages) {
        return $null
    }

    $allImages.Split("*") | Where-Object { $_ } | ForEach-Object {
        $parts = $_.Split("|")
        [PSCustomObject] @{
            "Repository:Tag" = $parts[0]
            "Digest"         = $parts[1]
            "Created"        = $parts[2].split(' ')[0]
        }
    } | Sort-Object -Property "Repository:Tag"
}

function Get-ShellTarget {
    return Get-ChildItem C:\shells -File | Select-Object Name, @{n = "Target"; e = {
            if ($_.Name -eq "msys2bash.cmd") {
                "C:\msys64\usr\bin\bash.exe"
            } else {
                @($_.Target)[0]
            }
        }
    } | Sort-Object Name
}

# function Get-PacmanVersion {
#     $msys2BinDir = "C:\msys64\usr\bin"
#     $pacmanPath = Join-Path $msys2BinDir "pacman.exe"
#     $rawVersion = & $pacmanPath --version
#     $rawVersion.Split([System.Environment]::NewLine)[1] -match "\d+\.\d+(\.\d+)?" | Out-Null
#     $pacmanVersion = $matches[0]
#     return $pacmanVersion
# }

# function Get-YAMLLintVersion {
#     yamllint --version | Get-StringPart -Part 1
# }

# function Get-BizTalkVersion {
#     $bizTalkReg = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\BizTalk Server\3.0"
#     return [ToolVersionNode]::new($bizTalkReg.ProductName, $bizTalkReg.ProductVersion)
# }

# function Get-PipxVersion {
#     pipx --version
# }

function Build-PackageManagementEnvironmentTable {
    return @(
        [PSCustomObject] @{
            "Name" = "VCPKG_INSTALLATION_ROOT"
            "Value" = $env:VCPKG_INSTALLATION_ROOT
        },
        [PSCustomObject] @{
            "Name" = "CONDA"
            "Value" = $env:CONDA
        }
    )
}

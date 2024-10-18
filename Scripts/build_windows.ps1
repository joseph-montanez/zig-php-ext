# Variables
$PHP_VERSION = "php-8.3.12"
$BUILD_DIR = "build"
$INSTALL_DIR_PREFIX = "php-8.3"
$PATCH_FILE = "../php-zig.patch"  # Relative path to the patch file
$ZTS_TYPES = @("zts", "non-zts")

$ZTS_URL = "https://windows.php.net/downloads/releases/php-devel-pack-8.3.12-Win32-vs16-x64.zip"
$NON_ZTS_URL = "https://windows.php.net/downloads/releases/php-devel-pack-8.3.12-nts-Win32-vs16-x64.zip"

# Get the current script directory
$script_dir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Resolve the patch file relative to the script directory
$absolute_patch_file = Join-Path $script_dir $PATCH_FILE

# Create the build directory
New-Item -ItemType Directory -Path $BUILD_DIR -Force

foreach ($zts_type in $ZTS_TYPES) {
    $install_dir = "$BUILD_DIR\$INSTALL_DIR_PREFIX-$zts_type"

    # If the install directory exists, remove it
    if (Test-Path $install_dir) {
        Write-Host "Removing existing directory $install_dir..."
        Remove-Item -Recurse -Force $install_dir
    }

    # Create install directory
    New-Item -ItemType Directory -Path $install_dir -Force

    # Set URL based on ZTS or Non-ZTS
    if ($zts_type -eq "zts") {
        $download_url = $ZTS_URL
    } else {
        $download_url = $NON_ZTS_URL
    }

    # Define download path and extract destination
    $zip_file = "$install_dir\$PHP_VERSION-$zts_type.zip"

    # Download the file
    Write-Host "Downloading PHP $zts_type..."
    Invoke-WebRequest -Uri $download_url -OutFile $zip_file

    # Extract the zip file to a temporary location
    $temp_extract_dir = "$install_dir\temp"
    Write-Host "Extracting PHP $zts_type..."
    Expand-Archive -Path $zip_file -DestinationPath $temp_extract_dir -Force

    # Locate the top-level extracted folder and move its contents up one level
    $nested_dir = Get-ChildItem -Path $temp_extract_dir | Where-Object { $_.PSIsContainer } | Select-Object -First 1

    if ($nested_dir) {
        Write-Host "Moving extracted files from $($nested_dir.FullName) to $install_dir..."
        Get-ChildItem -Path "$($nested_dir.FullName)\*" | Move-Item -Destination $install_dir
    }

    # Clean up the temporary extraction folder and zip file
    Remove-Item $temp_extract_dir -Recurse -Force
    Remove-Item $zip_file

    # Apply the patch to the 'include' directory
    $include_dir = "$install_dir\include"
    if (Test-Path $include_dir) {
        Write-Host "Applying patch to $include_dir..."
        git -C $include_dir apply $absolute_patch_file
    } else {
        Write-Host "Include directory not found at $include_dir."
    }
}

Write-Host "PHP $PHP_VERSION downloaded, extracted, and patched successfully with ZTS and Non-ZTS versions."

param (
    [string]$zig = $ZIG_BINARY,
    [string]$zts = $PHP_ZTS_TYPE,
    [string]$build = $PHP_BUILD_TYPE,
    [string[]]$action = @()
)

# Default values
$ZIG_BINARY = "zig"  # Location of zig binary, i.e., zig.exe
$PHP_ZTS_TYPE = "non-zts"  # Can be 'zts' or 'non-zts'
$PHP_BUILD_TYPE = "debug"  # Can be 'debug' or 'release', but for PHP there is no release version
$ACTIONS = @()  # List of actions to perform
$ZIG_OPT = "Debug"  # Zig optimization level

# Set flags based on input
if ($build -eq "release") {
    $PHP_BUILD_TYPE = "release"
    $ZIG_OPT = "ReleaseSafe"  # Zig release optimization
} else {
    $PHP_BUILD_TYPE = "debug"
    $ZIG_OPT = "Debug"
}

# Determine the shared library extension based on the OS
if ($IsMacOS) {
    $LIB_EXTENSION = "dylib"
    $SDK_PATH = & xcrun --sdk macosx --show-sdk-path
    $SDK_INCLUDE = "-I${SDK_PATH}/usr/include"
} else {
    $LIB_EXTENSION = "so"
    $SDK_INCLUDE = ""
}

# Set PHP_SDK path based on ZTS and build type
$PHP_SDK = ".\\build\\php-8.3-${PHP_ZTS_TYPE}"

# Get PHP configuration
$INCLUDE_PATHS = "-I${PHP_SDK}\\include -I${PHP_SDK}\\include\\main -I${PHP_SDK}\\include\\Zend -I${PHP_SDK}\\include\\TSRM"
$LIBS = ""

# Function to configure the extension
function Configure-Extension {
    Write-Host "Configuring the PHP extension..."
    Remove-Item config.h, config.nice, config.status, configure, configure.ac, configure~, libtool, Makefile, Makefile.*, run-tests.php -Force -ErrorAction SilentlyContinue
    
    # Run Visual Studio's vcvars64.bat in the current cmd process
    Write-Host "Setting up the Visual Studio build environment..."
    cmd /c '"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" && echo Visual Studio environment set up.'

    # Run phpize.bat from the PHP SDK
    $phpizePath = "${PHP_SDK}\\phpize.bat"
    if (Test-Path $phpizePath) {
        Write-Host "Running phpize.bat..."
        cmd /c "$phpizePath"
    } else {
        Write-Host "phpize.bat not found at $phpizePath"
        return
    }

    # Run the configure script
    Write-Host "Running PHP configure script..."
    cmd /c "cd $PWD && ./configure --with-php-config=""${PHP_SDK}\\php-config"""
    ./configure --with-php-config="${PHP_SDK}\\php-config"
}

# Function to build the extension
function Build-Extension {
    Write-Host "Building the PHP extension in ${PHP_BUILD_TYPE} mode..."

    # Clear build artifacts
    Remove-Item libext.*, wrapper.o -Force -ErrorAction SilentlyContinue

    # Compile wrapper
    if ($PHP_BUILD_TYPE -eq "release") {
        $CLANG_OPTS = "-O2 -DNDEBUG -march=native"
    } else {
        $CLANG_OPTS = "-O0 -g"
    }

    Write-Host "Compiling wrapper with clang..."
    clang -c wrapper.c -o wrapper.o $INCLUDE_PATHS $SDK_INCLUDE -fPIC $CLANG_OPTS

    # String replace for zig files
    Get-ChildItem -Filter "*.zig" | ForEach-Object { (Get-Content $_.FullName) -replace 'pub const struct_zend_atomic_bool_s = opaque {};', 'pub const struct_zend_atomic_bool_s = extern struct { value: @import("std").atomic.Value(bool), };' | Set-Content $_.FullName }

    Write-Host "Building Zig library..."
    $libPath = Join-Path -Path (Resolve-Path "$PHP_SDK../lib") ""
    & $ZIG_BINARY build-lib ext.zig `
        -freference-trace `
        -fallow-shlib-undefined `
        -Dtarget=native `
        -dynamic `
        $INCLUDE_PATHS `
        $SDK_INCLUDE `
        -O $ZIG_OPT `
        -fPIC `
        "-L$libPath" `
        $LIBS `
        -I. `
        wrapper.o
}

# Function to run the extension
function Run-Extension {
    Write-Host "Running the PHP extension..."
    & ${PHP_SDK}php -d extension=./libext.${LIB_EXTENSION} vector3.php
}

# Function to clean the build artifacts
function Clean-Extension {
    Write-Host "Cleaning build artifacts..."
    Remove-Item libext.*, wrapper.o, config.h, config.nice, config.status, configure, configure.ac, configure~, libtool, Makefile, Makefile.*, run-tests.php, -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item modules, include, autom4te.cache, .zig-cache, ~/.cache/zig -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Clean complete."
}

# Loop through all actions and perform them
foreach ($action in $action) {
    switch ($action) {
        "configure" {
            Configure-Extension
        }
        "build" {
            Build-Extension
        }
        "run" {
            Run-Extension
        }
        "clean" {
            Clean-Extension
        }
        default {
            Write-Host "Unknown action: $action. Available actions are: configure, build, run, clean."
            exit 1
        }
    }
}

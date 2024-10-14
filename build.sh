#!/bin/bash

# Default values
ZIG_BINARY="zig" # Location of zig binary i.e zig.exe
PHP_ZTS_TYPE="non-zts" # Can be 'nts' or 'non-nts'
PHP_BUILD_TYPE="debug"  # Can be 'debug' or 'release'
ACTIONS=()  # List of actions to perform
ZIG_OPT="Debug"  # Zig optimization level

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --zig) ZIG_BINARY="$2"; shift ;;
        --zts) PHP_ZTS_TYPE="zts" ;;
        --release)
            PHP_BUILD_TYPE="release"
            ZIG_OPT="ReleaseFast"  # Change Zig optimization to release mode
            ;;
        --action) ACTIONS+=("$2"); shift ;;  # Collect actions into an array
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Clear previous build artifacts
clear

# Determine the shared library extension based on the OS
if [[ "$(uname)" == "Darwin" ]]; then
    LIB_EXTENSION="dylib"
    SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
    SDK_INCLUDE="-I${SDK_PATH}/usr/include"
else
    LIB_EXTENSION="so"
    SDK_INCLUDE=""
fi

# Set PHP_SDK path based on ZTS and build type
PHP_SDK="./build/php-8.3-${PHP_ZTS_TYPE}-${PHP_BUILD_TYPE}/bin/"

# Get PHP configuration
INCLUDE_PATHS=$(${PHP_SDK}php-config --includes)
LIBS=$(${PHP_SDK}php-config --libs)

# Function to configure the extension
configure_extension() {
    echo "Configuring the PHP extension..."
    rm -f config.h config.nice config.status config.h.* configure configure.ac configure~ libtool Makefile Makefile.* run-tests.php
    ${PHP_SDK}phpize
    ./configure --with-php-config=${PHP_SDK}php-config
}

# Function to build the extension
build_extension() {
    echo "Building the PHP extension in ${PHP_BUILD_TYPE} mode..."
    # Clear build artifacts
    rm -f libext.*
    rm -f libext.*.*
    rm -f wrapper.o

    # Compile wrapper (apply appropriate optimization flags)
    if [[ "$PHP_BUILD_TYPE" == "release" ]]; then
        CLANG_OPTS="-O2 -DNDEBUG -march=native"
    else
        CLANG_OPTS="-O0 -g"
    fi

    # Compile wrapper (use optimization flag based on build type)
    clang -c wrapper.c -o wrapper.o $INCLUDE_PATHS $SDK_INCLUDE -fPIC $CLANG_OPTS

    # Build Zig library
    $ZIG_BINARY build-lib ext.zig \
        -freference-trace \
        -fallow-shlib-undefined \
        -Dtarget=native \
        -dynamic \
        $INCLUDE_PATHS \
        $SDK_INCLUDE \
        -O $ZIG_OPT \
        -fPIC \
        -L$PHP_SDK../lib \
        $LIBS \
        -I. \
        wrapper.o
}

# Function to run the extension test
run_extension() {
    echo "Running the PHP extension..."
    ${PHP_SDK}php -d extension=./libext.${LIB_EXTENSION} -r "echo test1(), 'going to test2...', PHP_EOL, '\"', test2('Zig'), '\"', PHP_EOL, text_reverse('Hello World');"
}

# Function to clean the build artifacts
clean_extension() {
    echo "Cleaning build artifacts..."
    rm -f libext.*
    rm -f libext.*.*
    rm -f wrapper.o
    rm -f config.h config.nice config.status config.h.* config.log autom4te.cache configure configure.ac configure~ libtool Makefile Makefile.* run-tests.php
    rm -rf modules include autom4te.cache
    rm -rf .zig-cache
    rm -rf ~/.cache/zig
    echo "Clean complete."
}

# Loop through all actions and perform them
for ACTION in "${ACTIONS[@]}"; do
    case $ACTION in
        configure)
            configure_extension
            ;;
        build)
            build_extension
            ;;
        run)
            run_extension
            ;;
        clean)
            clean_extension
            ;;
        *)
            echo "Unknown action: $ACTION. Available actions are: configure, build, run, clean."
            exit 1
            ;;
    esac
done

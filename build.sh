#!/bin/bash

# Default values
ZIG_BINARY="zig"
PHP_ZTS_TYPE="non-zts"
PHP_BUILD_TYPE="debug"
ACTIONS=()  # List of actions to perform

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --zig) ZIG_BINARY="$2"; shift ;;
        --zts) PHP_ZTS_TYPE="zts" ;;
        --release) PHP_BUILD_TYPE="release" ;;
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
    ${PHP_SDK}phpize
    ./configure
}

# Function to build the extension
build_extension() {
    echo "Building the PHP extension..."
    # Clear build artifacts
    rm -f libext.*
    rm -f libext.*.*
    rm -f wrapper.o

    # Compile wrapper
    clang -c wrapper.c -o wrapper.o $INCLUDE_PATHS $SDK_INCLUDE -fPIC

    # Build Zig library
    $ZIG_BINARY build-lib ext.zig \
        -freference-trace \
        -fallow-shlib-undefined \
        -Dtarget=native \
        -dynamic \
        $INCLUDE_PATHS \
        $SDK_INCLUDE \
        -O Debug \
        -fno-omit-frame-pointer \
        -fPIC \
        -L$PHP_SDK../lib \
        $LIBS \
        -I. \
        wrapper.o
}

# Function to run the extension test
run_extension() {
    echo "Running the PHP extension..."
    ${PHP_SDK}php -d extension=./libext.${LIB_EXTENSION} -r "echo test1(), 'going to test2...', PHP_EOL, '\"', test2('Zig'), '\"', PHP_EOL;"
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
        *)
            echo "Unknown action: $ACTION. Available actions are: configure, build, run."
            exit 1
            ;;
    esac
done

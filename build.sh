#!/bin/bash

# Default values
ZIG_BINARY="zig"
PHP_ZTS_TYPE="non-zts"
PHP_BUILD_TYPE="debug"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --zig) ZIG_BINARY="$2"; shift ;;
        --zts) PHP_ZTS_TYPE="zts" ;;
        --release) PHP_BUILD_TYPE="release" ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Clear previous build artifacts
clear
# rm -rf .zig-cache
# rm -rf ~/.cache/zig
rm -f libext.*
rm -f libext.*.*
rm -f wrapper.o

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

# Prepare PHP extension
${PHP_SDK}phpize
./configure

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

# Test the extension
${PHP_SDK}php -d extension=./libext.${LIB_EXTENSION} -r "echo test1(), 'going to test2...', PHP_EOL, '\"', test2('Zig'), '\"', PHP_EOL;"

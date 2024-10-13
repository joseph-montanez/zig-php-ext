#!/bin/bash
clear

# Default values
ZIG_BINARY="zig"
PHP_ZTS_TYPE="non-zts"
PHP_BUILD_TYPE="debug"
FILE_TO_EXPAND=""

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --zig) ZIG_BINARY="$2"; shift ;;
        --zts) PHP_ZTS_TYPE="zts" ;;
        --release) PHP_BUILD_TYPE="release" ;;
        --file) FILE_TO_EXPAND="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Check if the file to expand is provided
if [[ -z "$FILE_TO_EXPAND" ]]; then
    echo "Error: No file specified to expand. Use --file to specify a file."
    exit 1
fi

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

INCLUDE_PATHS=$(${PHP_SDK}php-config --includes)
LIBS=$(${PHP_SDK}php-config --libs)

# Expand the macros in the provided file using clang
clang -E $INCLUDE_PATHS $FILE_TO_EXPAND > out.c
$ZIG_BINARY translate-c $INCLUDE_PATHS $FILE_TO_EXPAND > out.zig

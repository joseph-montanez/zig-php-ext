#!/bin/bash

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
PHP_SDK="./build/php-8.3-non-zts-release/bin/"

# Get PHP configuration
INCLUDE_PATHS=$(${PHP_SDK}php-config --includes)
LIBS=$(${PHP_SDK}php-config --libs)


echo "Benchmarking the PHP extension..."
${PHP_SDK}php -d extension=./libext.${LIB_EXTENSION} bench-zig.php
${PHP_SDK}php -d extension=./ext2/.libs/ext2.so bench-c.php
${PHP_SDK}php bench-internal.php
${PHP_SDK}php bench-php.php

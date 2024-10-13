#!/bin/bash
clear

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

# Create a temporary LLDB command file
LLDB_CMDS=$(mktemp)
cat << EOF > "$LLDB_CMDS"
settings set -- target.run-args -d "extension=./libext.${LIB_EXTENSION}" -r "echo test1(), PHP_EOL, '\"', test2('Zig'), '\"', PHP_EOL;"
breakpoint set -n dlopen --condition '(int)strcmp((char *)\$rdi, "./libext.${LIB_EXTENSION}") == 0'
breakpoint command add
script print("Shared library loaded. Setting additional breakpoint...")
breakpoint set -n zend_string_init2 --condition '(int)strcmp(str, "Zig") == 0'
continue
run
EOF

# Run LLDB with the command file
lldb -s "$LLDB_CMDS" "${PHP_SDK}php"

# Clean up the temporary file
rm "$LLDB_CMDS"

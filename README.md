

# 1. Customizing PHP C Source

The source code current for PHP does not work out of the box in Zig and needs a few changes. So you cannot use off the shelf installs and need a custom build of PHP. I've designed some scripts to compile `php-src` for you with the patched code. This will compile a thread-safe and non-thread-safe version.

## Debian/Ubuntu

This will prompt a **password** to auto install packages to build and fetch `php-src`

    chmod +x Scripts/build_ubuntu.sh
    ./Scripts/build_ubuntu.sh

## macOS

This will use brew to install `Bison 3.x`, however you do need the **XCode toolchain** installed.

    chmod +x Scripts/build_macos.sh
    ./Scripts/build_macos.sh


# 2. Building Zig Extension

PHP has several modes, right now `zig build` only uses ZTS/NON-ZTS for thread-safety. If you need a thread-safety version you can use:

    ./build.sh --zig /path/to/zig --zts

If not, and okay with non-thread safety version:

    ./build.sh --zig /path/to/zig

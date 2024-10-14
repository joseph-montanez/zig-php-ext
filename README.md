# Zig PHP Extension

A super bearly bones example of getting starting with Zig to write PHP extensions (PECL).

## 1. Customizing PHP C Source

The source code current for PHP does not work out of the box in Zig and needs a few changes. So you cannot use off the shelf installs and need a custom build of PHP. I've designed some scripts to compile `php-src` for you with the patched code. This will compile a thread-safe and non-thread-safe version.

### Debian/Ubuntu

This will prompt a **password** to auto install packages to build and fetch `php-src`

    chmod +x Scripts/build_ubuntu.sh
    ./Scripts/build_ubuntu.sh

### macOS

This will use brew to install `Bison 3.x`, however you do need the **XCode toolchain** installed.

    chmod +x Scripts/build_macos.sh
    ./Scripts/build_macos.sh

### Windows

TODO...

## 2. Building Zig Extension

PHP has several modes, right now `zig build` only uses ZTS/NON-ZTS for thread-safety. If you need a thread-safety version you can use:

    ./build.sh --zig /path/to/zig --zts --action configure --action build --action run

If not, and okay with non-thread safety version:

    ./build.sh --zig /path/to/zig --action configure --action build --action run


## Performance

I've not bothered to optimized any code so this is just an out of the box experience.

### PHP 8.3.12 Release NTS macOS aarch64 - M1 Mac Mini

1,000,000,000 (One Billion) iterations of a string reverse

| Version               | Time (seconds)         | Memory Usage |
|-----------------------|------------------------|--------------|
| C 03 Optimization     | 23.962615966797 seconds| 2.5MB        |
| C 02 Optimization     | 24.240067005157 seconds| 3.6MB        |
| Zig ReleaseFast       | 24.58452296257 seconds | 2.9MB        |
| PHP's `strrev`        | 26.616330862045 seconds| 3.5MB        |
| Zig ReleaseSafe       | 29.834988117218 seconds| 4.0MB        |

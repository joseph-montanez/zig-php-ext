clear
SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
PHP_SDK="./build/php-8.3.12-non-zts-debug/bin/"

INCLUDE_PATHS=$(${PHP_SDK}php-config --includes)


rm -rf ~/.cache/zig
rm -f libext.*
rm -f wrapper.o

${PHP_SDK}phpize

clang -c wrapper.c -o wrapper.o \
    $INCLUDE_PATHS \
    -I${SDK_PATH}/usr/include \
    -fPIC

# rm -rf /Users/josephmontanez/.cache/zig && rm -f libext.dylib && \
'/home/joseph/Apps/zig-linux-x86_64-0.14.0-dev.1860+2e2927735/zig' \
    build-lib ext.zig \
    -freference-trace \
    -Dtarget=native \
    -dynamic \
    $INCLUDE_PATHS \
    -I${SDK_PATH}/usr/include \
    -O Debug \
    -fno-omit-frame-pointer \
    -fPIC \
    -Lbuild/php-src/libs \
    -lc \
    -I. \
    wrapper.o \
&& ${PHP_SDK}php -d extension=./libext.so -r "echo test1(), 'going to test2...', PHP_EOL, '\"', test2('Zig'), '\"', PHP_EOL;"
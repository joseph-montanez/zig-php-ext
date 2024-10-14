#!/bin/bash

# Set the path to your custom PHP installation
PHP_PATH="/Users/josephmontanez/Documents/GitHub/zig-php-ext/build/php-8.3-non-zts-release"

# Ensure we're using the correct PHP version
export PATH="${PHP_PATH}/bin:$PATH"

# Run phpize
"${PHP_PATH}/bin/phpize"

# Configure the build
CFLAGS="-O2 -DNDEBUG -march=native" CXXFLAGS="-O2 -DNDEBUG -march=native" ./configure --with-php-config="${PHP_PATH}/bin/php-config"

# Build the extension
make clean
make

# Optionally, install the extension (you might need sudo for this)
# make install

# Print the PHP version being used
$PHP_PATH/bin/php -v

# Print the extension directory
$PHP_PATH/bin/php -d extension=./.libs/ext2.so -r "echo ctext_reverse('Hello World');"

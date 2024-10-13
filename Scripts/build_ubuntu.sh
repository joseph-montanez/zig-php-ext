#!/usr/bin/env bash

set -eu

# Variables
PHP_VERSION="php-8.3.12"
BUILD_DIR="build/php-src"
INSTALL_DIR_PREFIX="php-8.3"
INSTALL_ZTS_DIR="$INSTALL_DIR_PREFIX-zts-debug"
INSTALL_NON_ZTS_DIR="$INSTALL_DIR_PREFIX-non-zts-debug"
PATCH_FILE="../../php-zig.patch"

# Create the build directories
mkdir -p "build"
mkdir -p "build/$INSTALL_ZTS_DIR/"
mkdir -p "build/$INSTALL_NON_ZTS_DIR/"

# Install necessary dependencies
echo "Installing PHP build dependencies..."
sudo apt-get install -y git build-essential autoconf libtool re2c libxml2-dev libsqlite3-dev bison

# Clone or update the PHP source
if [ ! -d "$BUILD_DIR" ]; then
  echo "Cloning PHP $PHP_VERSION..."
  git clone https://github.com/php/php-src.git "$BUILD_DIR"
  pushd "$BUILD_DIR"
  git checkout "tags/$PHP_VERSION" --force
  popd
else
  echo "Resetting PHP source directory to original state..."
  pushd "$BUILD_DIR"
  git fetch --all --tags
  git reset --hard "tags/$PHP_VERSION"
  popd
fi

# Apply the patch if it exists
echo "Applying patch $PATCH_FILE..."
pushd "$BUILD_DIR"
git apply "$PATCH_FILE"
popd

# Function to configure, build, and install PHP
build_php() {
  local install_dir=$1
  local zts_flag=$2

  # Enter the PHP source directory
  pushd "$BUILD_DIR"

  # Clean previous builds
  echo "Cleaning previous builds..."
  make clean || true

  # Configure PHP
  echo "Configuring PHP (ZTS: $zts_flag) with embedding..."
  ./configure \
    --prefix="$(pwd)/../$install_dir/" \
    --enable-debug \
    --disable-opcache \
    --enable-embed=shared \
    --disable-phar \
    --without-libxml \
    --disable-dom \
    --disable-xml \
    --disable-simplexml \
    --disable-xmlreader \
    --disable-xmlwriter \
    --disable-cgi \
    $zts_flag \
    --with-sqlite3

  # Build PHP
  echo "Building PHP (ZTS: $zts_flag)..."
  make -j$(nproc)

  # Install PHP
  echo "Installing PHP to $install_dir..."
  make install

  popd
}

# Build ZTS version
build_php "$INSTALL_ZTS_DIR" "--enable-zts"

# Build Non-ZTS version
build_php "$INSTALL_NON_ZTS_DIR" "--disable-zts"

echo "PHP $PHP_VERSION built successfully with ZTS and Non-ZTS versions."

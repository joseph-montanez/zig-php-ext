#!/usr/bin/env bash

set -eu

# Variables
PHP_VERSION="php-8.3.12"
BUILD_DIR="build/php-src"
INSTALL_DIR_PREFIX="php-8.3"
PATCH_FILE="../../php-zig.patch"
BUILD_TYPES=("debug" "release")
ZTS_TYPES=("zts" "non-zts")

# Create the build directories
mkdir -p "build"

for build_type in "${BUILD_TYPES[@]}"; do
  for zts_type in "${ZTS_TYPES[@]}"; do
    mkdir -p "build/${INSTALL_DIR_PREFIX}-${zts_type}-${build_type}/"
  done
done

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
  local build_type=$3
  local enable_debug="--enable-debug"

  # Set release options
  if [[ "$build_type" == "release" ]]; then
    enable_debug="--disable-debug --enable-opcache"
  fi

  # Enter the PHP source directory
  pushd "$BUILD_DIR"

  # Clean previous builds
  echo "Cleaning previous builds..."
  make clean || true

  # Run ./buildconf to ensure ./configure exists
  echo "Running ./buildconf to generate configure script..."
  ./buildconf --force

  # Configure PHP
  echo "Configuring PHP (ZTS: $zts_flag, Build Type: $build_type) with embedding..."
  ./configure \
    --prefix="$(pwd)/../$install_dir/" \
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
    $enable_debug \
    --with-sqlite3

  # Build PHP
  echo "Building PHP (ZTS: $zts_flag, Build Type: $build_type)..."
  make -j$(nproc)

  # Install PHP
  echo "Installing PHP to $install_dir..."
  make install

  popd
}

# Loop over ZTS/Non-ZTS and Debug/Release build types
for build_type in "${BUILD_TYPES[@]}"; do
  for zts_type in "${ZTS_TYPES[@]}"; do
    install_dir="${INSTALL_DIR_PREFIX}-${zts_type}-${build_type}"
    zts_flag="--disable-zts"
    if [[ "$zts_type" == "zts" ]]; then
      zts_flag="--enable-zts"
    fi
    build_php "$install_dir" "$zts_flag" "$build_type"
  done
done

echo "PHP $PHP_VERSION built successfully with ZTS and Non-ZTS, Debug and Release versions."

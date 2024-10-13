#!/usr/bin/env bash

set -eu

# Variables
PHP_VERSION="php-8.3.12"
BUILD_DIR="build/php-src"
INSTALL_DIR_PREFIX="php-8.3"
MACOS_SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
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

# Clone PHP if not already cloned, or reset if exists
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

# Check if bison is installed, and install it if necessary
if ! command -v bison &>/dev/null; then
  echo "Bison not found. Installing bison using Homebrew..."
  if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Please install Homebrew first."
    exit 1
  else
    brew install bison
  fi
fi

# Get the path of Homebrew-installed bison
BISON_PATH=$(brew --prefix bison)/bin

# Verify that we have the correct version of bison
BISON_VERSION=$($BISON_PATH/bison --version | head -n 1 | awk '{print $4}')
REQUIRED_VERSION="3.0.0"
if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$BISON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
  echo "Bison version $BISON_VERSION is too old. Please update to at least version $REQUIRED_VERSION."
  exit 1
fi

echo "Bison version $BISON_VERSION found."

# Export BISON and YACC to make sure configure and make use the correct bison
export BISON="$BISON_PATH/bison"
export YACC="$BISON_PATH/bison"

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

  # Run ./buildconf to ensure ./configure exists
  if [ ! -f "./configure" ]; then
    echo "Running ./buildconf to generate configure script..."
    ./buildconf --force
  fi

  # Configure PHP
  echo "Configuring PHP (ZTS: $zts_flag, Build Type: $build_type) with embedding..."
  PATH="$BISON_PATH:$PATH" ./configure --host=arm-apple-darwin \
    --prefix="$(pwd)/../$install_dir/" \
    --with-iconv="$MACOS_SDK_PATH/usr" \
    --with-sqlite3="$MACOS_SDK_PATH/usr" \
    --enable-shared \
    --with-libdir=lib \
    --enable-static=no \
    --enable-embed=static \
    --disable-phar \
    --without-libxml \
    --disable-dom \
    --disable-xml \
    --disable-simplexml \
    --disable-xmlreader \
    --disable-xmlwriter \
    --disable-cgi \
    $zts_flag \
    $enable_debug

  # Clean previous builds
  echo "Cleaning previous builds..."
  make clean || true

  # Build PHP
  echo "Building PHP (ZTS: $zts_flag, Build Type: $build_type)..."
  make BISON="$BISON_PATH/bison" YACC="$BISON_PATH/bison" -j$(sysctl -n hw.ncpu)

  # Install PHP
  echo "Installing PHP to $install_dir..."
  make install DESTDIR="$(pwd)/../$install_dir/"

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

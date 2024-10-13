#!/usr/bin/env bash

set -eu

# Variables
PHP_VERSION="php-8.3.12"
BUILD_DIR="build/php-src"
INSTALL_ZTS_DIR="php-8.3-zts-debug"
INSTALL_NON_ZTS_DIR="php-8.3-non-zts-debug"
MACOS_SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)

# Create the build directories
mkdir -p "build"
mkdir -p "build/$INSTALL_ZTS_DIR/"
mkdir -p "build/$INSTALL_NON_ZTS_DIR/"

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
if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$BISON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION"; then
  echo "Bison version $BISON_VERSION is too old. Please update to at least version $REQUIRED_VERSION."
  exit 1
fi

echo "Bison version $BISON_VERSION found."

# Export BISON and YACC to make sure configure and make use the correct bison
export BISON="$BISON_PATH/bison"
export YACC="$BISON_PATH/bison"

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
  PATH="$BISON_PATH:$PATH" ./configure --host=arm-apple-darwin \
    --with-iconv="$MACOS_SDK_PATH/usr" \
    --with-sqlite3="$MACOS_SDK_PATH/usr" \
    --enable-debug \
    --enable-shared --with-libdir=lib --enable-static=no \
    --enable-embed=shared \
    --disable-phar \
    --without-libxml \
    --disable-dom \
    --disable-xml \
    --disable-simplexml \
    --disable-xmlreader \
    --disable-xmlwriter \
    --disable-cgi \
    $zts_flag

  # Build PHP
  echo "Building PHP (ZTS: $zts_flag)..."
  make BISON="$BISON_PATH/bison" YACC="$BISON_PATH/bison" -j$(sysctl -n hw.ncpu)

  # Install PHP
  echo "Installing PHP to $install_dir..."
  make install DESTDIR="$(pwd)/../$install_dir/"

  popd
}

# Build ZTS version
build_php "$INSTALL_ZTS_DIR" "--enable-zts"

# Build Non-ZTS version
build_php "$INSTALL_NON_ZTS_DIR" "--disable-zts"

echo "PHP $PHP_VERSION built successfully with ZTS and Non-ZTS versions."

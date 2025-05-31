#!/bin/bash
set -e

# --------- CONFIG ---------
NUM_CORES=$(($(nproc) - 1))
INSTALL_DIR="./"
FFMPEG_INSTALL_DIR="./"

# --------- Step 1: Install Dependencies ----------
echo "[1/4] Installing dependencies..."

sudo apt update
sudo apt install -y \
  build-essential cmake git pkg-config \
  libdrm-dev libpciaccess-dev libva-dev \
  libx11-dev libxext-dev libwayland-dev libegl-dev \
  python3-pip python3-distutils \
  libfreetype6-dev libass-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev \
  yasm nasm libx264-dev libx265-dev libnuma-dev libvdpau-dev texinfo \
  libtool automake autoconf

sudo apt install -y git cmake pkg-config meson libdrm-dev automake libtool
# --------- Step 2: Build Intel Media Driver ----------
echo "[2/4] Building Intel Media Driver from source..."


# Clone dependencies
git clone https://github.com/intel/libva.git
git clone https://github.com/intel/gmmlib.git
git clone https://github.com/intel/media-driver.git

# Build and install libva
cd libva
mkdir -p build 
cd build 
meson .. -Dprefix=/usr -Dlibdir=/usr/lib/x86_64-linux-gnu
ninja
sudo ninja install
cd ../..

# Build and install gmmlib
cd gmmlib
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j"$NUM_CORES"
sudo make install
cd ../..

# Build and install media-driver

mkdir -p build_media
cd build_media
cmake ../media-driver
make -j"$NUM_CORES"
sudo make install
cd ..

# --------- Step 3: Build FFmpeg with VAAPI Support ----------
echo "[3/4] Cloning and building FFmpeg..."

git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
cd ffmpeg

./configure \
  --prefix="$FFMPEG_INSTALL_DIR" \
  --enable-gpl \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libass \
  --enable-libfreetype \
  --enable-vaapi \
  --enable-libdrm \
  --enable-nonfree

make -j"$NUM_CORES"
make install

# --------- Step 4: Done ----------
echo "[4/4] Build completed!"
echo "FFmpeg binary is located at:"
echo "$FFMPEG_INSTALL_DIR/bin/ffmpeg"

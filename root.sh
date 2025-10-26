#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=5
timeout=5
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                      Foxytoux INSTALLER"
  echo "#"
  echo "#                           Copyright (C) 2024, RecodeStudios.Cloud"
  echo "#"
  echo "#"
  echo "#######################################################################################"

  read -p "Do you want to install Ubuntu? (YES/no): " install_ubuntu
fi

case $install_ubuntu in
  [yY][eE][sS])
    ROOTFS_FILE="$ROOTFS_DIR/rootfs.tar.gz"
    if [ ! -f "$ROOTFS_FILE" ]; then
      echo "Downloading Ubuntu rootfs..."
      wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$ROOTFS_FILE" \
        "http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.1-base-${ARCH_ALT}.tar.gz" || {
        echo "Failed to download rootfs"
        exit 1
      }
    else
      echo "Rootfs already exists, skipping download."
    fi

    echo "Extracting rootfs..."
    tar -xf "$ROOTFS_FILE" -C "$ROOTFS_DIR" || {
      echo "Failed to extract rootfs"
      exit 1
    }
    ;;
  *)
    echo "Skipping Ubuntu installation."
    ;;
esac

# proot
PROOT_FILE="$ROOTFS_DIR/usr/local/bin/proot"
if [ ! -s "$PROOT_FILE" ]; then
  mkdir -p "$ROOTFS_DIR/usr/local/bin"
  echo "Downloading proot binary..."
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$PROOT_FILE" \
    "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}" || {
      echo "Failed to download proot"
      exit 1
    }
  chmod 755 "$PROOT_FILE"
fi

# resolv.conf
if [ ! -e "$ROOTFS_DIR/etc/resolv.conf" ]; then
  mkdir -p "$ROOTFS_DIR/etc"
  echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "$ROOTFS_DIR/etc/resolv.conf"
fi

touch "$ROOTFS_DIR/.installed"

CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'

display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e ""
  echo -e "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}"
}

clear
display_gg

"$PROOT_FILE" \
  --rootfs="$ROOTFS_DIR" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b "$ROOTFS_DIR/etc/resolv.conf" --kill-on-exit

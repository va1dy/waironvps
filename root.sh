#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

# Определяем архитектуру для скачивания rootfs
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

# Установка rootfs
if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                  Foxytoux INSTALLER"
  echo "#"
  echo "#                       Copyright (C) 2024, RecodeStudios.Cloud"
  echo "#"
  echo "#######################################################################################"

  read -p "Do you want to install Debian 13? (YES/no): " install_debian
fi

case $install_debian in
  [yY][eE][sS])
    echo "Downloading Debian 13 rootfs..."
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/debian-rootfs.tar.xz \
      "https://github.com/debootstrap/debootstrap/releases/download/debian-13.0/debian-13.0-rootfs.tar.xz"

    mkdir -p $ROOTFS_DIR
    tar -xJf /tmp/debian-rootfs.tar.xz -C $ROOTFS_DIR

    # Создаем /root для корректной работы proot
    mkdir -p $ROOTFS_DIR/root

    # Проверка /bin/sh
    if [ ! -f "$ROOTFS_DIR/bin/sh" ]; then
      echo "Error: /bin/sh not found in rootfs!"
      exit 1
    fi
    ;;
  *)
    echo "Skipping Debian installation."
    ;;
esac

# Установка proot
if [ ! -e $ROOTFS_DIR/usr/local/bin/proot ]; then
  mkdir -p $ROOTFS_DIR/usr/local/bin
  echo "Downloading proot..."
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot \
    "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"
  chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

# Настройка DNS
if [ ! -e $ROOTFS_DIR/etc/resolv.conf ]; then
  mkdir -p $ROOTFS_DIR/etc
  echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > $ROOTFS_DIR/etc/resolv.conf
fi

# Создание файла .installed
touch $ROOTFS_DIR/.installed

# Цвета для вывода
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

# Запуск proot с Debian 13
$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  --kill-on-exit /bin/bash

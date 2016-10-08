#!/bin/sh -e

echo "*** BUILD KERNEL BEGIN ***"

SRC_DIR=$(pwd)

# Read the 'JOB_FACTOR' property from '.config'
JOB_FACTOR="$(grep -i ^JOB_FACTOR .config | cut -f2 -d'=')"

# Find the number of available CPU cores.
NUM_CORES=$(grep ^processor /proc/cpuinfo | wc -l)

# Calculate the number of 'make' jobs to be used later.
NUM_JOBS=$((NUM_CORES * JOB_FACTOR))

cd work/kernel

# Prepare the kernel install area.
rm -rf kernel_installed
mkdir kernel_installed

# Change to the kernel source directory which ls finds, e.g. 'linux-4.4.6'.
cd $(ls -d linux-*)

# Cleans up the kernel sources, including configuration files.
echo "Preparing kernel work area..."
make mrproper -j $NUM_JOBS

# Read the 'USE_PREDEFINED_KERNEL_CONFIG' property from '.config'
USE_PREDEFINED_KERNEL_CONFIG="$(grep -i ^USE_PREDEFINED_KERNEL_CONFIG $SRC_DIR/.config | cut -f2 -d'=')"

if [ "$USE_PREDEFINED_KERNEL_CONFIG" = "true" -a ! -f $SRC_DIR/minimal_config/kernel.config ] ; then
  echo "Config file $SRC_DIR/minimal_config/kernel.config does not exist."
  USE_PREDEFINED_KERNEL_CONFIG="false"
fi

if [ "$USE_PREDEFINED_KERNEL_CONFIG" = "true" ] ; then
  # Use predefined configuration file for the kernel.
  echo "Using config file $SRC_DIR/minimal_config/kernel.config"  
  cp -f $SRC_DIR/minimal_config/kernel.config .config
else
  # Create default configuration file for the kernel.

  # PowerPC has 32 and 64 bit, hence there is no defconfig
  if [ "$(uname -m)" = "ppc" ]; then
    make pmac32_defconfig -j $NUM_JOBS
  # Catch Apple G5 (MacRISC4) PowerPC and take specific target
  elif [ "$(uname -m)" = "ppc64" ] && [ $(grep MacRISC4 /proc/cpuinfo > /dev/null) ]; then
    make g5_defconfig
  else
    make defconfig -j $NUM_JOBS
  fi
  echo "Generated default kernel configuration."

  # Changes the name of the system to 'minimal'.
  sed -i "s/.*CONFIG_DEFAULT_HOSTNAME.*/CONFIG_DEFAULT_HOSTNAME=\"minimal\"/" .config

  # Enable overlay support, e.g. merge ro and rw directories.
  sed -i "s/.*CONFIG_OVERLAY_FS.*/CONFIG_OVERLAY_FS=y/" .config
  
  # Step 1 - disable all active kernel compression options (should be only one).
  sed -i "s/.*\\(CONFIG_KERNEL_.*\\)=y/\\#\\ \\1 is not set/" .config  
  
  # Step 2 - enable the 'xz' compression option.
  sed -i "s/.*CONFIG_KERNEL_XZ.*/CONFIG_KERNEL_XZ=y/" .config

  # Enable the VESA framebuffer for graphics support.
  sed -i "s/.*CONFIG_FB_VESA.*/CONFIG_FB_VESA=y/" .config

  # Enable DEVTMPFS in case it got disabled (we dont use udev, we rely on it!)
  sed -i "s/.*CONFIG_DEVTMPFS.*/CONFIG_DEVTMPFS=y/" .config

  # Enable auto mount of DEVTMPFS
  sed -i "s/.*CONFIG_DEVTMPFS_MOUNT.*/CONFIG_DEVTMPFS_MOUNT=y/" .config
  # Sometimes this hasnt been set before, so we check if it exists and if not we put it in
  if [ ! $(grep CONFIG_DEVTMPFS_MOUNT .config) ]; then
    echo "CONFIG_DEVTMPFS_MOUNT=y" >> .config
  fi

  # Enable Firewire basic modules for PowerPC Apple
  if [ $(grep MacRISC /proc/cpuinfo > /dev/null) ]; then
    echo "MacRISC detected, enabling firewire basic modules"

    sed -i "s/.*CONFIG_FIREWIRE.*/CONFIG_FIREWIRE=y/" .config
    if [ ! $(grep CONFIG_FIREWIRE .config) ]; then
      echo "CONFIG_FIREWIRE=y" >> .config
    fi

    sed -i "s/.*CONFIG_FIREWIRE_NET.*/CONFIG_FIREWIRE_NET=y/" .config
    if [ ! $(grep CONFIG_FIREWIRE_NET .config) ]; then
      echo "CONFIG_FIREWIRE_NET=y" >> .config
    fi

    sed -i "s/.*CONFIG_FIREWIRE_OHCI.*/CONFIG_FIREWIRE_OHCI=y/" .config
    if [ ! $(grep CONFIG_FIREWIRE_OHCI .config) ]; then
      echo "CONFIG_FIREWIRE_OHCI=y" >> .config
    fi

    sed -i "s/.*CONFIG_FIREWIRE_SBP2.*/CONFIG_FIREWIRE_SBP2=y/" .config
    if [ ! $(grep CONFIG_FIREWIRE_SBP2 .config) ]; then
      echo "CONFIG_FIREWIRE_SBP2=y" >> .config
    fi
  fi

  # Read the 'USE_BOOT_LOGO' property from '.config'
  USE_BOOT_LOGO="$(grep -i ^USE_BOOT_LOGO $SRC_DIR/.config | cut -f2 -d'=')"

  if [ "$USE_BOOT_LOGO" = "true" ] ; then
    sed -i "s/.*CONFIG_LOGO_LINUX_CLUT224.*/CONFIG_LOGO_LINUX_CLUT224=y/" .config
    echo "Boot logo is enabled."
  else
    sed -i "s/.*CONFIG_LOGO_LINUX_CLUT224.*/\\# CONFIG_LOGO_LINUX_CLUT224 is not set/" .config
    echo "Boot logo is disabled."
  fi
  
  # Disable debug symbols in kernel => smaller kernel binary.
  sed -i "s/^CONFIG_DEBUG_KERNEL.*/\\# CONFIG_DEBUG_KERNEL is not set/" .config
fi

# Determine arch for the kernel image.
UNAMEM=$(uname -m)
if [ "$UNAMEM" = "x86_64" ] || [ "$UNAMEM" = "x86" ] || [ "$UNAMEM" = "i386" ] || [ "$UNAMEM" = "i686" ]; then
  ARCH=x86
elif [ "$UNAMEM" = "ppc" ] || [ "$UNAMEM" = "ppc64" ] || [ "$UNAMEM" = "ppcemb" ]; then
  ARCH=powerpc
else
  echo "ERROR: Unknown architecture..."
  exit 1
fi

# Compile the kernel with optimization for 'parallel jobs' = 'number of processors'.
# Good explanation of the different kernels:
# http://unix.stackexchange.com/questions/5518/what-is-the-difference-between-the-following-kernel-makefile-terms-vmlinux-vmlinux
echo "Building kernel..."
if [ "$ARCH" = "x86" ]; then
  MAKETARGET="bzImage"
  KERNELBINARY="arch/$ARCH/boot/$MAKETARGET"
elif [ "$ARCH" = "powerpc" ]; then
  MAKETARGET="vmlinux"
  KERNELBINARY="$MAKETARGET"
fi
make \
  CFLAGS="-Os -s -fno-stack-protector -U_FORTIFY_SOURCE" \
  $MAKETARGET -j $NUM_JOBS

# Install the kernel file.
cp $KERNELBINARY \
  $SRC_DIR/work/kernel/kernel_installed/kernel

# Further strip down the kernel, saving a lot of space and ram
if [ ! "$DONTSTRIPKERNEL" = "true" ]; then
  strip --strip-all $KERNELBINARY
fi

# Install kernel headers which are used later when we build and configure the
# GNU C library (glibc).
echo "Generating kernel headers..."
make \
  INSTALL_HDR_PATH=$SRC_DIR/work/kernel/kernel_installed \
  headers_install -j $NUM_JOBS

cd $SRC_DIR

echo "*** BUILD KERNEL END ***"


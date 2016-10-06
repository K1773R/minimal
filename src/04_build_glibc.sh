#!/bin/sh

echo "*** BUILD GLIBC BEGIN ***"

SRC_DIR=$(pwd)

# Read the 'JOB_FACTOR' property from '.config'
JOB_FACTOR="$(grep -i ^JOB_FACTOR .config | cut -f2 -d'=')"

# Find the number of available CPU cores.
NUM_CORES=$(grep ^processor /proc/cpuinfo | wc -l)

# Calculate the number of 'make' jobs to be used later.
NUM_JOBS=$((NUM_CORES * JOB_FACTOR))

# Save the kernel installation directory.
KERNEL_INSTALLED=$SRC_DIR/work/kernel/kernel_installed

cd work/glibc

# Find the glibc source directory, e.g. 'glibc-2.23' and remember it.
cd $(ls -d glibc-*)
GLIBC_SRC=$(pwd)
cd ..

# Prepare the work area, e.g. 'work/glibc/glibc_objects'.
echo "Preparing glibc object area. This may take a while..."
rm -rf glibc_objects
mkdir glibc_objects

# Prepare the install area, e.g. 'work/glibc/glibc_installed'.
echo "Preparing glibc install area. This may take a while..."
rm -rf glibc_installed
mkdir glibc_installed
GLIBC_INSTALLED=$(pwd)/glibc_installed

# All glibc work is done from the working area.
cd glibc_objects

# glibc is configured to use the root folder (--prefix=) and as result all
# libraries will be installed in '/lib'. Note that on 64-bit machines BusyBox
# will be linked with the libraries in '/lib' while the Linux loader is expected
# to be in '/lib64'. Kernel headers are taken from our already prepared kernel
# header area (see xx_build_kernel.sh). Packages 'gd' and 'selinux' are disabled
# for better build compatibility with the host system.
echo "Configuring glibc..."
# to find the architecture depending lib-name-*.h
#export LIBRARY_PATH=/usr/lib/$(gcc -print-multiarch)
export C_INCLUDE_PATH=/usr/include/$(gcc -print-multiarch)
export CPLUS_INCLUDE_PATH=/usr/include/$(gcc -print-multiarch)
# PowerPC build fails when any CFLAGS are defined, appending to CC and
# forcing build of 32 or 64bit code
UNAMEM="$(uname -m)"
if [ "$UNAMEM" = "ppc" ]; then
  export CC="gcc -m32 -mpowerpc -Os -s -fno-stack-protector"
  unset CFLAGS
elif [ "$UNAMEM" = "ppc64" ]; then
  export CC="gcc -m64 -mpowerpc64 -Os -s -fno-stack-protector"
  unset CFLAGS
else
  export CFLAGS="-Os -s -fno-stack-protector"
fi
$GLIBC_SRC/configure \
  --prefix= \
  --with-headers=$KERNEL_INSTALLED/include \
  --without-gd \
  --without-selinux \
  --disable-werror

# Compile glibc with optimization for "parallel jobs" = "number of processors".
echo "Building glibc..."
make -j $NUM_JOBS

# Install glibc in the installation area, e.g. 'work/glibc/glibc_installed'.
echo "Installing glibc..."
make install \
  DESTDIR=$GLIBC_INSTALLED \
  -j $NUM_JOBS

cd $SRC_DIR

echo "*** BUILD GLIBC END ***"


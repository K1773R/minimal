#!/bin/sh -e

SRC_DIR=$(pwd)

# Read the 'JOB_FACTOR' property from '.config'
JOB_FACTOR="$(grep -i ^JOB_FACTOR .config | cut -f2 -d'=')"

# Find the number of available CPU cores.
NUM_CORES=$(grep ^processor /proc/cpuinfo | wc -l)

# Calculate the number of 'make' jobs to be used later.
NUM_JOBS=$((NUM_CORES * JOB_FACTOR))

if [ ! -d $SRC_DIR/work/glibc/glibc_prepared ] ; then
  echo "Cannot continue - memtester depends on GLIBC. Please buld GLIBC first."
  exit 1
fi

cd work/overlay/memtester

# Change to the memtester source directory which ls finds, e.g. 'memtester-4.3'.
cd $(ls -d memtester-*)

echo "Preparing memtester work area. This may take a while..."
make clean -j $NUM_JOBS 2>/dev/null

rm -rf ../memtester_installed

echo "Configuring memtester..."
# Force 64bit build on ppc64 with 32bit userland
if [ "$(uname -m)" = "ppc64" ]; then
  sed -i 's/cc /cc -m64 -mpowerpc64 /' conf-cc
  sed -i 's/cc /cc -m64 -mpowerpc64 /' conf-ld
fi

echo "Building memtester..."
make -j $NUM_JOBS

echo "Installing memtester..."
mkdir -p ../../memtester_installed/sbin
cp memtester ../../memtester_installed/sbin/ 

echo "Reducing memtester size..."
strip --strip-all ../memtester_installed/sbin/*

cp -r \
  ../memtester_installed/sbin \
  $SRC_DIR/work/src/minimal_overlay

echo "memtester has been installed."

cd $SRC_DIR


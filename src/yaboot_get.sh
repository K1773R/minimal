#!/bin/sh -e

echo "*** GET YABOOT BEGIN ***"

SRC_DIR=$(pwd)

# We default to using prebuilt yaboot dpkg packages because of no active source hosting
# Also its abandonware, no new versions or anything. launchpad has the latest source/build

# Grab everything after the '=' character.
DOWNLOAD_URL=$(grep -i ^YABOOT_BINARY_URL .config | cut -f2 -d'=')

# Grab everything after the last '/' character.
ARCHIVE_FILE=${DOWNLOAD_URL##*/}

# Read the 'USE_LOCAL_SOURCE' property from '.config'
USE_LOCAL_SOURCE="$(grep -i ^USE_LOCAL_SOURCE .config | cut -f2 -d'=')"

if [ "$USE_LOCAL_SOURCE" = "true" -a ! -f $SRC_DIR/source/$ARCHIVE_FILE  ] ; then
  echo "Bundle $SRC_DIR/source/$ARCHIVE_FILE is missing and will be downloaded."
  USE_LOCAL_SOURCE="false"
fi

cd source

if [ ! "$USE_LOCAL_SOURCE" = "true" ] ; then
  # Downloading Yaboot bundle file. The '-c' option allows the download to resume.
  echo "Downloading Yaboot bundle from $DOWNLOAD_URL"
  wget -c $DOWNLOAD_URL
else
  echo "Using local Yaboot bundle $SRC_DIR/source/$ARCHIVE_FILE"
fi

# Delete folder with previously extracted Yaboot.
echo "Removing Yaboot work area. This may take a while..."
rm -rf ../work/yaboot
mkdir ../work/yaboot

# Extract Yaboot to folder 'work/yaboot'.
#tar -xvf $ARCHIVE_FILE -C ../work/yaboot
ar xv $ARCHIVE_FILE data.tar.gz
# Extract only neccesarry files
tar xvf data.tar.gz -C ../work/yaboot --strip=4 ./usr/lib/yaboot/yaboot
rm -f data.tar.gz

cd $SRC_DIR
# Create ofboot.b (OpenFirmware boot script)
echo "Create ofboot.b (OpenFirmware boot script)"
sh yaboot_ofboot.b.sh > work/yaboot/ofboot.b

echo "*** GET YABOOT END ***"


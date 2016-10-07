#!/bin/sh -e

# Choose between syslinux (x86) and yaboot (powerpc)
UNAMEM=$(uname -m)
if [ "$UNAMEM" = "x86_64" ] || [ "$UNAMEM" = "x86" ] || [ "$UNAMEM" = "i386" ] || [ "$UNAMEM" = "i686" ]; then
  time sh syslinux_generate_iso.sh
elif [ "$UNAMEM" = "ppc" ] || [ "$UNAMEM" = "ppc64" ] || [ "$UNAMEM" = "ppcemb" ]; then
  time sh yaboot_generate_iso.sh
else
  echo "ERROR: Unknown architecture..."
  exit 1
fi


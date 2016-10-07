#!/bin/sh -e
exec tail -n +4 $0

# ext.  xlate  creator  type    comment
.hqx    Ascii  'BnHx'   'TEXT'  "BinHex file"
.sit    Raw    'SIT!'   'SITD'  "StuffIT Expander"
.mov    Raw    'TVOD'   'MooV'  "QuickTime Movie"
.deb    Raw    'Debn'   'bina'  "Debian package"
.bin    Raw    'ddsk'   'DDim'  "Floppy or ramdisk image"
.img    Raw    'ddsk'   'DDim'  "Floppy or ramdisk image"
.b      Raw    'UNIX'   'tbxi'  "bootstrap"
yaboot  Raw    'UNIX'   'boot'  "bootstrap"
vmlinux Raw    'UNIX'   'boot'  "bootstrap"
.conf   Raw    'UNIX'   'conf'  "bootstrap"
*       Ascii  '????'   '????'  "Text file"


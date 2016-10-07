#!/bin/sh -e
exec tail -n +4 $0

<chrp-boot>
<description>Minimal Linux Live</description>
<os-name>Minimal Linux Live</os-name>
<boot-script>boot &device;:\boot\yaboot</boot-script>
</chrp-boot>

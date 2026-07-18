#!/bin/bash
#
# Hardware modification script: 2GB RAM + 512MB flash for Netcore N60 Pro.
# Run from the OpenWrt source root after feeds are installed and before build.

set -e

RAM_SIZE="0x80000000"
UBI_SIZE="0x1fa00000"
IMAGE_SIZE="506240k"

echo "=== Applying Netcore N60 Pro 2GB RAM + 512MB flash modifications ==="

OPENWRT_DIR="${OPENWRT_DIR:-$PWD}"
if [ ! -d "$OPENWRT_DIR/target/linux/mediatek" ] && [ -d "$PWD/openwrt/target/linux/mediatek" ]; then
    OPENWRT_DIR="$PWD/openwrt"
fi

DTS_FILES=(
    "$OPENWRT_DIR/target/linux/mediatek/dts/mt7986a-netcore-n60-pro.dts"
    "$OPENWRT_DIR"/target/linux/mediatek/files-*/arch/arm64/boot/dts/mediatek/mt7986a-netcore-n60-pro.dts
)

DTS_FOUND=0
for DTS_FILE in "${DTS_FILES[@]}"; do
    [ -f "$DTS_FILE" ] || continue
    DTS_FOUND=1
    echo "Found DTS: $DTS_FILE"

    if grep -Eq 'memory@40000000[[:space:]]*\{' "$DTS_FILE"; then
        sed -i -E "/memory@40000000[[:space:]]*\{/,/};/ {
            s/reg = <0[[:space:]]+0x40000000[[:space:]]+0[[:space:]]+0x[0-9a-fA-F]+>;/reg = <0 0x40000000 0 ${RAM_SIZE}>;/
            s/reg = <0x40000000[[:space:]]+0x[0-9a-fA-F]+>;/reg = <0x40000000 ${RAM_SIZE}>;/
        }" "$DTS_FILE"

        if sed -n -E "/memory@40000000[[:space:]]*\{/,/};/p" "$DTS_FILE" | grep -Eq "reg = <(0[[:space:]]+0x40000000[[:space:]]+0[[:space:]]+${RAM_SIZE}|0x40000000[[:space:]]+${RAM_SIZE})>;"; then
            echo "  [OK] Memory set to 2GB (${RAM_SIZE})"
        else
            echo "  [WARN] Memory reg was not updated; check DTS manually"
        fi
    else
        echo "  [WARN] memory@40000000 node not found; check DTS manually"
    fi

    if grep -Eq 'partition@580000[[:space:]]*\{' "$DTS_FILE"; then
        sed -i -E "/partition@580000[[:space:]]*\{/,/};/ {
            s/reg = <0x0*580000[[:space:]]+0x[0-9a-fA-F]+>;/reg = <0x580000 ${UBI_SIZE}>;/
        }" "$DTS_FILE"

        if sed -n -E "/partition@580000[[:space:]]*\{/,/};/p" "$DTS_FILE" | grep -Eq "reg = <0x0*580000[[:space:]]+${UBI_SIZE}>;"; then
            echo "  [OK] UBI partition set to ${UBI_SIZE}"
        else
            echo "  [WARN] UBI partition reg was not updated; check DTS manually"
        fi
    else
        echo "  [WARN] partition@580000 node not found; check DTS manually"
    fi
done

if [ "$DTS_FOUND" -eq 0 ]; then
    echo "  [WARN] DTS file not found; check Netcore N60 Pro DTS path manually"
fi

for MK_FILE in \
    "$OPENWRT_DIR/target/linux/mediatek/image/filogic.mk" \
    "$OPENWRT_DIR/target/linux/mediatek/image/mt7986.mk"; do

    if [ ! -f "$MK_FILE" ]; then
        continue
    fi

    if ! grep -Eq '^define Device/netcore_n60-pro[[:space:]]*$' "$MK_FILE"; then
        continue
    fi

    echo "Found image Makefile: $MK_FILE"

    sed -i -E '/^define Device\/netcore_n60-pro[[:space:]]*$/,/^endef[[:space:]]*$/ {
        /^[[:space:]]*IMAGE_SIZE[[:space:]]*:=/d
    }' "$MK_FILE"

    sed -i -E "/^define Device\/netcore_n60-pro[[:space:]]*$/,/^endef[[:space:]]*$/ {
        /^[[:space:]]*PAGESIZE[[:space:]]*:=/a\\
  IMAGE_SIZE := ${IMAGE_SIZE}
    }" "$MK_FILE"

    if awk '
        /^define Device\/netcore_n60-pro[[:space:]]*$/ { in_device = 1 }
        in_device && /^[[:space:]]*IMAGE_SIZE[[:space:]]*:=[[:space:]]*506240k[[:space:]]*$/ { found = 1 }
        in_device && /^endef[[:space:]]*$/ { in_device = 0 }
        END { exit(found ? 0 : 1) }
    ' "$MK_FILE"; then
        echo "  [OK] IMAGE_SIZE set to ${IMAGE_SIZE}"
    else
        echo "  [WARN] IMAGE_SIZE was not inserted; check netcore_n60-pro block manually"
    fi
done

for PLATFORM_FILE in \
    "$OPENWRT_DIR/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh" \
    "$OPENWRT_DIR/target/linux/mediatek/mt7986/base-files/lib/upgrade/platform.sh"; do

    if [ ! -f "$PLATFORM_FILE" ]; then
        continue
    fi

    echo "Found upgrade platform script: $PLATFORM_FILE"

    if awk '
        /^[[:space:]]*netcore,n60-pro[|\\]/ { in_device = 1 }
        in_device && /^[[:space:]]*CI_UBIPART="ubi"[[:space:]]*$/ { ubi = 1 }
        in_device && /^[[:space:]]*CI_KERNPART="kernel"[[:space:]]*$/ { kernel = 1 }
        in_device && /^[[:space:]]*CI_ROOTPART="rootfs"[[:space:]]*$/ { rootfs = 1 }
        in_device && /^[[:space:]]*nand_do_upgrade "\$1"[[:space:]]*$/ { nand = 1 }
        in_device && /^[[:space:]]*;;[[:space:]]*$/ {
            done = 1
            exit(ubi && kernel && rootfs && nand ? 0 : 1)
        }
        END {
            if (!done)
                exit 1
        }
    ' "$PLATFORM_FILE"; then
        echo "  [OK] Sysupgrade uses ubi/kernel/rootfs via nand_do_upgrade"
    else
        echo "  [WARN] Netcore N60 Pro sysupgrade path changed; check platform.sh manually"
    fi
done

echo "=== Hardware modification done ==="

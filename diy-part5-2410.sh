#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part5-2410.sh
# Description: OpenWrt DIY script part 5 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

set -e

CONFIG_GENERATE="package/base-files/files/bin/config_generate"

# Modify default IP
sed -i -E 's#ipad=\$\{ipaddr:-"192\.168\.(1|6)\.1"\}#ipad=${ipaddr:-"10.0.0.1"}#g' "$CONFIG_GENERATE"
grep -Fq '10.0.0.1' "$CONFIG_GENERATE" || {
    echo "[ERROR] Failed to set default LAN IP to 10.0.0.1"
    exit 1
}

# Modify default theme
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
sed -i -E "s#set system\.@system\[-1\]\.hostname='[^']*'#set system.@system[-1].hostname='N60Pro'#" "$CONFIG_GENERATE"
grep -Fq "hostname='N60Pro'" "$CONFIG_GENERATE" || {
    echo "[ERROR] Failed to set default hostname to N60Pro"
    exit 1
}

# Use latest luci-app-daed from QiuSimons, keep the tree's compatible daed backend.
rm -rf package/luci-app-daed package/feeds/*/luci-app-daed
DAED_LUCI_TMP="$(mktemp -d)"
git clone --depth=1 https://github.com/QiuSimons/luci-app-daed.git "$DAED_LUCI_TMP/src"
cp -a "$DAED_LUCI_TMP/src/luci-app-daed" package/luci-app-daed
rm -rf "$DAED_LUCI_TMP"

# 移除USB网络共享
sed -i 's/kmod-usb-net-rndis //g' target/linux/mediatek/image/mt7986.mk

# 硬件适配：2GB内存 + 512MB闪存
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/diy-hwmod-2g-512m.sh"

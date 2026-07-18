#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: post-feeds-2410.sh
# Description: Apply ImmortalWrt 2410 post-feed customizations
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/post-feeds-common.sh"

# Use latest daed stack from kenzok8/openwrt-daede with Go 1.26.
bash "$SCRIPT_DIR/replace-daed-stack.sh"

# Remove USB network sharing support from the device package list.
sed -i 's/kmod-usb-net-rndis //g' target/linux/mediatek/image/mt7986.mk

# Apply hardware adaptation: 2GB RAM + 512MB flash.
bash "$SCRIPT_DIR/apply-hwmod-2g-512m.sh"

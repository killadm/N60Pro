#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: post-feeds-common.sh
# Description: Apply common post-feed customizations
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

set -e

CONFIG_GENERATE="package/base-files/files/bin/config_generate"
DEFAULT_LAN_IP="10.0.0.1"
DEFAULT_HOSTNAME="N60Pro"
DEFAULT_THEME="luci-theme-argon"

# Modify default IP
sed -i "s/192.168.1.1/${DEFAULT_LAN_IP}/g" "$CONFIG_GENERATE"

# Modify default theme
sed -i "s/luci-theme-bootstrap/${DEFAULT_THEME}/g" feeds/luci/collections/luci/Makefile

# Modify hostname
sed -i "s/OpenWrt/${DEFAULT_HOSTNAME}/g" "$CONFIG_GENERATE"

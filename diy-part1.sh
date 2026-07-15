#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

set -e

# Use fw876/helloworld as a build-time source feed.
sed -i '/[[:space:]]helloworld[[:space:]]/d' feeds.conf.default
if [ -s feeds.conf.default ] && [ "$(tail -c 1 feeds.conf.default)" != "" ]; then
    echo >>feeds.conf.default
fi
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
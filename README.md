# N60Pro ImmortalWrt Build

GitHub Actions build configuration for Netcore N60 Pro / MT7986 firmware based on
`padavanonly/immortalwrt-mt798x-6.6`.
Commits to `main` that touch build inputs trigger the matching build workflow
automatically.

## Build Targets

| Workflow | Source branch | Config file | DIY script |
| --- | --- | --- | --- |
| `padavanonly-immortalwrt-mt798x-2410-builder` | `2410` | `configs/n60pro-immortalwrt-2410.config` | `scripts/post-feeds-2410.sh` |
| `padavanonly-immortalwrt-mt798x-6.6-builder` | `openwrt-24.10-6.6` | `configs/n60pro-immortalwrt-6.6.config` | `scripts/post-feeds-6.6.sh` |

## Repository Layout

- `.github/workflows/`: build and source-update workflows.
- `configs/`: build configuration files, grouped by target.
- `scripts/pre-feeds-helloworld.sh`: feed preparation before `scripts/feeds update`.
- `scripts/post-feeds-common.sh`: shared post-feed customization.
- `scripts/post-feeds-*.sh`: branch-specific post-feed customization entry points.
- `scripts/replace-daed-stack.sh`: replaces the bundled DAEDE stack and Go feed.
- `scripts/apply-hwmod-2g-512m.sh`: applies the 2GB RAM + 512MB flash hardware adaptation.
- `files/`: OpenWrt rootfs overlay.

## Config Maintenance

The `.config` files are intentionally grouped and commented for reviewability:

- target and build system
- kernel, crypto and hardening
- MediaTek platform, Wi-Fi and acceleration
- storage, networking, LuCI and services
- userland tools, runtime libraries and explicit disabled overrides

Keep the final disabled-options section after enabled options. Some symbols are
defined more than once to preserve OpenWrt/Kconfig override behavior.

## License

This repository keeps the original Actions-OpenWrt MIT license terms. See
[`LICENSE`](LICENSE).

#!/bin/bash
#
# Replace the bundled daed stack with kenzok8/openwrt-daede and use Go 1.26.
#

set -e

OPENWRT_DIR="${1:-$(pwd)}"
GOLANG_REPO="${GOLANG_REPO:-https://github.com/kenzok8/golang.git}"
GOLANG_BRANCH="${GOLANG_BRANCH:-1.26}"
DAEDE_REPO="${DAEDE_REPO:-https://github.com/kenzok8/openwrt-daede.git}"
DAEDE_BRANCH="${DAEDE_BRANCH:-main}"

cd "$OPENWRT_DIR"

if [ ! -x scripts/feeds ] || [ ! -d feeds/packages ]; then
    echo "[ERROR] Run diy-daede.sh from an OpenWrt buildroot after feeds are updated"
    exit 1
fi

echo "[INFO] Replacing OpenWrt golang feed with Go 1.26"
rm -rf feeds/packages/lang/golang
git clone --depth=1 --single-branch -b "$GOLANG_BRANCH" "$GOLANG_REPO" feeds/packages/lang/golang
./scripts/feeds install -f golang

echo "[INFO] Replacing dae/daed packages with kenzok8/openwrt-daede"
rm -rf \
    package/dae/dae \
    package/dae/daed \
    package/luci-app-daed \
    package/openwrt-daede \
    package/feeds/*/dae \
    package/feeds/*/daed \
    package/feeds/*/luci-app-daed \
    package/feeds/*/luci-i18n-daed-zh-cn \
    package/feeds/*/luci-app-daede

DAEDE_TMP="$(mktemp -d)"
trap 'rm -rf "$DAEDE_TMP"' EXIT

git clone --depth=1 --single-branch -b "$DAEDE_BRANCH" "$DAEDE_REPO" "$DAEDE_TMP/src"

mkdir -p package/openwrt-daede
cp -a \
    "$DAEDE_TMP/src/dae" \
    "$DAEDE_TMP/src/daed" \
    "$DAEDE_TMP/src/luci-app-daede" \
    "$DAEDE_TMP/src/vmlinux-btf" \
    package/openwrt-daede/

DAEDE_MENU="package/openwrt-daede/luci-app-daede/root/usr/share/luci/menu.d/luci-app-daede.json"
if [ ! -f "$DAEDE_MENU" ]; then
    echo "[ERROR] Failed to locate daede LuCI menu: $DAEDE_MENU"
    exit 1
fi
sed -i 's/"title": "daede"/"title": "DAEDE"/' "$DAEDE_MENU"
grep -Fq '"title": "DAEDE"' "$DAEDE_MENU" || {
    echo "[ERROR] Failed to set daede LuCI menu title to DAEDE"
    exit 1
}

mkdir -p package/openwrt-daede/daed/patches
DAED_SO_MARK_PATCH="package/openwrt-daede/daed/patches/0002-daed-set-explicit-so-mark-from-dae.patch"
cat > "$DAED_SO_MARK_PATCH" <<'PATCH'
--- a/dae/utils.go
+++ b/dae/utils.go
@@ -34,6 +34,20 @@ var (
 	EmptyGlobalSection       = `global {}`
 )
 
+func ensureExplicitSoMarkFromDae(globalSection string) string {
+	if strings.Contains(globalSection, "so_mark_from_dae") {
+		return globalSection
+	}
+
+	i := strings.Index(globalSection, "{")
+	if i < 0 {
+		return globalSection
+	}
+
+	rest := strings.TrimLeft(globalSection[i+1:], "\r\n")
+	return globalSection[:i+1] + "\n  so_mark_from_dae: 0\n" + rest
+}
+
 func NecessaryOutbounds(routing *daeConfig.Routing) (outbounds []string) {
 	f := daeConfig.FunctionOrStringToFunction(routing.Fallback)
 	outbounds = append(outbounds, f.Name)
@@ -55,9 +69,10 @@ func ParseConfig(globalSection *string,
 	if routingSection == nil {
 		routingSection = &EmptyRoutingSection
 	}
+	normalizedGlobalSection := ensureExplicitSoMarkFromDae(*globalSection)
 	strConfig := strings.Join([]string{
-		*globalSection,
+		normalizedGlobalSection,
 		*dnsSection,
 		*routingSection,
 		EmptyGroupSection,
 		EmptySubscriptionSection,
PATCH

for pkg in dae daed luci-app-daede vmlinux-btf; do
    if [ ! -f "package/openwrt-daede/$pkg/Makefile" ]; then
        echo "[ERROR] Failed to install openwrt-daede package: $pkg"
        exit 1
    fi
done

echo "[OK] openwrt-daede packages installed"

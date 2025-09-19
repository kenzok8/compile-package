#!/bin/bash

shopt -s extglob
rm -rf feeds/jell/{diy,mt-drivers,shortcut-fe,luci-app-mtwifi,base-files,luci-app-package-manager,\
dnsmasq,firewall*,wifi-scripts,opkg,ppp,curl,luci-app-firewall,\
nftables,fstools,wireless-regdb,libnftnl,netdata}
rm -rf feeds/packages/libs/libcups

curl -sfL https://raw.githubusercontent.com/openwrt/packages/master/lang/golang/golang/Makefile -o feeds/packages/lang/golang/golang/Makefile

for ipk in $(find feeds/jell/* -maxdepth 0 -type d);
do
	[[ "$(grep "KernelPackage" "$ipk/Makefile")" && ! "$(grep "BuildPackage" "$ipk/Makefile")" ]] && rm -rf $ipk || true
done

#<<'COMMENT'
rm -Rf feeds/luci/{applications,collections,protocols,themes,libs,docs,contrib}
rm -Rf feeds/luci/modules/!(luci-base)
rm -Rf feeds/packages/!(lang|libs|devel|utils|net|multimedia)
rm -Rf feeds/packages/libs/gnutls
rm -Rf feeds/packages/multimedia/!(gstreamer1)
rm -Rf feeds/packages/net/!(mosquitto|curl)
rm -Rf feeds/base/package/firmware
rm -Rf feeds/base/package/network/!(services|utils)
rm -Rf feeds/base/package/network/services/!(ppp)
rm -Rf feeds/base/package/system/!(opkg|ubus|uci|ca-certificates)
rm -Rf feeds/base/package/kernel/!(cryptodev-linux)
#COMMENT

status=$(curl -H "Authorization: token $REPO_TOKEN" -s "https://api.github.com/repos/kenzok8/small-package/actions/runs" | jq -r '.workflow_runs[0].status')
while [[ "$status" == "in_progress" || "$status" == "queued" ]];do
echo "wait 5s"
sleep 5
status=$(curl -H "Authorization: token $REPO_TOKEN" -s "https://api.github.com/repos/kenzok8/small-package/actions/runs" | jq -r '.workflow_runs[0].status')
done

./scripts/feeds update -a
./scripts/feeds install -a -p jell -f
./scripts/feeds install -a

rm -rf package/feeds/jell/luci-app-quickstart/root/usr/share/luci/menu.d/luci-app-quickstart.json

sed -i 's/\(page\|e\)\?.acl_depends.*\?}//' `find package/feeds/jell/luci-*/luasrc/controller/* -name "*.lua"`
# sed -i 's/\/cgi-bin\/\(luci\|cgi-\)/\/\1/g' `find package/feeds/jell/luci-*/ -name "*.lua" -or -name "*.htm*" -or -name "*.js"` &

sed -i \
	-e "s/+\(luci\|luci-ssl\|uhttpd\)\( \|$\)/\2/" \
	-e "s/+nginx\( \|$\)/+nginx-ssl\1/" \
	-e 's/+python\( \|$\)/+python3/' \
	-e 's?../../lang?$(TOPDIR)/feeds/packages/lang?' \
	-e 's,$(STAGING_DIR_HOST)/bin/upx,upx,' \
	package/feeds/jell/*/Makefile

sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile

cp -f devices/common/.config .config

sed -i '/WARNING: Makefile/d' scripts/package-metadata.pl


cp -f devices/common/po2lmo staging_dir/host/bin/po2lmo
chmod +x staging_dir/host/bin/po2lmo
# 请在下方输入自定义命令(一般用来安装第三方插件)(可以留空)

# 编辑默认的lan口ip地址
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# 编辑默认的主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 编辑默认的luci显示的固件名称
sed -i 's/OpenWrt/Koce/g' package/base-files/files/bin/config_generate
#sed -i 's/ImmortalWrt/ZWRT/g' package/base-files/files/bin/config_generate

# 添加额外的软件包，echo 方式和git clone 方式二选一即可
#echo 'src-git kenzok8 https://github.com/kenzok8/openwrt-packages' >>feeds.conf.default
#echo 'src-git small https://github.com/kenzok8/small' >>feeds.conf.default
echo 'src-git UA3F https://github.com/SunBK201/UA3F.git' >>feeds.conf.default
#git clone https://github.com/kenzok8/openwrt-packages.git package/openwrt-packages
#git clone https://github.com/kenzok8/small.git package/small
#git clone https://github.com/SunBK201/UA3F.git package/UA3F
#git clone https://github.com/stevenjoezhang/luci-app-adguardhome.git package/ADGH

# ===== enable kmod-nft-tproxy =====
MK=package/kernel/linux/modules/netfilter.mk
if ! grep -q 'KernelPackage/nft-tproxy' "$MK"; then
cat >> "$MK" <<'EOF'

define KernelPackage/nft-tproxy
  SUBMENU:=$(NF_MENU)
  TITLE:=Netfilter nf_tables tproxy support
  DEPENDS:=+kmod-nft-core
  KCONFIG:= \
    CONFIG_NF_TPROXY_IPV4 \
    CONFIG_NF_TPROXY_IPV6 \
    CONFIG_NFT_TPROXY
  FILES:= \
    $(LINUX_DIR)/net/netfilter/nf_tproxy_ipv4.ko \
    $(LINUX_DIR)/net/netfilter/nf_tproxy_ipv6.ko \
    $(LINUX_DIR)/net/netfilter/nft_tproxy.ko
  AUTOLOAD:=$(call AutoLoad,50,nf_tproxy_ipv4 nf_tproxy_ipv6 nft_tproxy)
endef

define KernelPackage/nft-tproxy/description
  Netfilter nf_tables tproxy support
endef

$(eval $(call KernelPackage,nft-tproxy))
EOF
fi

# target kernel config
CFG=target/linux/ipq50xx/config-5.4
mkdir -p "$(dirname "$CFG")"
touch "$CFG"
sed -i -E '/^#? ?CONFIG_(NFT_TPROXY|NF_TPROXY_IPV4|NF_TPROXY_IPV6)([ =]|$)/d' "$CFG"
cat >> "$CFG" <<'EOF'
CONFIG_NF_TPROXY_IPV4=m
CONFIG_NF_TPROXY_IPV6=m
CONFIG_NFT_TPROXY=m
EOF

# generic kernel config
GEN=target/linux/generic/config-5.4
sed -i 's/^# CONFIG_NFT_TPROXY is not set/CONFIG_NFT_TPROXY=m/'        "$GEN"
sed -i 's/^# CONFIG_NF_TPROXY_IPV4 is not set/CONFIG_NF_TPROXY_IPV4=m/' "$GEN"
sed -i 's/^# CONFIG_NF_TPROXY_IPV6 is not set/CONFIG_NF_TPROXY_IPV6=m/' "$GEN"

echo "[diy] nft-tproxy enabled"


# 启用 ath11k NSS offload
CONFIG_FILE="target/linux/ipq50xx/config-5.4"
if [ -f "$CONFIG_FILE" ]; then
  sed -i '/^# CONFIG_ATH11K_NSS_SUPPORT is not set/d' "$CONFIG_FILE"
  grep -q '^CONFIG_ATH11K_NSS_SUPPORT=y' "$CONFIG_FILE" || echo 'CONFIG_ATH11K_NSS_SUPPORT=y' >> "$CONFIG_FILE"
fi

# 仅在未设置环境变量时配置ccache
if [ -z "$CCACHE_DIR" ]; then
    export CCACHE_DIR="/home/runner/.ccache"
    export CCACHE_MAXSIZE="10G"
    export CCACHE_SLOPPINESS="file_macro,locale,time_macros"
fi

# 确保ccache目录存在
mkdir -p "$CCACHE_DIR"

# 确保ccache优先使用clang
export CC="ccache clang"
export CXX="ccache clang++"
export AR="llvm-ar"
export NM="llvm-nm"
export OBJCOPY="llvm-objcopy"
export OBJDUMP="llvm-objdump"
export READELF="llvm-readelf"
export STRIP="llvm-strip"

git clone https://gitlab.postmarketos.org/alghiffaryfa19/linux-sm8250.git --branch 7.1.0-dev --depth 1 linux
cd linux

# MIPPS
# wget https://github.com/code002-2/sm8550-mainline/commit/57512186fc43a902e38945da91c656dc36400362.patch
# git apply *patch
# rm *patch

cp ../sm8250.config .config

make -j$(nproc) ARCH=arm64 CC="ccache clang" LLVM=1
_kernel_version="$(make kernelrelease -s)"


sed -i "s/Version:.*/Version: ${_kernel_version}/" ../linux-xiaomi-enuma/DEBIAN/control

PKGDIR=../linux-xiaomi-enuma
ARCH=arm64

# =========================
# Install kernel images
# =========================
mkdir -p $PKGDIR/boot

install -Dm644 arch/$ARCH/boot/Image.gz \
    $PKGDIR/boot/Image.gz

install -Dm644 arch/$ARCH/boot/Image \
    $PKGDIR/boot/Image

install -Dm644 arch/$ARCH/boot/dts/qcom/sm8250-xiaomi-enuma.dtb \
    $PKGDIR/boot/sm8250-xiaomi-enuma.dtb

install -Dm644 .config \
    $PKGDIR/boot/config-${_kernel_version}

install -Dm644 System.map \
    $PKGDIR/boot/System.map-${_kernel_version}
    
chmod +x ../mkbootimg

cat arch/arm64/boot/Image.gz arch/arm64/boot/dts/qcom/sm8250-xiaomi-enuma.dtb > Image.gz-dtb_enuma

install -Dm644 Image.gz-dtb_enuma \
    $PKGDIR/boot/Image.gz-dtb_enuma

mv Image.gz-dtb_enuma zImage_enuma
../mkbootimg --kernel zImage_enuma --cmdline "root=PARTLABEL=linux" --base 0x00000000 --kernel_offset 0x00008000 --tags_offset 0x01e00000 --pagesize 4096 --id -o ../boot_enuma_dualboot.img
../mkbootimg --kernel zImage_enuma --cmdline "root=PARTLABEL=userdata" --base 0x00000000 --kernel_offset 0x00008000 --tags_offset 0x01e00000 --pagesize 4096 --id -o ../boot_enuma_singleboot.img

# ukify build \
#   --linux=arch/arm64/boot/Image \
#   --devicetree=arch/arm64/boot/dts/qcom/sm8250-xiaomi-enuma.dtb \
#   --cmdline="console=tty0 root=PARTLABEL=linux rootwait rw" \
#   --output=../bootaa64.efi

#rm $1/linux-xiaomi-sheng/usr/dummy

make -j$(nproc) ARCH=arm64 CC="ccache clang" LLVM=1 INSTALL_MOD_PATH=../linux-xiaomi-enuma modules_install
rm -f ../linux-xiaomi-enuma/lib/modules/*/build ../linux-xiaomi-enuma/lib/modules/*/source

cd ..
git clone https://github.com/alghiffaryfa19/xiaomi-enuma-firmware
mkdir -p firmware-xiaomi-enuma/
cp -r xiaomi-enuma-firmware/* firmware-xiaomi-enuma/

git clone https://github.com/map220v/alsa-ucm-conf
mkdir -p alsa-xiaomi-enuma/usr/share/alsa/ucm2/Xiaomi/enuma
cp -r alsa-ucm-conf/ucm2 alsa-xiaomi-enuma/usr/share/alsa/
install -Dm644 enuma.conf alsa-xiaomi-enuma/usr/share/alsa/ucm2/Xiaomi/enuma/enuma.conf
install -Dm644 HiFi.conf alsa-xiaomi-enuma/usr/share/alsa/ucm2/Xiaomi/enuma/HiFi.conf

mkdir -p alsa-xiaomi-enuma/usr/share/alsa/ucm2/conf.d/sm8250
ln -s "../../Xiaomi/enuma/enuma.conf" "alsa-xiaomi-enuma/usr/share/alsa/ucm2/conf.d/sm8250/Xiaomi Mi Pad 5 Pro 5G.conf"

dpkg-deb --build --root-owner-group linux-xiaomi-enuma
dpkg-deb --build --root-owner-group firmware-xiaomi-enuma
dpkg-deb --build --root-owner-group alsa-xiaomi-enuma

# modem-userspace
echo "🚀 Building modem-userspace"
git clone https://github.com/meizu-m2172-mainline/modem-userspace
mkdir -p modem-userspace-enuma/usr/local/sbin
mkdir -p modem-userspace-enuma/etc/udev/rules.d
mkdir -p modem-userspace-enuma/etc/systemd/system
mkdir -p modem-userspace-enuma/DEBIAN

cat << 'EOF' > modem-userspace-enuma/DEBIAN/control
Package: modem-userspace-enuma
Version: 1.0
Architecture: arm64
Maintainer: alghiffaryfa19
Description: Modem userspace scripts and rules for enuma
EOF

cat << 'EOF' > modem-userspace-enuma/DEBIAN/postinst
#!/bin/sh
udevadm control --reload || true
systemctl daemon-reload || true
systemctl enable --now m2172-modem.service || true
EOF
chmod +x modem-userspace-enuma/DEBIAN/postinst

install -m755 modem-userspace/scripts/m2172_sahara_fw_loader.py modem-userspace-enuma/usr/local/sbin/m2172-sahara-fw-loader
install -m755 modem-userspace/scripts/m2172-modem-bringup.sh    modem-userspace-enuma/usr/local/sbin/m2172-modem-bringup.sh
install -m755 modem-userspace/scripts/sdx55m-data-up.sh          modem-userspace-enuma/usr/local/sbin/sdx55m-data-up.sh
install -m644 modem-userspace/udev/78-mm-sdx55m.rules     modem-userspace-enuma/etc/udev/rules.d/
install -m644 modem-userspace/udev/79-mm-sdx55m-net.rules modem-userspace-enuma/etc/udev/rules.d/
install -m644 modem-userspace/systemd/m2172-modem.service modem-userspace-enuma/etc/systemd/system/

dpkg-deb --build --root-owner-group modem-userspace-enuma

# ModemManager
echo "🚀 Building ModemManager"
git clone https://github.com/meizu-m2172-mainline/ModemManager
cd ModemManager
meson setup build --prefix=/usr --buildtype=release -Dsystemdsystemunitdir=/lib/systemd/system -Dwerror=false -Dmbim=true -Dqmi=true -Dqrtr=true -Dpolkit=strict
ninja -C build
DESTDIR=$(pwd)/../modemmanager-enuma ninja -C build install
cd ..

mkdir -p modemmanager-enuma/DEBIAN
cat << 'EOF' > modemmanager-enuma/DEBIAN/control
Package: modemmanager-enuma
Version: 1.20.0-custom
Architecture: arm64
Maintainer: alghiffaryfa19
Conflicts: modemmanager
Replaces: modemmanager
Provides: modemmanager
Description: Custom ModemManager for enuma
EOF

cat << 'EOF' > modemmanager-enuma/DEBIAN/postinst
#!/bin/sh
systemctl daemon-reload || true
systemctl restart ModemManager.service || true
EOF
chmod +x modemmanager-enuma/DEBIAN/postinst

dpkg-deb --build --root-owner-group modemmanager-enuma
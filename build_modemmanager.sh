#!/bin/bash
set -e

# ModemManager
echo "🚀 Building ModemManager"
git clone https://github.com/meizu-m2172-mainline/ModemManager
cd ModemManager
meson setup build --prefix=/usr --buildtype=release -Dsystemdsystemunitdir=/lib/systemd/system -Dwerror=false -Dmbim=true -Dqmi=true -Dqrtr=true -Dpolkit=strict --force-fallback-for=libmbim,libqmi
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
echo "✅ ModemManager package built successfully"

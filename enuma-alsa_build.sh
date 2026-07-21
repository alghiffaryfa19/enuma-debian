#!/bin/bash
set -e

echo "🚀 Building ALSA configs"
git clone https://github.com/map220v/alsa-ucm-conf
mkdir -p alsa-xiaomi-enuma/usr/share/alsa/ucm2/Xiaomi/enuma
cp -r alsa-ucm-conf/ucm2 alsa-xiaomi-enuma/usr/share/alsa/
install -Dm644 enuma.conf alsa-xiaomi-enuma/usr/share/alsa/ucm2/Xiaomi/enuma/enuma.conf
install -Dm644 HiFi.conf alsa-xiaomi-enuma/usr/share/alsa/ucm2/Xiaomi/enuma/HiFi.conf

mkdir -p alsa-xiaomi-enuma/usr/share/alsa/ucm2/conf.d/sm8250
ln -s "../../Xiaomi/enuma/enuma.conf" "alsa-xiaomi-enuma/usr/share/alsa/ucm2/conf.d/sm8250/Xiaomi Mi Pad 5 Pro 5G.conf"

dpkg-deb --build --root-owner-group alsa-xiaomi-enuma
echo "✅ ALSA package built successfully"

#!/bin/bash

echo "🚀 Building firmware-xiaomi-enuma"
git clone https://github.com/alghiffaryfa19/xiaomi-enuma-firmware
mkdir -p firmware-xiaomi-enuma/
cp -r xiaomi-enuma-firmware/* firmware-xiaomi-enuma/

dpkg-deb --build --root-owner-group firmware-xiaomi-enuma

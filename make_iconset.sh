#!/bin/bash

# 创建临时目录
mkdir Fluffel.iconset

# 生成不同尺寸的图标
sips -z 16 16     Fluffel/icon.png --out Fluffel.iconset/icon_16x16.png
sips -z 32 32     Fluffel/icon.png --out Fluffel.iconset/icon_16x16@2x.png
sips -z 32 32     Fluffel/icon.png --out Fluffel.iconset/icon_32x32.png
sips -z 64 64     Fluffel/icon.png --out Fluffel.iconset/icon_32x32@2x.png
sips -z 128 128   Fluffel/icon.png --out Fluffel.iconset/icon_128x128.png
sips -z 256 256   Fluffel/icon.png --out Fluffel.iconset/icon_128x128@2x.png
sips -z 256 256   Fluffel/icon.png --out Fluffel.iconset/icon_256x256.png
sips -z 512 512   Fluffel/icon.png --out Fluffel.iconset/icon_256x256@2x.png
sips -z 512 512   Fluffel/icon.png --out Fluffel.iconset/icon_512x512.png
sips -z 1024 1024 Fluffel/icon.png --out Fluffel.iconset/icon_512x512@2x.png

# 转换为 .icns 文件
iconutil -c icns Fluffel.iconset

# 清理临时文件
rm -rf Fluffel.iconset 

# chmod +x make_iconset.sh
# ./make_iconset.sh
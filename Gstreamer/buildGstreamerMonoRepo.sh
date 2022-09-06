#!/usr/bin/env bash
#include build functions
CHECK=1
SKIP=0
source ./../common/buildfunc.sh

sudo apt install python3-pip python3-gi python3-gi-cairo gir1.2-gtk-3.0 make flex bison

sudo python3 -m pip install --upgrade pip
sudo python3 -m pip install meson
sudo python3 -m pip install cmake
sudo python3 -m pip install ninja
sudo python3 -m pip install nasm

sudo apt remove libglib2.0-dev


buildNinja "tinyalsa" "tinyalsa"

#Checkout project
cd /tmp
git -C gstreamer pull 2> /dev/null || git clone https://gitlab.freedesktop.org/gstreamer/gstreamer.git
cd gstreamer
git checkout tags/1.20.3

#Initiate meson setup. Expecting failure by goobject-introspection.wrap
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" LIBRARY_PATH=$HOME/ffmpeg_build/include PATH="$HOME/bin:$PATH" meson --prefix=/usr/local -D libnice=enabled -D omx=enabled -D gst-omx:target=rpi -D gst-omx:header_path=/opt/vc/include/IL -D buildtype=release -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ build

#Until pygobject fix the gobject-introspection.wrap revision, here's the patch
sed -i 's/revision=master/revision=main/' ./subprojects/pygobject/subprojects/gobject-introspection.wrap
sed -i 's/revision=master/revision=main/' ./subprojects/pango/subprojects/gobject-introspection.wrap

#rm -rf build
#Reinitialize setup with patched gobject-introspection.wrap 
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" LIBRARY_PATH=$HOME/ffmpeg_build/include PATH="$HOME/bin:$PATH" meson --prefix=/usr/local -D libnice=enabled -D omx=enabled -D gst-omx:target=rpi -D gst-omx:header_path=/opt/vc/include/IL -D buildtype=release -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ --reconfigure build
ninja -C build
#install first set of dependencies
sudo meson install -C build

#reconfigure to discover self dependencies
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" LIBRARY_PATH=$HOME/ffmpeg_build/include meson --prefix=/usr/local -D libnice=enabled -D omx=enabled -D gst-omx:target=rpi -D gst-omx:header_path=/opt/vc/include/IL -D buildtype=release -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ --reconfigure build
ninja -C build
sudo meson install -C build

#Armbian jammy rockpro64
sudo cp /usr/local/lib/aarch64-linux-gnu/girepository-1.0/Gst* /usr/lib/aarch64-linux-gnu/girepository-1.0/
#x86_64
sudo cp /usr/local/lib/x86_64-linux-gnu/girepository-1.0/* /usr/lib/x86_64-linux-gnu/girepository-1.0/
#Raspbian
sudo cp /usr/local/lib/arm-linux-gnueabihf/girepository-1.0/Gst* /usr/lib/arm-linux-gnueabihf/girepository-1.0/

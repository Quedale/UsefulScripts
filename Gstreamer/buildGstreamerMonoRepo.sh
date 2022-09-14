#!/usr/bin/env bash
#include build functions
PREFIX="$HOME/gst_build"
CHECK=1
SKIP=0
source $(dirname "$0")/../common/buildfunc.sh

arch=$(echo $(uname -a) | awk '{print $12}')
echo "*****************************"
echo "*** Architecture $arch ***"
echo "*****************************"

mkdir $PREFIX
#python3-gi python3-gi-cairo
# sudo apt install python3-pip gir1.2-gtk-3.0 make flex bison
#Custom dependencie by glib-networking where custom build location  is not picked up
#sudo apt install libssl-dev

sudo python3 -m pip install --upgrade pip
sudo python3 -m pip install meson
sudo python3 -m pip install cmake
sudo python3 -m pip install ninja
#sudo python3 -m pip install nasm
#sudo python3 -m pip install gi
#sudo python3 -m pip install pycairo

#Incompabible with apt version
#sudo apt remove libglib2.0-dev

#buildNinja "tinyalsa" "tinyalsa"

#Needed for libpciaccess
cd /tmp
pullOrClone path="https://github.com/freedesktop/xorg-macros.git"
buildMake1 srcdir="xorg-macros" prefix="$PREFIX"

#Needed for libdrm
cd /tmp
pullOrClone path="https://gitlab.freedesktop.org/xorg/lib/libpciaccess.git"
buildMake1 srcdir="libpciaccess" prefix="$PREFIX"

#Needed for libav
cd /tmp
downloadAndExtract file=nasm-2.15.05.tar.bz2 path=https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2
buildMake1 srcdir="nasm-2.15.05" prefix="$PREFIX"

echo "*****************************"
echo "*** Pull/Clone Gstreamer MonoRepo ***"
echo "*****************************"
gst_enables+=" -Dlibnice=enabled"
gst_enables+=' -Dpackage-origin="GitlabMonoRepo"'
if [[ "$arch" == "armv7l" ]]; then
    echo "arch is arm : $arch"
    gst_enables+=" -Domx=enabled"
    #TODO Validate rpi board
    gst_enables+=" -Dgst-omx:target=rpi"
    gst_enables+=" -Dgst-omx:header_path=/opt/vc/include/IL"
fi
gst_enables+=" -Dtests=disabled"
gst_enables+=" -Dexamples=disabled"
gst_enables+=" -Ddoc=disabled"
#gst_enables+=" --force-fallback-for=openh264"
#Override possibly outdated glib package
#gst_enables+=" --force-fallback-for=glib-2.0"
#gst_enables+=" --force-fallback-for=list,of,dependencies"

setup_patch="sed -i 's/revision=master/revision=main/' ./subprojects/pygobject/subprojects/gobject-introspection.wrap"
setup_patch+=" && sed -i 's/revision=master/revision=main/' ./subprojects/pango/subprojects/gobject-introspection.wrap"
setup_patch+=" && sed -i 's/revision=master/revision=main/' ./subprojects/gobject-introspection.wrap"

cd /tmp
pullOrClone path="https://gitlab.freedesktop.org/gstreamer/gstreamer.git" tag="1.20.3"
sed -i 's/revision=glib-2-70/revision=2.73.3/' ./gstreamer/subprojects/glib.wrap
buildMeson1 srcdir="gstreamer" prefix="$PREFIX" mesonargs="$gst_enables" setuppatch="$setup_patch" bindir="$HOME/bin"

##run Gstreamer portably* and force reload plugins
sudo rm -rf /home/pi/.cache/gstreamer-1.0/registry.armv7l.bin
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" \
    C_INCLUDE_PATH="$PREFIX/include" \
    LIBRARY_PATH="$PREFIX/include" \
    PATH="$HOME/bin:$PATH" \
    $PREFIX/bin/gst-launch-1.0 --version
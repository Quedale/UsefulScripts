#!/usr/bin/env bash
#include build functions
PREFIX="$HOME/gst_build"
SOURCES="$HOME/gst_sources"
CHECK=0
SKIP=0
source $(dirname "$0")/../common/buildfunc.sh

arch=$(echo $(uname -a) | awk '{print $12}')
echo "*****************************"
echo "*** Architecture $arch ***"
echo "*****************************"
mkdir $PREFIX
mkdir $SOURCES

if [ $SKIP -eq 0 ]
then
    echo "*****************************"
    echo "*   Installing PIP"
    echo "*****************************"
    sudo apt install python3-pip

    echo "*****************************"
    echo "*   Installing Build tools"
    echo "*****************************"
    sudo apt install autoconf automake  bison pkg-config

    echo "*****************************"
    echo "*   Upgrading PIP"
    echo "*****************************"
    python3 -m pip install --upgrade pip
    echo "*****************************"
    echo "*   Installing Meson"
    echo "*****************************"
    python3 -m pip install meson
    echo "*****************************"
    echo "*   Installing Cmake"
    echo "*****************************"
    python3 -m pip install cmake
    echo "*****************************"
    echo "*   Installing Ninja"
    echo "*****************************"
    python3 -m pip install ninja
    echo "*****************************"
    echo "*   Installing gobject"
    echo "*****************************"
    python3 -m pip install gobject

fi
#buildNinja "tinyalsa" "tinyalsa"

#Needed by xorg-macros
# cd $SOURCES
# downloadAndExtract file=autoconf-2.71.tar.gz path=http://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz
# buildMake1 srcdir="autoconf-2.71" prefix="$PREFIX" configure="--bindir=$HOME/bin"


#Needed for libpciaccess
if [ -z "$(checkPkg name='xorg-macros' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://github.com/freedesktop/xorg-macros.git" tag="util-macros-1.19.1"
    buildMake1 srcdir="xorg-macros" prefix="$PREFIX" configure="--datarootdir=$PREFIX/lib"
else
    echo "Xorg-macro already installed."
fi

#Needed for libdrm
if [ -z "$(checkPkg name='pciaccess' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://gitlab.freedesktop.org/xorg/lib/libpciaccess.git"
    buildMeson1 srcdir="libpciaccess" prefix="$PREFIX"
else
    echo "libpciaccess already installed."
fi

#Needed by glib-networking
if [ -z "$(checkPkg name='openssl' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://github.com/openssl/openssl.git" tag="OpenSSL_1_1_1q" #tag="OpenSSL_1_1_0l"
    buildMake1 srcdir="openssl" prefix="$PREFIX" configcustom="./config --prefix=$PREFIX --openssldir=$PREFIX/ssl shared"
    #TODO check if all distro uses /etc/ssl/certs
    cp -r /etc/ssl/certs/* $PREFIX/ssl/certs
else
    echo "openssl already installed."
fi

if [ -z "$(checkProg name='nasm' args='--version')" ]; then
    cd $SOURCES
    downloadAndExtract file=nasm-2.15.05.tar.bz2 path=https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2
    buildMake1 srcdir="nasm-2.15.05" prefix="$PREFIX" configure="--bindir=$HOME/bin"
else
    echo "nasm already installed."
fi

#Glib conflict during build time causes pygobject build to fail.
#Build pygobject manually
if [ -z "$(checkPkg name='pygobject-3.0' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://gitlab.gnome.org/GNOME/pygobject.git" tag="3.38.0"
    buildMeson1 srcdir="pygobject" prefix="$PREFIX" bindir="$HOME/bin"
    #For some reason it fails the first time
    buildMeson1 srcdir="pygobject" prefix="$PREFIX" bindir="$HOME/bin"
else
    echo "pygobject already installed."
fi

echo "*****************************"
echo "*** Pull/Clone Gstreamer MonoRepo ***"
echo "*****************************"
gst_enables+=" -Dlibnice=enabled"
gst_enables+=" -Dpackage-origin='GitlabFreedesktopMonoRepo'"
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

####################################
#
# main branch of pygobject requires exactly 2.73.2
# Lower isn't supported and 2.73.3 fails
#
####################################
setup_patch="sed -i 's/revision=master/revision=main/' ./subprojects/pygobject/subprojects/gobject-introspection.wrap"
setup_patch+=" && sed -i 's/revision=master/revision=main/' ./subprojects/pango/subprojects/gobject-introspection.wrap"
setup_patch+=" && sed -i 's/revision=master/revision=main/' ./subprojects/gobject-introspection.wrap"
setup_patch+=" && sed -i 's/revision=master/revision=2.73.2/' ./subprojects/pygobject/subprojects/glib.wrap"

cd $SOURCES
pullOrClone path="https://gitlab.freedesktop.org/gstreamer/gstreamer.git" tag="1.20.3"
sed -i 's/revision=glib-2-70/revision=2.73.2/' ./gstreamer/subprojects/glib.wrap

buildMeson1 srcdir="gstreamer" prefix="$PREFIX" mesonargs="$gst_enables" setuppatch="$setup_patch" bindir="$HOME/bin"
#Reconfigure to pickup self-dependencies and recompile
#buildMeson1 srcdir="gstreamer" prefix="$PREFIX" mesonargs="$gst_enables" setuppatch="$setup_patch" bindir="$HOME/bin"

##run Gstreamer portably* and force reload plugins
sudo rm -rf /home/pi/.cache/gstreamer-1.0/registry.armv7l.bin
GI_TYPELIB_PATH="$PREFIX/lib/girepository-1.0" \
PYTHONPATH="$PREFIX/lib/python3/dist-packages" \
LIBRARY_PATH="$PREFIX/lib:$LIBRARY_PATH" \
LD_LIBRARY_PATH="$PREFIX/lib" \
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" \
    $HOME/bin/gst-launch-1.0 --version

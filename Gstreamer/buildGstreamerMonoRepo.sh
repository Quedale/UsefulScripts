#!/usr/bin/env bash
#include build functions
PREFIX="$HOME/gst_build"
SOURCES="$HOME/gst_sources"
CHECK=1
SKIP=0
source $(dirname "$0")/../common/buildfunc.sh

arch=$(echo $(uname -a) | awk '{print $12}')
echo "*****************************"
echo "*** Architecture $arch ***"
echo "*****************************"
mkdir $PREFIX
mkdir $SOURCES

#Carry ffmpeg build if exists to prevent fallback
echo "*****************************"
echo "*** Copying FFmeg build ***"
echo "*****************************"
cp -r -u $HOME/ffmpeg_build/* $PREFIX

if [ $SKIP -eq 0 ]
then
    echo "*****************************"
    echo "*   Installing PIP"
    echo "*****************************"
    sudo apt install python3-pip

    echo "*****************************"
    echo "*   Installing Build tools"
    echo "*****************************"
    sudo apt install  bison pkg-config flex
    #autoconf automake Now coming from ffmpeg build
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

if [ -z "$(checkPkg name='gnutls' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://git.savannah.gnu.org/git/gnulib.git" tag="v0.1"
    preconfigure="./gnulib-tool --create-megatestdir --dir=build"
    buildMake1 srcdir="gnulib/build" prefix="$PREFIX" preconfigure=$preconfigure

    cd $SOURCES
    pullOrClone path="https://gitlab.com/gnutls/gnutls.git" tag="3.7.7"
    buildMake1 srcdir="gnutls" prefix="$PREFIX" 
else
    echo "gnutls already installed."
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

if [ -z "$(checkPkg name='libpcre2-8' prefix=$PREFIX)" ]; then

    cd $SOURCES
    pullOrClone path="https://github.com/PCRE2Project/pcre2.git" tag="pcre2-10.37"
    mkdir "pcre2/build"
    buildMake1 srcdir="pcre2/build" prefix="$PREFIX" configure="-Dtests=disabled -Ddocs=disabled" cmakedir=".."
else
    echo "libpcre2-8 already installed."
fi

if [ -z "$(checkPkg name='glib-2.0  >= 2.62.6' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://gitlab.gnome.org/GNOME/glib.git" tag="2.62.6" #Cerbero recipe version
    buildMeson1 srcdir="glib" prefix="$PREFIX" mesonargs="-Dinstalled_tests=false -Dgtk_doc=false -Dinstalled_tests=false"

    #TODO Test gnutls because openssl doesnt seem to work with gstreamer libsoup
    cd $SOURCES
    pullOrClone path="https://gitlab.gnome.org/GNOME/glib-networking.git" tag="2.62.3" #Cerbero recipe version
    buildMeson1 srcdir="glib-networking" prefix="$PREFIX" mesonargs="-Dgnutls=enabled -Dopenssl=enabled"
else
    echo "glib already installed."
fi

if [ -z "$(checkPkg name='gobject-introspection-1.0' prefix=$PREFIX)" ]; then

    cd $SOURCES
    pullOrClone path="https://gitlab.gnome.org/GNOME/gobject-introspection.git" tag="1.71.0"
    buildMeson1 srcdir="gobject-introspection" prefix="$PREFIX" mesonargs=""
else
    echo "gobject-introspection-1.0 already installed."
fi

if [ -z "$(checkPkg name='cairo' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="git://anongit.freedesktop.org/git/cairo" tag="1.17.6"
    buildMeson1 srcdir="cairo" prefix="$PREFIX" mesonargs="-Dtests=disabled -Dgtk_doc=false"
else
    echo "cairo already installed."
fi

#Glib conflict during build time causes pygobject build to fail.
#Build pygobject manually
if [ -z "$(checkPkg name='pygobject-3.0' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://gitlab.gnome.org/GNOME/pygobject.git" tag="3.42.2"
    buildMeson1 srcdir="pygobject" prefix="$PREFIX" bindir="$HOME/bin"
    #For some reason it fails the first time
    #cd $SOURCES
    #buildMeson1 srcdir="pygobject" prefix="$PREFIX" bindir="$HOME/bin"
else
    echo "pygobject already installed."
fi

if [ -z "$(checkPkg name='libva' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://github.com/intel/libva.git" tag="2.15.0"
    buildMeson1 srcdir="libva" prefix="$PREFIX" mesonargs="-Denable_docs=false"
else
    echo "libva already installed."
fi

if [ -z "$(checkPkg name='harfbuzz' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://github.com/harfbuzz/harfbuzz.git" tag="5.2.0"
    buildMeson1 srcdir="harfbuzz" prefix="$PREFIX" mesonargs="-Dtests=disabled -Ddocs=disabled -Dintrospection=enabled"
else
    echo "harfbuzz already installed."
fi

if [ -z "$(checkPkg name='pango' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://github.com/GNOME/pango.git" tag="1.48.11"
    buildMeson1 srcdir="pango" prefix="$PREFIX" mesonargs="-Dinstall-tests=false -Dgtk_doc=false"
    #This might fail the first time?
else
    echo "pango already installed."
fi

if [ -z "$(checkPkg name='libunwind' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://github.com/libunwind/libunwind.git" tag="v1.6.2"
    #downloadAndExtract file="mp3lame.tar.xz" path="https://sourceforge.net/projects/lame/files/latest/download"
    buildMake1 srcdir="libunwind" prefix="$PREFIX" autoreconf=true
else
    echo "libunwind already installed."
fi

echo "*****************************"
echo "*** Pull/Clone Gstreamer MonoRepo ***"
echo "*****************************"
gst_enables+=" -Dlibnice=enabled"
gst_enables+=" -Dpackage-origin='GitlabFreedesktopMonoRepo'"
if [[ "$arch" == "armv7l" ]]; then
    echo "arch is arm : $arch"
    #gst_enables+=" -Domx=enabled"
    #TODO Validate rpi board
    #gst_enables+=" -Dgst-omx:target=rpi"
    #gst_enables+=" -Dgst-omx:header_path=/opt/vc/include/IL"
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
pullOrClone path="https://gitlab.freedesktop.org/gstreamer/gstreamer.git"
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

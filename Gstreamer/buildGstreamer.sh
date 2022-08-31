#!/bin/sh

CPU_COUNT=$(nproc --all)
VERSION=1.20.3
INSTALL_PATH=/usr/local
BUILD_PATH=/tmp
MESON_BIN=meson
CHECK=1
SKIP=0

#export PKG_CONFIG_PATH=$INSTALL_PATH/lib/aarch64-linux-gnu/pkgconfig
#export LD_LIBRARY_PATH=$INSTALL_PATH/lib:$INSTALL_PATH/lib/aarch64-linux-gnu/
#PATH=/home/quedale/.bin:$PATH

echo "*****************************"
echo "*   Installing Tools"
echo "*****************************"
sudo apt install git make flex bison python-gi-dev python3-gi python3-gi-cairo python3-pip python3-dev

echo "*****************************"
echo "*   Installing Libraries"
echo "*****************************"
sudo apt install libglib2.0-dev libgirepository1.0-dev libxml2-dev libcgroup-dev \
                 libjson-glib-dev gettext libcap-dev libgsl-dev libgmp-dev libunwind-dev \
                 libdw-dev libopus-dev libpango1.0-dev valgrind libxv-dev libxext-dev libvorbisidec-dev \
                 libvorbis-dev libtheora-dev libvisual-0.4-dev libcdparanoia-dev libsoup2.4-dev \
                 libopenjp2-7-dev libdrm-dev libexif-dev libzbar-dev libzxingcore-dev \
                 libwebp-dev libwildmidi-dev libwebrtc-audio-processing-dev libvo-amrwbenc-dev \
                 libzvbi-dev libsrtp2-dev libspandsp-dev libsoundtouch-dev libsndfile1-dev libsbc-dev \
                 libqrencode-dev libopenmpt-dev libopenni2-dev libopenal-dev \
                 libneon27-dev libmodplug-dev liblilv-dev libde265-dev liblrdf0-dev libkate-dev \
                 libgsm1-dev flite1-dev libdirectfb-dev libssh2-1-dev libchromaprint-dev \
                 libbs2b-dev libaom-dev libass-dev libgudev-1.0-dev libusb-1.0-0-dev libltc-dev \
                 libxkbcommon-x11-dev libvulkan-dev libva-dev libbluetooth-dev libdv4-dev libmp3lame-dev \
                 libwavpack-dev libtwolame-dev libspeex-dev libshout-dev libpulse-dev libiec61883-dev libavc1394-dev \
                 libcaca-dev libjack-jackd2-dev liba52-0.7.4-dev libopencore-amrnb-dev libopencore-amrwb-dev libavfilter-dev \
                 librtmp-dev libvo-aacenc-dev libjpeg-dev libx264-dev libjson-glib-dev mono-mcs mono-devel \
                 libgtk2.0-dev libcanberra-gtk* libgtk-3-dev python3-libxml2 libasound2-dev

#Unavailable on Armbian Buster Legacy
#sudo apt install libwpewebkit-1.0-dev libwpebackend-fdo-1.0-dev libsrt-gnutls-dev libopenaptx-dev libldacbt-enc-dev

#RockPro64 armbian jammy
#sudo apt install libopenh264-dev libfreeaptx-dev

#Armbian
#sudo apt install libfdk-aac-dev libfaac-dev

#meson needs to be in the sudo PYTHONPATH variable
echo "*****************************"
echo "*   Upgrading Pip"
echo "*****************************"
sudo python3 -m pip install --upgrade pip
echo "*****************************"
echo "*   Installing Meson"
echo "*****************************"
sudo python3 -m pip install meson
echo "*****************************"
echo "*   Installing Ninja"
echo "*****************************"
sudo python3 -m pip install ninja
echo "*****************************"
echo "*   Installing Setuptools"
echo "*****************************"
sudo python3 -m pip install setuptools
echo "*****************************"
echo "*   Installing cmake"
echo "*****************************"
sudo python3 -m pip install cmake

#Wont install on Armbian Buster Legacy
#sudo python3 -m pip install hotdoc

echo "*****************************"
echo "*   Installing opency"
echo "*****************************"
#libopencv-dev replaced with
sudo python -m pip install opencv-python
echo "*****************************"
echo "*   Installing Contrib"
echo "*****************************"
#sudo python -m pip install opencv-contrib-python


buildMake() {
    if [ $SKIP -eq 1 ]
    then
        echo "*****************************"
        echo "*** Skipping $1/$2 ***"
        echo "*****************************"
        return
    fi

    echo "*****************************"
    echo "* Building Github Project"
    echo "* Owner is $1"
    echo "* Repo is $2"
    echo "*****************************"

      cd /tmp
    sudo rm -rf $2
    git clone https://github.com/$1/$2.git
    cd $2
    meson builddir && ninja -C builddir
    sudo ninja -C builddir install
    cd ..

    checkWithUser
}

buildNinja() {
    if [ $SKIP -eq 1 ]
    then
        echo "*****************************"
        echo "*** Skipping $1/$2 ***"
        echo "*****************************"
        return
    fi

    echo "*****************************"
    echo "* Building Github Project"
    echo "* Owner is $1"
    echo "* Repo is $2"
    echo "*****************************"

    cd /tmp
    sudo rm -rf $2
    git clone https://github.com/$1/$2.git
    cd $2
    meson build
    ninja -C build
    sudo ninja -C build install
    sudo ldconfig
    cd ..

    checkWithUser
}


buildProjectDesc () {
    if [ $SKIP -eq 1 ] 
    then
        echo "*****************************"
        echo "*** Skipping $1 ***"
        echo "*****************************"
        return
    fi
    echo "*****************************"
    echo "* Project is $1"
    echo "* File is $2"
    echo "* Version is $3"
    echo "*****************************"

    cd $BUILD_PATH
    # download and unpack the lib
    wget https://gstreamer.freedesktop.org/src/$1/$2-$3.tar.xz
    tar -xf $2-$3.tar.xz
    cd $2-$3
    # make an installation folder
    sudo rm -rf build

    ### ADDED "-D gl_winsys=egl" to successfully compile gst-bad on raspbian bullseye
    # run meson (a kind of cmake)
    $MESON_BIN --prefix=$INSTALL_PATH -D gl_winsys=egl -D buildtype=release -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ -D package-name="GStreamer $3 BLFS" build

    # install the libraries
    sudo $MESON_BIN install -C build
    sudo ldconfig

    echo "Clean up..."
    cd $BUILD_PATH
    sudo rm $2-$3.tar.xz
    #sudo rm -rf $2-$3

    checkWithUser
}

buildProject () {
    if [ $SKIP -eq 1 ] 
    then
        echo "*****************************"
        echo "*** Skipping $1 ***"
        echo "*****************************"
        return
    fi
    echo "*****************************"
    echo "* Project is $1"
    echo "* File is $2"
    echo "* Version is $3"
    echo "* Extension is $4"
    echo "*****************************"

    cd $BUILD_PATH

    # download and unpack the lib
    wget https://gstreamer.freedesktop.org/src/$1/$2-$3.$4
    tar -xf $2-$3.$4
    cd $2-$3
    # make an installation folder
    sudo rm -rf build
    # run meson (a kind of cmake)
    $MESON_BIN --prefix=$INSTALL_PATH -D buildtype=release build

    # install the libraries
    sudo $MESON_BIN install -C build
    sudo ldconfig

    echo "Clean up..."
    cd $BUILD_PATH
    sudo rm $2-$3.tar.xz
    #sudo rm -rf $2-$3

    checkWithUser
}

checkWithUser () {
    if [ $CHECK -ne 1 ] 
    then
        return
    fi

    read -p "Do you want to proceed? (yes/no) " yn

    case $yn in 
        y);;
        ye);;
	yes );;
	no ) echo exiting...;
		exit;;
	* ) echo invalid response;
		exit 1;;
    esac
}

#Build gstreamer

# remove the old version
if [ $SKIP -nq 1 ] 
then
    echo "*****************************"
    echo "*** Clean up previous deployment ***"
    echo "*****************************"
    sudo rm -rf $INSTALL_PATH/bin/gst-*
    sudo rm -rf $INSTALL_PATH/include/gstreamer-1.0
fi

buildMake "videolabs" "libmicrodns"

buildNinja "tinyalsa" "tinyalsa"

buildNinja "Avnu" "libavtp"

buildProject "orc" "orc" "0.4.32" "tar.xz"

buildProjectDesc "gstreamer" "gstreamer" $VERSION
#Second time build for self dependencies
#buildProjectDesc "gstreamer" "gstreamer" $VERSION

buildNinja "libnice" "libnice"

ls $PKG_CONFIG_PATH
buildProjectDesc "gst-plugins-base" "gst-plugins-base" $VERSION
#Second time build for self dependencies
#buildProjectDesc "gst-plugins-base" "gst-plugins-base" $VERSION

buildProject "gst-python" "gst-python" $VERSION "tar.xz"

buildProjectDesc "gst-plugins-bad" "gst-plugins-bad" $VERSION

buildProjectDesc "gst-plugins-good" "gst-plugins-good" $VERSION

buildProjectDesc "gst-plugins-ugly" "gst-plugins-ugly" $VERSION

buildProjectDesc "gst-libav" "gst-libav" $VERSION
#buildProjectDesc "gst-omx" "gst-omx"  $VERSION

#buildProjectDesc "gst-rtsp" "gst-rtsp-server" $VERSION

buildProjectDesc "gst-rtsp-server" "gst-rtsp-server" $VERSION

buildProject "gst-devtools" "gst-devtools" $VERSION "tar.xz"

buildProject "gstreamer-editing-services" "gst-editing-services" $VERSION "tar.xz"

sudo ldconfig
buildProject "gstreamer-sharp" "gstreamer-sharp" $VERSION "tar.xz"

buildProject "gstreamer-vaapi" "gstreamer-vaapi" $VERSION "tar.xz"

echo "*****************************"
echo "* Moving girepository files..."
echo "*****************************"
#sudo mv /usr/local/lib/x86_64-linux-gnu/girepository-1.0/Gst* /usr/lib/x86_64-linux-gnu/girepository-1.0/
#sudo mv /usr/local/lib/x86_64-linux-gnu/girepository-1.0/libgst* /usr/lib/x86_64-linux-gnu/girepository-1.0/
sudo ldconfig

echo "*****************************"
echo "* Moving typelib files"
echo "*****************************"
#Armbian jammy rockpro64
sudo cp /usr/local/lib/aarch64-linux-gnu/girepository-1.0/Gst* /usr/lib/aarch64-linux-gnu/girepository-1.0/
#Raspbian
sudo cp /usr/local/lib/arm-linux-gnueabihf/girepository-1.0/Gst* /usr/lib/arm-linux-gnueabihf/girepository-1.0/
sudo cp /usr/local/lib/python3/dist-packages/gi/overrides/* /usr/lib/python3/dist-packages/gi/overrides/

echo "*****************************"
echo "* Clean up sources..."
echo "*****************************"
#sudo rm -rf $BUILD_PATH/orc*
#sudo rm -rf $BUILD_PATH/gst*

#
# TODO TEST UGLY
#
# test if the module exists (for instance x264enc)
#gst-inspect-1.0 x264enc
# if not, make sure you have the libraries installed
# stackoverflow is your friend here
#sudo apt-get install libx264-dev
# check which the GStreamer site which plugin holds the module
# rebuild the module (in this case the ugly)
#cd gst-plugins-ugly-$VERSION
# remove the previous build
#rm-rf build
# make a new build folder
#mkdir build && cd build
#meson --prefix=/usr       \
#      -D buildtype=release \
#      -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ \
#      -D package-name="GStreamer $VERSION BLFS" ..
#ninja -j4
#sudo ninja install
#sudo ldconfig

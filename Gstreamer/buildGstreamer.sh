#!/bin/sh

CPU_COUNT=$(nproc --all)
VERSION=1.20.0

sudo apt install python3-pip
python3 -m pip install meson


buildProjectDesc () {
    echo "Project is $1"
    echo "File is $2"
    echo "Version is $3"

    cd ~
    # download and unpack the lib
    wget https://gstreamer.freedesktop.org/src/$1/$2-$3.tar.xz
    sudo tar -xf $2-$3.tar.xz
    cd $2-$3
    # make an installation folder
    rm -rf build
    mkdir build && cd build
    # run meson (a kind of cmake)
    meson --prefix=/usr \
       -D buildtype=release \
        -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ \
        -D package-name="GStreamer $3 BLFS" ..
    # build the software
    ninja -j$CPU_COUNT
    # test the software (optional)
    #ninja test
    # install the libraries
    sudo ninja install
    sudo ldconfig
}

buildProject () {
    echo "Project is $1"
    echo "File is $2"
    echo "Version is $3"
    cd ~
    # download and unpack the lib
    wget https://gstreamer.freedesktop.org/src/$1/$2-$3tar.xz
    sudo tar -xf $2-$3.tar.xz
    cd $2-$3
    # make an installation folder
    rm -rf build
    mkdir build && cd build
    # run meson (a kind of cmake)
    meson --prefix=/usr \
       -D buildtype=release

    # build the software
    ninja -j$CPU_COUNT
    # test the software (optional)
    #ninja test
    # install the libraries
    sudo ninja install
    sudo ldconfig
}


#Build gstreamer

# remove the old version
sudo rm -rf /usr/bin/gst-*
sudo rm -rf /usr/include/gstreamer-1.0
# install a few dependencies
sudo apt-get install cmake meson flex bison -y
sudo apt-get install libglib2.0-dev libjpeg-dev libx264-dev -y
sudo apt-get install libgtk2.0-dev libcanberra-gtk* libgtk-3-dev -y
# needed for alsasrc, alsasink
sudo apt-get install libasound2-dev -y

buildProject "orc" "orc" "0.4.32"

buildProjectDesc "gstreamer" "gstreamer" $VERSION
buildProjectDesc "gst-plugins-base" "gst-plugins-base" $VERSION

sudo apt-get install libjpeg-dev -y
#TODO libsoup
buildProjectDesc "gst-plugins-good" "gst-plugins-good" $VERSION

#TODO libnice
sudo apt install librtmp-dev -y
sudo apt-get install libvo-aacenc-dev -y
buildProjectDesc "gst-plugins-bad" "gst-plugins-bad" $VERSION
sudo apt-get install libx264-dev -y
buildProjectDesc "gst-plugins-ugly" "gst-plugins-ugly" $VERSION

buildProjectDesc "gst-libav" "gst-libav" $VERSION

#buildProjectDesc "gst-omx" "gst-omx"  $VERSION

buildProjectDesc "gst-rtsp-server" "gst-rtsp-server" $VERSION

sudo apt install libjson-glib-dev
buildProject "gst-devtools" "gst-devtools" $VERSION

buildProject "gstreamer-editing-services" "gst-editing-services" $VERSION

sudo apt install mono-mcs mono-devel
buildProject "gstreamer-sharp" "gstreamer-sharp" $VERSION

buildProject "gstreamer-vaapi" "gstreamer-vaapi" $VERSION



git clone https://gitlab.freedesktop.org/gstreamer/gstreamer.git
cd gstreamer
git checkout tags/1.18.4
meson --prefix=/usr/local -D buildtype=release -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ build

#install first set of dependencies
sudo meson install -C build

#reconfigure to discover self dependencies
meson --prefix=/usr/local -D buildtype=release -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ --reconfigure build
sudo meson install -C build

#Armbian jammy rockpro64
sudo cp /usr/local/lib/aarch64-linux-gnu/girepository-1.0/Gst* /usr/lib/aarch64-linux-gnu/girepository-1.0/
#x86_64
sudo cp /usr/local/lib/x86_64-linux-gnu/girepository-1.0/* /usr/lib/x86_64-linux-gnu/girepository-1.0/
#Raspbian
sudo cp /usr/local/lib/arm-linux-gnueabihf/girepository-1.0/Gst* /usr/lib/arm-linux-gnueabihf/girepository-1.0/

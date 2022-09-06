#!/usr/bin/env bash
source $(dirname "$0")/../common/checkFunc.sh

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
    git -C $2 pull 2> /dev/null || git clone https://github.com/$1/$2.git
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
    git -C $2 pull 2> /dev/null || git clone https://github.com/$1/$2.git
    cd $2
    meson build
    ninja -C build
    sudo ninja -C build install
    sudo ldconfig
    cd ..

    checkWithUser
}
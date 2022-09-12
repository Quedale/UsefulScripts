#!/usr/bin/env bash
#SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
source $SCRIPT_DIR/checkFunc.sh

buildMake1() {
    local srcdir prefix autoreconf configure configcustom cmakedir cmakeargs # reset first
    local "${@}"
    build_start=$SECONDS
    if [ $SKIP -eq 1 ]
    then
        echo "*****************************"
        echo "*** Skipping Make ${srcdir} ***"
        echo "*****************************"
        return
    fi

    echo "*****************************"
    echo "* Building Github Project"
    echo "* Src dir : ${srcdir}"
    echo "* Prefix : ${prefix}"
    echo "* Bootstrap: ${bootstrap}"
    echo "*****************************"

    cd ${srcdir}
    if [ -f "./bootstrap" ]; then
    #if [ ! -z "${bootstrap}" ]; then
        echo "*****************************"
        echo "*** bootstrap ${srcdir} ***"
        echo "*****************************"
        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            ./bootstrap
    elif [ -f "./bootstrap.sh" ]; then
        echo "*****************************"
        echo "*** bootstrap.sh ${srcdir} ***"
        echo "*****************************"
        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            ./bootstrap.sh
    elif [ -f "./autogen.sh" ]; then
        echo "*****************************"
        echo "*** autogen ${srcdir} ***"
        echo "*****************************"
        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            ./autogen.sh
    fi

    if [ ! -z "${autoreconf}" ] 
    then
        echo "*****************************"
        echo "*** autoreconf ${srcdir} ***"
        echo "*****************************"
        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            autoreconf -fiv
    fi

    if [ ! -z "${cmakedir}" ] 
    then
        echo "*****************************"
        echo "*** cmake ${srcdir} ***"
        echo "*** Argss ${cmakeargs} "
        echo "*****************************"

        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
        cmake -G "Unix Makefiles" \
            ${cmakeargs} \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX="${prefix}" \
            -DENABLE_TESTS=OFF -DENABLE_SHARED=on \
            -DENABLE_NASM=on \
            -DPYTHON_EXECUTABLE="$(which python3)" \
            -DBUILD_DEC=OFF \
            ${cmakedir}
    fi
    
    if [ ! -z "${configcustom}" ]; then
        echo "*****************************"
        echo "*** custom config ${srcdir} ***"
        echo "*** ${configcustom} ***"
        echo "*****************************"

        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            bash ${configcustom}

    elif [ -f "./configure" ]; then
        echo "*****************************"
        echo "*** configure ${srcdir} ***"
        echo "*****************************"

        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            ./configure \
                --prefix=${prefix} \
                --disable-unit-tests \
                --disable-examples \
                ${configure}
          
          #--bindir="$HOME/bin" #Doesnt work for libvpx
    else
      echo "*****************************"
      echo "*** no configuration available ${srcdir} ***"
      echo "*****************************"
    fi

    echo "*****************************"
    echo "*** compile ${srcdir} ***"
    echo "*****************************"
    C_INCLUDE_PATH="${prefix}/include" \
    CPLUS_INCLUDE_PATH="${prefix}/include" \
    PATH="$HOME/bin:$PATH" \
    LD_LIBRARY_PATH="${prefix}/lib" \
    PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
      make -j$(nproc)

    echo "*****************************"
    echo "*** install ${srcdir} ***"
    echo "*****************************"
    C_INCLUDE_PATH="${prefix}/include" \
    CPLUS_INCLUDE_PATH="${prefix}/include" \
    PATH="$HOME/bin:$PATH" \
    LD_LIBRARY_PATH="${prefix}/lib" \
    PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
      make -j$(nproc) install #exec_prefix="$HOME/bin"

    build_time=$(( SECONDS - build_start ))
    displaytime $build_time
    
    checkWithUser
}

buildMeson1() {
    local srcdir mesonargs prefix setuppatch bindir
    local "${@}"

    build_start=$SECONDS
    if [ $SKIP -eq 1 ]
    then
        echo "*****************************"
        echo "*** Skipping Meson ${srcdir} ***"
        echo "*****************************"
        return
    fi

    echo "*****************************"
    echo "* Building Github Project"
    echo "* Src dir : ${srcdir}"
    echo "* Prefix : ${prefix}"
    echo "*****************************"

    bindir_val=""
    if [ ! -z "${bindir}" ]; then
        bindir_val="--bindir=${bindir}"
    fi
    #rm -rf ${srcdir}/build
    if [ ! -d "${srcdir}/build_dir" ]; then
        mkdir -p ${srcdir}/build_dir

        cd ${srcdir}
        if [ -d "./subprojects" ]; then
            echo "*****************************"
            echo "*** Download Subprojects ${srcdir} ***"
            echo "*****************************"
            C_INCLUDE_PATH="${prefix}/include" \
            CPLUS_INCLUDE_PATH="${prefix}/include" \
            PATH="$HOME/bin:$PATH" \
            LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
            LD_LIBRARY_PATH="${prefix}/lib" \
            PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
                meson subprojects download
        fi

        echo "setup patch : ${setuppatch}"
        if [ ! -z "${setuppatch}" ]; then
            echo "*****************************"
            echo "*** Meson Setup Patch ${srcdir} ***"
            echo "*** ${setuppatch} ***"
            echo "*****************************"
            C_INCLUDE_PATH="${prefix}/include" \
            CPLUS_INCLUDE_PATH="${prefix}/include" \
            PATH="$HOME/bin:$PATH" \
            LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
            LD_LIBRARY_PATH="${prefix}/lib" \
            PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
                bash -c "${setuppatch}"
        fi

        echo "*****************************"
        echo "*** Meson Setup ${srcdir}"
        echo "*****************************"

        cd build_dir
        # C_INCLUDE_PATH="${prefix}/include" \
        # CPLUS_INCLUDE_PATH="${prefix}/include" \
        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            meson setup \
                ${mesonargs} \
                --default-library=static .. \
                --prefix=${prefix} \
                $bindir_val \
                --libdir=${prefix}/lib \
                --includedir=${prefix}/include \
                --buildtype=release 

    else
        cd ${srcdir}
        if [ -d "./subprojects" ]; then
            echo "*****************************"
            echo "*** Meson Update ${srcdir}"
            echo "*****************************"
            C_INCLUDE_PATH="${prefix}/include" \
            CPLUS_INCLUDE_PATH="${prefix}/include" \
            PATH="$HOME/bin:$PATH" \
            LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
            LD_LIBRARY_PATH="${prefix}/lib" \
            PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
                meson subprojects update
        fi

        if [ ! -z "${setuppatch}" ]; then
            echo "*****************************"
            echo "*** Meson Setup Patch ${srcdir} ***"
            echo "*** ${setuppatch} ***"
            echo "*****************************"
            C_INCLUDE_PATH="${prefix}/include" \
            CPLUS_INCLUDE_PATH="${prefix}/include" \
            PATH="$HOME/bin:$PATH" \
            LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
            LD_LIBRARY_PATH="${prefix}/lib" \
            PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
                bash -c "${setuppatch}"
        fi

        echo "*****************************"
        echo "*** Meson Reconfigure ${srcdir}"
        echo "*****************************"
        cd build_dir
        # C_INCLUDE_PATH="${prefix}/include" \
        # CPLUS_INCLUDE_PATH="${prefix}/include" \
        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            meson setup \
                ${mesonargs} \
                --prefix=${prefix} \
                $bindir_val \
                --libdir=${prefix}/lib \
                --includedir=${prefix}/include \
                --buildtype=release \
                --reconfigure
    fi

    echo "*****************************"
    echo "*** Meson Compile ${srcdir}"
    echo "*****************************"
    # C_INCLUDE_PATH="${prefix}/include" \
    # CPLUS_INCLUDE_PATH="${prefix}/include" \
    C_INCLUDE_PATH="${prefix}/include" \
    CPLUS_INCLUDE_PATH="${prefix}/include" \
    PATH="$HOME/bin:$PATH" \
    LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
    LD_LIBRARY_PATH="${prefix}/lib" \
    PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
      ninja

    echo "*****************************"
    echo "*** Meson Install ${srcdir}"
    echo "*****************************"
    # C_INCLUDE_PATH="${prefix}/include" \
    # CPLUS_INCLUDE_PATH="${prefix}/include" \
    C_INCLUDE_PATH="${prefix}/include" \
    CPLUS_INCLUDE_PATH="${prefix}/include" \
    PATH="$HOME/bin:$PATH" \
    LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
    LD_LIBRARY_PATH="${prefix}/lib" \
    PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
      ninja install
    
    build_time=$(( SECONDS - build_start ))
    displaytime $build_time
    
    checkWithUser
}

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
    git -C $2 pull 2> /dev/null || git clone https://github.com/$1/$2.git
    cd $2
    meson build
    ninja -C build
    sudo ninja -C build install
    sudo ldconfig
    cd ..

    checkWithUser
}
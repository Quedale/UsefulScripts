#!/usr/bin/env bash
#SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
source $SCRIPT_DIR/checkFunc.sh

ORANGE='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

buildMake1() {
    local srcdir prefix autoreconf preconfigure configure configcustom cmakedir autogenargs cmakeargs makeargs # reset first
    local "${@}"
    build_start=$SECONDS
    if [ $SKIP -eq 1 ]
    then
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** Skipping Make ${srcdir} ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"
        return
    fi

    printf "${ORANGE}*****************************\n${NC}"
    printf "${ORANGE}* Building Github Project ***\n${NC}"
    printf "${ORANGE}* Src dir : ${srcdir} ***\n${NC}"
    printf "${ORANGE}* Prefix : ${prefix} ***\n${NC}"
    printf "${ORANGE}*****************************\n${NC}"

    cd ${srcdir}
    if [ -f "./bootstrap" ]; then
    #if [ ! -z "${bootstrap}" ]; then
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** bootstrap ${srcdir} ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"
        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            ./bootstrap
        status=$?
        if [ $status -ne 0 ]; then
            printf "${RED}*****************************\n${NC}"
            printf "${RED}*** ./bootstrap failed ${srcdir} ***\n${NC}"
            printf "${RED}*****************************\n${NC}"
        fi
    elif [ -f "./bootstrap.sh" ]; then
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** bootstrap.sh ${srcdir} ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"
        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            ./bootstrap.sh
        status=$?
        if [ $status -ne 0 ]; then
            printf "${RED}*****************************\n${NC}"
            printf "${RED}*** ./bootstrap.sh failed ${srcdir} ***\n${NC}"
            printf "${RED}*****************************\n${NC}"
        fi
    elif [ -f "./autogen.sh" ]; then
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** autogen ${srcdir} ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"
        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            ./autogen.sh ${autogenargs}
        status=$?
        if [ $status -ne 0 ]; then
            printf "${RED}*****************************\n${NC}"
            printf "${RED}*** Autogen failed ${srcdir} ***\n${NC}"
            printf "${RED}*****************************\n${NC}"
        fi
    fi

    if [ ! -z "${autoreconf}" ] 
    then
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** autoreconf ${srcdir} ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"
        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            autoreconf -fiv
        status=$?
        if [ $status -ne 0 ]; then
            printf "${RED}*****************************\n${NC}"
            printf "${RED}*** Autoreconf failed ${srcdir} ***\n${NC}"
            printf "${RED}*****************************\n${NC}"
        fi
    fi

    if [ ! -z "${cmakedir}" ] 
    then
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** cmake ${srcdir} ***\n${NC}"
        printf "${ORANGE}*** Args ${cmakeargs} ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"

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
            "${cmakedir}"
        status=$?
        if [ $status -ne 0 ]; then
            printf "${RED}*****************************\n${NC}"
            printf "${RED}*** CMake failed ${srcdir} ***\n${NC}"
            printf "${RED}*****************************\n${NC}"
        fi
    fi
    
    if [ ! -z "${preconfigure}" ]; then
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}* Preconfigure              *\n${NC}"
        printf "${ORANGE}* ${preconfigure} *\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"
        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            bash -c "${preconfigure}"
        status=$?
        if [ $status -ne 0 ]; then
            printf "${RED}*****************************\n${NC}"
            printf "${RED}*** Preconfigure failed ${srcdir} ***\n${NC}"
            printf "${RED}*****************************\n${NC}"
        fi
    fi
    
    if [ ! -z "${configcustom}" ]; then
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** custom config ${srcdir} ***\n${NC}"
        printf "${ORANGE}*** ${configcustom} ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"

        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            bash -c "${configcustom}"
        status=$?
        if [ $status -ne 0 ]; then
            printf "${RED}*****************************\n${NC}"
            printf "${RED}*** Custom Config failed ${srcdir} ***\n${NC}"
            printf "${RED}*****************************\n${NC}"
        fi
    elif [ -f "./configure.sh" ]; then
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** configure ${srcdir} ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"

        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            ./configure \
                --prefix=${prefix} \
                ${configure}
        status=$?
        if [ $status -ne 0 ]; then
            printf "${RED}*****************************\n${NC}"
            printf "${RED}*** ./configure.sh failed ${srcdir} ***\n${NC}"
            printf "${RED}*****************************\n${NC}"
        fi
    elif [ -f "./configure" ]; then
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** configure ${srcdir} ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"
    
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
        status=$?
        if [ $status -ne 0 ]; then
            printf "${RED}*****************************\n${NC}"
            printf "${RED}*** ./configure failed ${srcdir} ***\n${NC}"
            printf "${RED}*****************************\n${NC}"
        fi
    else
      printf "${ORANGE}*****************************\n${NC}"
      printf "${ORANGE}*** no configuration available ${srcdir} ***\n${NC}"
      printf "${ORANGE}*****************************\n${NC}"
    fi

    printf "${ORANGE}*****************************\n${NC}"
    printf "${ORANGE}*** compile ${srcdir} ***\n${NC}"
    printf "${ORANGE}*** Make Args : ${makeargs} ***\n${NC}"
    printf "${ORANGE}*****************************\n${NC}"
    C_INCLUDE_PATH="${prefix}/include" \
    CPLUS_INCLUDE_PATH="${prefix}/include" \
    PATH="$HOME/bin:$PATH" \
    LD_LIBRARY_PATH="${prefix}/lib" \
    PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
      make -j$(nproc) ${makeargs}
    status=$?
    if [ $status -ne 0 ]; then
        printf "${RED}*****************************\n${NC}"
        printf "${RED}*** Make failed ${srcdir} ***\n${NC}"
        printf "${RED}*****************************\n${NC}"
    fi

    printf "${ORANGE}*****************************\n${NC}"
    printf "${ORANGE}*** install ${srcdir} ***\n${NC}"
    printf "${ORANGE}*** Make Args : ${makeargs} ***\n${NC}"
    printf "${ORANGE}*****************************\n${NC}"
    C_INCLUDE_PATH="${prefix}/include" \
    CPLUS_INCLUDE_PATH="${prefix}/include" \
    PATH="$HOME/bin:$PATH" \
    LD_LIBRARY_PATH="${prefix}/lib" \
    PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
      make -j$(nproc) ${makeargs} install #exec_prefix="$HOME/bin"
    status=$?
    if [ $status -ne 0 ]; then
        printf "${RED}*****************************\n${NC}"
        printf "${RED}*** Make failed ${srcdir} ***\n${NC}"
        printf "${RED}*****************************\n${NC}"
    fi

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
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** Skipping Meson ${srcdir} ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"
        return
    fi

    printf "${ORANGE}*****************************\n${NC}"
    printf "${ORANGE}* Building Github Project ***\n${NC}"
    printf "${ORANGE}* Src dir : ${srcdir} ***\n${NC}"
    printf "${ORANGE}* Prefix : ${prefix} ***\n${NC}"
    printf "${ORANGE}*****************************\n${NC}"

    bindir_val=""
    if [ ! -z "${bindir}" ]; then
        bindir_val="--bindir=${bindir}"
    fi
    #rm -rf ${srcdir}/build
    if [ ! -d "${srcdir}/build_dir" ]; then
        mkdir -p ${srcdir}/build_dir

        cd ${srcdir}
        if [ -d "./subprojects" ]; then
            printf "${ORANGE}*****************************\n${NC}"
            printf "${ORANGE}*** Download Subprojects ${srcdir} ***\n${NC}"
            printf "${ORANGE}*****************************\n${NC}"
            # C_INCLUDE_PATH="${prefix}/include" \
            # CPLUS_INCLUDE_PATH="${prefix}/include" \
            # PATH="$HOME/bin:$PATH" \
            # LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
            # LD_LIBRARY_PATH="${prefix}/lib" \
            # PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            #     meson subprojects download
        fi

        echo "setup patch : ${setuppatch}"
        if [ ! -z "${setuppatch}" ]; then
            printf "${ORANGE}*****************************\n${NC}"
            printf "${ORANGE}*** Meson Setup Patch ${srcdir} ***\n${NC}"
            printf "${ORANGE}*** ${setuppatch} ***\n${NC}"
            printf "${ORANGE}*****************************\n${NC}"
            C_INCLUDE_PATH="${prefix}/include" \
            CPLUS_INCLUDE_PATH="${prefix}/include" \
            PATH="$HOME/bin:$PATH" \
            LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
            LD_LIBRARY_PATH="${prefix}/lib" \
            PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
                bash -c "${setuppatch}"
            status=$?
            if [ $status -ne 0 ]; then
                printf "${RED}*****************************\n${NC}"
                printf "${RED}*** Bash Setup failed ${srcdir} ***\n${NC}"
                printf "${RED}*****************************\n${NC}"
            fi
        fi

        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** Meson Setup ${srcdir} ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"

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
        status=$?
        if [ $status -ne 0 ]; then
            printf "${RED}*****************************\n${NC}"
            printf "${RED}*** Meson Setup failed ${srcdir} ***\n${NC}"
            printf "${RED}*****************************\n${NC}"
        fi
    else
        cd ${srcdir}
        if [ -d "./subprojects" ]; then
            printf "${ORANGE}*****************************\n${NC}"
            printf "${ORANGE}*** Meson Update ${srcdir} ***\n${NC}"
            printf "${ORANGE}*****************************\n${NC}"
            # C_INCLUDE_PATH="${prefix}/include" \
            # CPLUS_INCLUDE_PATH="${prefix}/include" \
            # PATH="$HOME/bin:$PATH" \
            # LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
            # LD_LIBRARY_PATH="${prefix}/lib" \
            # PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            #     meson subprojects update
        fi

        if [ ! -z "${setuppatch}" ]; then
            printf "${ORANGE}*****************************\n${NC}"
            printf "${ORANGE}*** Meson Setup Patch ${srcdir} ***\n${NC}"
            printf "${ORANGE}*** ${setuppatch} ***\n${NC}"
            printf "${ORANGE}*****************************\n${NC}"
            C_INCLUDE_PATH="${prefix}/include" \
            CPLUS_INCLUDE_PATH="${prefix}/include" \
            PATH="$HOME/bin:$PATH" \
            LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
            LD_LIBRARY_PATH="${prefix}/lib" \
            PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
                bash -c "${setuppatch}"
            status=$?
            if [ $status -ne 0 ]; then
                printf "${RED}*****************************\n${NC}"
                printf "${RED}*** Bash Setup failed ${srcdir} ***\n${NC}"
                printf "${RED}*****************************\n${NC}"
            fi
        fi

        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** Meson Reconfigure ${srcdir} ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"
        rm -rf build_dir #Cmake state somehow gets messed up
        mkdir build_dir
        cd build_dir
        # C_INCLUDE_PATH="${prefix}/include" \
        # CPLUS_INCLUDE_PATH="${prefix}/include" \
        C_INCLUDE_PATH="${prefix}/include" \
        CPLUS_INCLUDE_PATH="${prefix}/include" \
        PATH="${prefix}\bin:$HOME/bin:$PATH" \
        LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
            meson setup \
                ${mesonargs} \
                --prefix=${prefix} \
                $bindir_val \
                --libdir=${prefix}/lib \
                --includedir=${prefix}/include \
                --buildtype=release 
                #--reconfigure
        status=$?
        if [ $status -ne 0 ]; then
            printf "${RED}*****************************\n${NC}"
            printf "${RED}*** Meson Setup failed ${srcdir} ***\n${NC}"
            printf "${RED}*****************************\n${NC}"
        fi
    fi

    printf "${ORANGE}*****************************\n${NC}"
    printf "${ORANGE}*** Meson Compile ${srcdir} ***\n${NC}"
    printf "${ORANGE}*****************************\n${NC}"
    # C_INCLUDE_PATH="${prefix}/include" \
    # CPLUS_INCLUDE_PATH="${prefix}/include" \
    C_INCLUDE_PATH="${prefix}/include" \
    CPLUS_INCLUDE_PATH="${prefix}/include" \
    PATH="$HOME/bin:$PATH" \
    LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
    LD_LIBRARY_PATH="${prefix}/lib" \
    PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
      ninja
    status=$?
    if [ $status -ne 0 ]; then
        printf "${RED}*****************************\n${NC}"
        printf "${RED}*** Ninja failed ${srcdir} ***\n${NC}"
        printf "${RED}*****************************\n${NC}"
    fi

    printf "${ORANGE}*****************************\n${NC}"
    printf "${ORANGE}*** Meson Install ${srcdir} ***\n${NC}"
    printf "${ORANGE}*****************************\n${NC}"
    # C_INCLUDE_PATH="${prefix}/include" \
    # CPLUS_INCLUDE_PATH="${prefix}/include" \
    C_INCLUDE_PATH="${prefix}/include" \
    CPLUS_INCLUDE_PATH="${prefix}/include" \
    PATH="$HOME/bin:$PATH" \
    LIBRARY_PATH="${prefix}/lib:$LIBRARY_PATH" \
    LD_LIBRARY_PATH="${prefix}/lib" \
    PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
      ninja install
    status=$?
    if [ $status -ne 0 ]; then
        printf "${RED}*****************************\n${NC}"
        printf "${RED}*** Ninja Install failed ${srcdir} ***\n${NC}"
        printf "${RED}*****************************\n${NC}"
    fi

    build_time=$(( SECONDS - build_start ))
    displaytime $build_time
    
    checkWithUser
}

buildMake() {
    if [ $SKIP -eq 1 ]
    then
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** Skipping $1/$2 ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"
        return
    fi

    printf "${ORANGE}*****************************\n${NC}"
    printf "${ORANGE}* Building Github Project ***\n${NC}"
    printf "${ORANGE}* Owner is $1 ***\n${NC}"
    printf "${ORANGE}* Repo is $2 ***\n${NC}"
    printf "${ORANGE}*****************************\n${NC}"

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
        printf "${ORANGE}*****************************\n${NC}"
        printf "${ORANGE}*** Skipping $1/$2 ***\n${NC}"
        printf "${ORANGE}*****************************\n${NC}"
        return
    fi

    printf "${ORANGE}*****************************\n${NC}"
    printf "${ORANGE}* Building Github Project *\n${NC}"
    printf "${ORANGE}* Owner is $1 *\n${NC}"
    printf "${ORANGE}* Repo is $2 *\n${NC}"
    printf "${ORANGE}*****************************\n${NC}"

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
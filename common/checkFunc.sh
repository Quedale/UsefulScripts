#!/bin/sh

ORANGE='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

downloadAndExtract (){
  local path file # reset first
  local "${@}"

  if [ $SKIP -eq 1 ]
  then
      printf "${ORANGE}*****************************\n${NC}"
      printf "${ORANGE}*** Skipping Download ${path} ***\n${NC}"
      printf "${ORANGE}*****************************\n${NC}"
      return
  fi

  if [ ! -f "${file}" ]; then
    printf "${ORANGE}*****************************\n${NC}"
    printf "${ORANGE}*** Downloading : ${path} ***\n${NC}"
    printf "${ORANGE}*****************************\n${NC}"
    wget ${path} -O ${file}
  else
    printf "${ORANGE}*****************************\n${NC}"
    printf "${ORANGE}*** Source already downloaded : ${path} ***\n${NC}"
    printf "${ORANGE}*****************************\n${NC}"
  fi

  printf "${ORANGE}*****************************\n${NC}"
  printf "${ORANGE}*** Extracting : ${file} ***\n${NC}"
  printf "${ORANGE}*****************************\n${NC}"
  if [[ ${file} == *.tar.gz ]]; then
    tar xfz ${file}
  elif [[ ${file} == *.tar.xz ]]; then
    tar xf ${file}
  elif [[ ${file} == *.tar.bz2 ]]; then
    tar xjf ${file}
  else
    echo "ERROR FILE NOT FOUND ${path} // ${file}"
    exit 1
  fi
}

pullOrClone (){
  local path tag depth recurse # reset first
  local "${@}"

  if [ $SKIP -eq 1 ]
  then
      printf "${ORANGE}*****************************\n${NC}"
      printf "${ORANGE}*** Skipping Pull/Clone ${tag}@${path} ***\n${NC}"
      printf "${ORANGE}*****************************\n${NC}"
      return
  fi

  recursestr=""
  if [ ! -z "${recurse}" ] 
  then
    recursestr="--recurse-submodules"
  fi
  depthstr=""
  if [ ! -z "${depth}" ] 
  then
    depthstr="--depth ${depth}"
  fi 

  tgstr=""
  tgstr2=""
  if [ ! -z "${tag}" ] 
  then
    tgstr="origin tags/${tag}"
    tgstr2="-b ${tag}"
  fi

  printf "${ORANGE}*****************************\n${NC}"
  printf "${ORANGE}*** Cloning ${tag}@${path} ***\n${NC}"
  printf "${ORANGE}*****************************\n${NC}"
  IFS='/' read -ra ADDR <<< "$path"
  namedotgit=${ADDR[-1]}
  IFS='.' read -ra ADDR <<< "$namedotgit"
  name=${ADDR[0]}
  git -C $name pull $tgstr 2> /dev/null || git clone -j$(nproc) $recursestr $depthstr $tgstr2 ${path}
}

function displaytime {
    local T=$1
    local D=$((T/60/60/24))
    local H=$((T/60/60%24))
    local M=$((T/60%60))
    local S=$((T%60))
    printf "${ORANGE}*****************************\n${NC}"
    printf "${ORANGE}*** "
    (( $D > 0 )) && printf '%d days ' $D
    (( $H > 0 )) && printf '%d hours ' $H
    (( $M > 0 )) && printf '%d minutes ' $M
    (( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
    printf "%d seconds\n${NC}" $S
    printf "${ORANGE}*****************************\n${NC}"
}


checkPkg (){
    local name prefix atleast exact # reset first
    local "${@}"
    
    ver_val=""
    if [ ! -z "${atleast}" ]; then
      ver_val="--atleast-version=${atleast}"
    elif [ ! -z "${exact}" ]; then
      ver_val="--exact-version=${exact}"
    fi

    PATH="$HOME/bin:$PATH" \
    LD_LIBRARY_PATH="${prefix}/lib" \
    PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
    pkg-config --exists --print-errors $ver_val ${name}
    ret=$?
    if [ $ret -eq 0 ]; then
      echo "Installed"
    fi
}

checkProg () {
    local name args prefix # reset first
    local "${@}"

    if !     PATH="$HOME/bin:$PATH" \
    LD_LIBRARY_PATH="${prefix}/lib" \
    PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" command -v ${name} &> /dev/null
    then
        return #Prog not found
    else
        PATH="$HOME/bin:$PATH" \
        LD_LIBRARY_PATH="${prefix}/lib" \
        PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
        command ${name} ${args} &> /dev/null
        status=$?
        if [[ $status -eq 0 ]]; then
            echo "Working"
        else
            return #Prog failed
        fi
    fi
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
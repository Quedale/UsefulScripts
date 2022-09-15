#!/bin/sh

downloadAndExtract (){
  local path file # reset first
  local "${@}"

  if [ $SKIP -eq 1 ]
  then
      echo "*****************************"
      echo "*** Skipping Download ${path} ***"
      echo "*****************************"
      return
  fi

  if [ ! -f "${file}" ]; then
    echo "*****************************"
    echo "*** Downloading : ${path} ***"
    echo "*****************************"
    wget ${path}
  else
    echo "*****************************"
    echo "*** Source already downloaded : ${path} ***"
    echo "*****************************"
  fi

  echo "*****************************"
  echo "*** Extracting : ${file} ***"
  echo "*****************************"
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
      echo "*****************************"
      echo "*** Skipping Pull/Clone ${tag}@${path} ***"
      echo "*****************************"
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

  echo "*****************************"
  echo "*** Cloning ${tag}@${path} ***"
  echo "*****************************"
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
    echo "*****************************"
    printf '*** '
    (( $D > 0 )) && printf '%d days ' $D
    (( $H > 0 )) && printf '%d hours ' $H
    (( $M > 0 )) && printf '%d minutes ' $M
    (( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
    printf '%d seconds\n' $S
    echo "*****************************"
}


checkPkg (){
    local name prefix # reset first
    local "${@}"
    
    PATH="$HOME/bin:$PATH" \
    LD_LIBRARY_PATH="${prefix}/lib" \
    PKG_CONFIG_PATH="${prefix}/lib/pkgconfig" \
    pkg-config --exists --print-errors ${name} 2> /dev/null || return
    echo "Installed"
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
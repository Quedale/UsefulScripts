#!/bin/sh

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
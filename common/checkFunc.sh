#!/bin/sh
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
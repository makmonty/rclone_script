#!/bin/bash

# global variables
repo="https://github.com/makmonty/rclone_script.git"
path=~/scripts/rclone_script
setupScript=${path}/rclone_script-setup.sh

if ! command -v git &> /dev/null
then
	sudo apt-get install git
fi

git clone ${repo} ${path}

$setupScript
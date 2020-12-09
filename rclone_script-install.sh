#!/bin/bash

# global variables
repo="https://github.com/makmonty/rclone_script.git"
branch="master"
path=~/scripts/rclone_script
setup_script=${path}/rclone_script-setup.sh

if ! command -v git &> /dev/null
then
	sudo apt-get install git
fi

git clone ${repo} ${path}

$setup_script
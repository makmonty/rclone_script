#!/bin/bash

# define colors for output
NORMAL="\Zn"
BLACK="\Z0"
RED="\Z1"
GREEN="\Z2"
YELLOW="\Z3\Zb"
BLUE="\Z4"
MAGENTA="\Z5"
CYAN="\Z6"
WHITE="\Z7"
BOLD="\Zb"
REVERSE="\Zr"
UNDERLINE="\Zu"

repo="https://github.com/makmonty/rclone_script"

currDir=`realpath $(dirname $0)`
config=${currDir}/rclone_script.ini

function log ()
# Prints messages of different severeties to a logfile
# Each message will look something like this:
# <TIMESTAMP>	<SEVERITY>	<CALLING_FUNCTION>	<MESSAGE>
# needs a set variable $logLevel
#	-1 > No logging at all
#	0 > prints ERRORS only
#	1 > prints ERRORS and WARNINGS
#	2 > prints ERRORS, WARNINGS and INFO
#	3 > prints ERRORS, WARNINGS, INFO and DEBUGGING
# needs a set variable $log pointing to a file
# Usage
# log 0 "This is an ERROR Message"
# log 1 "This is a WARNING"
# log 2 "This is just an INFO"
# log 3 "This is a DEBUG message"
{
	local severity=$1
	local message=$2
	
	if (( ${severity} <= ${logLevel} ))
	then
        local level
		case ${severity} in
			0) level="ERROR"  ;;
			1) level="WARNING"  ;;
			2) level="INFO"  ;;
			3) level="DEBUG"  ;;
            *) level=${severity}  ;;
		esac
		
		printf "$(date +%FT%T%:z):\t${level}\t${0##*/}\t${FUNCNAME[1]}\t${message}\n" >> ${logfile} 
	fi
}

function setKeyValueInFile () 
{
    local key=$1
    local value=$2
    local file=$3
    local newLine="${key} = \"${value}\""
    if fileHasKey ${key} ${file};
    then
        sed -i "/^${key} = /c\\${newLine}" ${file}
    else
        echo "${newLine}" >> ${file}
    fi
}

function removeKeyFromFile () 
{
    local key=$1
    local file=$2
    sed -i "/^${key} = /d" ${file}
}

function fileHasKey ()
{
    local key=$1
    local file=$2
    if [[ $(grep -c "^${key} " ${file}) -gt 0 ]]
	then
        return 0
    else
        return 1
    fi
}

function fileHasKeyWithValue ()
{
    local key=$1
    local value=$2
    local file=$3
    if [[ $(grep -c "^${key} = \"${value}\"" ${file}) -gt 0 ]]
	then
        return 0
    else
        return 1
    fi
}

function saveConfiguration ()
{
	echo "remotebasedir=${remotebasedir}" > ${config}
	echo "showNotifications=${showNotifications}" >> ${config}
	echo "syncOnStartStop=${syncOnStartStop}" >> ${config}
	echo "logfile=${currDir}/rclone_script.log" >> ${config}
	echo "neededConnection=${neededConnection}" >> ${config}
    echo "useSystemDirectories=${useSystemDirectories}" >> ${config}
	echo "debug=0" >> ${config}
}
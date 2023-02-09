#!/bin/bash

DEBUG=true

# Checking for sudo privileges
$DEBUG && { echo -e "\e[1;33m[ Debug ]\e[0m Checking for sudo privileges..."; };
[ "$(id -u)" == 0 ] || {
    echo -e "\e[1;31m[ Error ]\e[0m Execute this script with sudo privileges.";
    exit 1;
}
$DEBUG && { echo -e "\e[1;33m[ Debug ]\e[0m It's a super user!"; };

# Checking for missing dependencies and compatibility
$DEBUG && { echo -e "\e[1;33m[ Debug ]\e[0m Checking where I'm running..."; };
os_distro_name="$(lsb_release -is)"
os_distro_release="$(lsb_release -sr)"
$DEBUG && { echo -e "\e[1;33m[ Debug ]\e[0m I'm running in a $os_distro_name $os_distro_release machine!"; };
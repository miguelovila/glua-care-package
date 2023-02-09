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

has_distrobox=true
has_curl=true
has_podman=true
has_docker=true

$DEBUG && { echo -e "\e[1;33m[ Debug ]\e[0m Checking for missing dependencies..."; };
command -v distrobox > /dev/null || { has_distrobox=false; }
command -v curl > /dev/null || { has_curl=false; }
command -v podman > /dev/null || { has_podman=false; }
command -v docker > /dev/null || { has_docker=false; }
$DEBUG && { echo -e "\e[1;33m[ Debug ]\e[0m I got this: has_distrobox=$has_distrobox, has_curl=$has_curl, has_podman=$has_podman, has_docker:$has_docker!"; };
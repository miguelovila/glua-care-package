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

# Missing dependencies prompt
$has_distrobox && $has_curl && ( $has_podman || $has_docker ) || {
	missing_dependencies=""
	$has_distrobox || { missing_dependencies="${missing_dependencies}\e[1:1m distrobox\e[0m"; }
	$has_curl || { missing_dependencies="${missing_dependencies}\e[1:1m curl\e[0m"; }
	$has_podman || $has_docker || {
		[ -z "$missing_dependencies" ] || { missing_dependencies="${missing_dependencies},"; }
		missing_dependencies="${missing_dependencies}\e[1:1m podman, docker (optional)\e[0m";
	}
	echo -e "\e[1;31m[ Error ]\e[0m Missing dependencies:$missing_dependencies.";
	
	# Installing missing dependencies
	$has_curl || {
		$DEBUG && { echo -e "\e[1;33m[ Debug ]\e[0m Asking to install curl..."; };
		while true; do
			read -p $'\e[1;32m[ Input ]\e[0m Install curl automatically? [y/n] ' yn
			case $yn in 
				[yY] )
					has_curl=true
					echo -e "\e[1;34m[  Log  ]\e[0m Installing curl, it may take a while.";
					if [[ $os_distro_name =~ ^(Ubuntu|Lubuntu|Xubuntu|Debian)$ ]]
					then
    						sudo apt update -y &> /dev/null
    						sudo apt install curl -y &> /dev/null
					fi
					if [[ $os_distro_name =~ ^(Fedora)$ ]]
					then
    						sudo dnf update -y &> /dev/null
    						sudo dnf install curl -y &> /dev/null
					fi
					command -v curl > /dev/null || { has_curl=false; }
					$has_curl || {
						echo -e "\e[1;31m[ Error ]\e[0m Unable to install curl. Install it manually and run this script again.";
						exit 1;
					}
					break;;
				[nN]   )
					echo -e "\e[1;34m[  Log  ]\e[0m Installing curl is required. Install it manually and run this script again.";
					exit 0;;
				* )
			esac

		done
	};
	$has_distrobox || {
		$DEBUG && { echo -e "\e[1;33m[ Debug ]\e[0m Asking to install distrobox..."; };
		while true; do
			read -p $'\e[1;32m[ Input ]\e[0m Install distrobox automatically? [y/n] ' yn
			case $yn in 
				[yY] )
					has_distrobox=true
					echo -e "\e[1;34m[  Log  ]\e[0m Installing distrobox, it may take a while.";
					curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh &> /dev/null
					command -v distrobox > /dev/null || { has_distrobox=false; }
					$has_distrobox || {
						echo -e "\e[1;31m[ Error ]\e[0m Unable to install distrobox, install it manually and run this script again. Instructions are available here: https://github.com/89luca89/distrobox";
						exit 1;
					}
					break;;
				[nN]   )
					echo -e "\e[1;34m[  Log  ]\e[0m Installing distrobox is required, install it manually and run this script again. Instructions are available here: https://github.com/89luca89/distrobox";
					exit 0;;
				* )
			esac

		done
	};
	echo "cest fini"
}
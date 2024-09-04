#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
	echo "脚本需要root运行." 1>&2
	exit 1
fi

#Linux Distro Version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    os=$NAME
    ver=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    os=$(lsb_release -si)
    ver=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    os=$DISTRIB_ID
    ver=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    os=Debian
    ver=$(cat /etc/debian_version)
elif [ -f /etc/redhat-release ]; then
    os=Redhat
else
    os=$(uname -s)
    ver=$(uname -r)
fi
echo "[Info]==> $os $ver"

#Virtualization Technology
if [ $(systemd-detect-virt) != "none" ]; then
    virt_tech=$(systemd-detect-virt)
    echo "[Info]==> virt_tech=$virt_tech"
fi

#Memory Size
mem_size=$(free -m | grep Mem | awk '{print $2}')
echo "[Info]==> mem_size=$mem_size"

#Network interface
nic=$(ip addr | grep 'state UP' | awk '{print $2}' | sed 's/.$//' | cut -d'@' -f1 | head -1)
echo "[Info]==> nic=$nic"

# Linux Headers
if [[ "$os" =~ "Debian" ]]; then
    if [ $(uname -m) == "x86_64" ]; then
        apt-get -y install linux-image-amd64 linux-headers-amd64
        if [ $? -ne 0 ]; then
            fail "Linux headers installation failed"
            return 1
        fi
    elif [ $(uname -m) == "aarch64" ]; then
        apt-get -y install linux-image-arm64 linux-headers-arm64
        if [ $? -ne 0 ]; then
            fail "Linux headers  installation failed"
            return 1
        fi
    fi
elif [[ "$os" =~ "Ubuntu" ]]; then
    apt-get -y install linux-image-generic linux-headers-generic
    if [ $? -ne 0 ]; then
        fail "Linux headers  installation failed"
        return 1
    fi
else
    fail "Unsupported OS"
    return 1
fi

#Install dkms if not installed
if [ ! -x /usr/sbin/dkms ]; then
	apt-get -y install dkms
    if [ ! -x /usr/sbin/dkms ]; then
		echo "Error: dkms is not installed" >&2
		exit 1
	fi
fi

#Ensure there is header file
if [ ! -f /usr/src/linux-headers-$(uname -r)/.config ]; then
	if [[ -z $(apt-cache search linux-headers-$(uname -r)) ]]; then
		echo "Error: linux-headers-$(uname -r) not found" >&2
		exit 1
	fi
	apt-get -y install linux-headers-$(uname -r)
	if [ ! -f /usr/src/linux-headers-$(uname -r)/.config ]; then
		echo "Error: linux-headers-$(uname -r) is not installed" >&2
		exit 1
	fi
fi

cd $(dirname "$0")

# make clean
make
make load

echo "==>> Avail:   $(sysctl net.ipv4.tcp_available_congestion_control)"
echo "==>> Current: $(sysctl net.ipv4.tcp_congestion_control)"

echo "==== ALL DONE ===="


#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# ====================================================
#	System Request:CentOS 6+ 、Debian 7+、Ubuntu 14+
#	Author:	Rat's
#	Dscription: tinyPortMapper一键脚本
#	Version: 1.0
#	Blog: https://www.moerats.com
#	Github:https://github.com/iiiiiii1/tinyPortMapper
# ====================================================

Green="\033[32m"
Font="\033[0m"
Blue="\033[33m"

rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

checkos(){
    if [[ -f /etc/redhat-release ]];then
        OS=CentOS
    elif cat /etc/issue | grep -q -E -i "debian";then
        OS=Debian
    elif cat /etc/issue | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    elif cat /proc/version | grep -q -E -i "debian";then
        OS=Debian
    elif cat /proc/version | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    else
        echo "Not supported OS, Please reinstall OS and try again."
        exit 1
    fi
}

disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

disable_iptables(){
    systemctl stop firewalld.service >/dev/null 2>&1
    systemctl disable firewalld.service >/dev/null 2>&1
    service iptables stop >/dev/null 2>&1
    chkconfig iptables off >/dev/null 2>&1
}

get_ip(){
    ip=`curl http://whatismyip.akamai.com`
}

config_tinyPortMapper(){
    echo -e "${Green}请输入tinyPortMapper配置信息！${Font}"
    read -p "请输入本地端口:" port1
    read -p "请输入远程端口:" port2
    read -p "请输入远程IP:" tinyPortMapperip
}

start_tinyPortMapper(){
    echo -e "${Green}正在配置tinyPortMapper...${Font}"
    nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${tinyPortMapperip}:${port2} -t -u > /root/tinymapper.log 2>&1 &
    if [ "${OS}" == 'CentOS' ];then
        sed -i '/exit/d' /etc/rc.d/rc.local
        echo "nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${tinyPortMapperip}:${port2} -t -u > /root/tinymapper.log 2>&1 &
        " >> /etc/rc.d/rc.local
        chmod +x /etc/rc.d/rc.local
    elif [ -s /etc/rc.local ]; then
        sed -i '/exit/d' /etc/rc.local
        echo "nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${tinyPortMapperip}:${port2} -t -u > /root/tinymapper.log 2>&1 &
        " >> /etc/rc.local
        chmod +x /etc/rc.local
    else
echo -e "${Green}检测到系统无rc.local自启，正在为其配置... ${Font} "
echo "[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
 
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
 
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/rc-local.service
echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
" > /etc/rc.local
echo "nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${tinyPortMapperip}:${port2} -t -u > /root/tinymapper.log 2>&1 &
" >> /etc/rc.local
chmod +x /etc/rc.local
systemctl enable rc-local >/dev/null 2>&1
systemctl start rc-local >/dev/null 2>&1
    fi
    get_ip
    sleep 3
    echo
    echo -e "${Green}tinyPortMapper安装并配置成功!${Font}"
    echo -e "${Blue}你的本地端口为:${port1}${Font}"
    echo -e "${Blue}你的远程端口为:${port2}${Font}"
    echo -e "${Blue}你的本地服务器IP为:${ip}${Font}"
    exit 0
}

install_tinyPortMapper(){
echo -e "${Green}即将安装tinyPortMapper...${Font}"
#获取最新版本号
#tinyPortMapper_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/wangyu-/tinyPortMapper/releases | grep -o '"tag_name": ".*"' |head -n 1| sed 's/"//g' | sed 's/tag_name: //g') && echo ${tinyPortMapper_ver}
#下载tinyPortMapper
#wget -N --no-check-certificate "https://github.com/wangyu-/tinyPortMapper/releases/download/${tinyPortMapper_ver}/tinymapper_binaries.tar.gz"
wget -N --no-check-certificate "https://github.com/wangyu-/tinyPortMapper/releases/download/20180224.0/tinymapper_binaries.tar.gz"
#解压tinyPortMapper
tar -xzf tinymapper_binaries.tar.gz
mkdir /tinyPortMapper
KernelBit="$(getconf LONG_BIT)"
    if [[ "$KernelBit" == '32' ]];then
        mv tinymapper_x86 /tinyPortMapper/tinymapper
    elif [[ "$KernelBit" == '64' ]];then
        mv tinymapper_amd64 /tinyPortMapper/tinymapper
    fi
    if [ -f /tinyPortMapper/tinymapper ]; then
    echo -e "${Green}tinyPortMapper安装成功！${Font}"
    else
    echo -e "${Green}tinyPortMapper安装失败！${Font}"
    exit 1
    fi
#授可执行权
chmod +x /tinyPortMapper/tinymapper
#删除无用文件
rm -rf version.txt
rm -rf tinymapper_*
}

status_tinyPortMapper(){
    if [ -f /tinyPortMapper/tinymapper ]; then
    echo -e "${Green}检测到tinyPortMapper已存在，并跳过安装步骤！${Font}"
        main_x
    else
        main_y
    fi
}

main_x(){
checkos
rootness
disable_selinux
disable_iptables
config_tinyPortMapper
start_tinyPortMapper
}

main_y(){
checkos
rootness
disable_selinux
disable_iptables
install_tinyPortMapper
config_tinyPortMapper
start_tinyPortMapper
}

status_tinyPortMapper

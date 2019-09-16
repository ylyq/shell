#/usr/bin/bash
###########
#Copright 2019
#Version  1.0
#Author xiaobai
###########
export LANG=en_US.UTF-8

##############################定义版本变量########################################
#zabbix_proxy 
Red_cent7_nam="zabbix-proxy-sqlite3-3.4.14-1.el7.x86_64.rpm"
Proxy_version="3.4"
Red_cent7_url="https://mirrors.tuna.tsinghua.edu.cn/zabbix/zabbix/$Proxy_version/rhel/7/x86_64/$Red_cent7_nam"



###########################写检查函数############################################

##检查操作系统
issue="/etc/issue.net"
check_os() {
if [ -f /etc/lsb-release -o -f /usr/bin/lsb_release -o -d /etc/lsb-release.d ];then
   OSR=$(lsb_release -si 2>/dev/null)
   OSN=$(lsb_release -r |awk '{print $2}'|cut -f 1 -d "." 2>/dev/null)
elif [ -f "$issue" ];then
       nul=$(cat "$issue"  |grep  [0-9])

        if [ -z "$nul" ];then
           if [ -f /etc/redhat-release ];then
               OSR=$(cat /etc/redhat-release  | cut -f 1 -d  " " 2>/dev/null)
               OSN=$(cat /etc/redhat-release  | awk -F '[ .]' '{print $4}' 2>/dev/null)

            elif [ -f /etc/system-release ];then
               OSR=$(cat /etc/system-release  | cut -f 1 -d  " " 2>/dev/null)
               OSN=$(cat /etc/system-release  | awk -F '[ .]' '{print $4}' 2>/dev/null)
            elif [ -f /etc/os-release ];then
               OSR=$(cat /etc/os-release | head -n 1|awk -F '"' '{print $2}' 2>/dev/null)
               OSN=$(cat /etc/os-release |egrep -i "PRETTY_NAME" | awk -F '[ "]' '{print $4}' 2>/dev/null)
            fi
        else
               OSi=$(head -n1 "$issue" | cut -f 1 -d  " " 2>/dev/null)
               OSu=$(head -n1 "$issue" |awk '{print $3}' 2>/dev/null)
         if [ $OSi = "Red" ];then
            OSR="RedHat"
            OSN=$(head -n1 "$issue" |awk -F '[ .]' '{print $7}' 2>/dev/null)

         #elif [ $OSi = "CentOS" -a $OSu = "6.5" ];then
         elif [ $OSi = "CentOS" ];then
                  OSR=$(head -n1 "$issue" | cut -f 1 -d  " " 2>/dev/null)
                  OSN=$(head -n1 "$issue" |awk -F '[ .]' '{print $3}' 2>/dev/null)
               else
      OSR=$(head -n1 "$issue" | cut -f 1 -d  " " 2>/dev/null)
                  OSN=$(head -n1 "$issue" | cut -f 3 -d  " " 2>/dev/null)
          fi
        fi
fi

}

# 判断操作系统
get_OS() {
    if [ $OSR == "CentOS" ]
    then
        echo -e  "\033[34;1mThe Operating system is $OSR $OSN ! \033[0m"
    else
        echo -e  "\033[34;1mThe Operating system is $OSR $OSN ! \033[0m"
        echo -e  "\033[34;1m目前脚本只支持centos系列 ! \033[0m"
        exit 1
    fi
}

# 检查判断zabbix-proxy是否存在
Zbx_pro_num=`ps aux |grep "zabbix_proxy" |wc -l`
check_proxy_exist() {
if [ -d /etc/zabbix ]
then
    echo -e  "\033[34;1m/etc/zabbix目录exist ! \033[0m"
    exit 2
elif [ $Zbx_pro_num -lt 1 ]
then
    echo -e  "\033[34;1mzabbix-proxy is runing ! \033[0m"
    exit 2
else
    echo -e  "\033[34;1mzabbix-proxy install begin ! \033[0m"
fi
}

# 检查判断端口是否占用
check_proxy_port() {
Proxy_port=10051
Zbx_port=`netstat -lnpt |grep $Proxy_port |wc -l`
if [ $Zbx_port -eq 1 ]
then
    echo -e  "\033[34;1mThis port:$Proxy_port used ! \033[0m"
    exit 3
fi
}



###############################################安装配置函数#######################
#zabbix_proxy安装
zabbix_proxy_install() {
if [ -f /usr/bin/wget ]
then
    wget -P /usr/local/src/ $Red_cent7_url &>/dev/null
    yum install -y  /usr/local/src/$Red_cent7_nam &>/dev/null
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1mzabbix-proxy install fail ! \033[0m"
        exit 5
    fi
    mkdir -p /data/zabbix/
    chown -R zabbix:zabbix /data
    zcat /usr/share/doc/$Red_cent7_sqlit/schema.sql.gz | sqlite3 /data/zabbix/zabbix_proxy.db
    systemctl start zabbix-proxy &>/dev/null
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1mzabbix-proxy start fail ! \033[0m"
        exit 5
    fi

    systemctl enable zabbix-proxy &>/dev/null
    echo -e  "\033[34;1mzabbix-proxy install success ! \033[0m"
else
    echo -e  "\033[34;1mwget  install ! \033[0m"
    yum install -y wget &>/dev/null
    if [ -f /usr/bin/wget ];then
        echo "" >/dev/null
    else
        echo -e  "\033[34;1m请检查网络与yum源 ! \033[0m"
        exit 4
    fi
fi
}


#zabbix_proxy.conf 配置函数
Zab_proxy_conf="/etc/zabbix/zabbix_proxy.conf"

zabbix_proxy_conf() {
echo '' > $Zab_proxy_conf
tee $Zab_proxy_conf <<EOF
ProxyMode=1
Server=139.9.164.103   #需要修改为zabbix_server的IP
ServerPort=10051       #需要修改为zabbix_server的端口
ListenPort=10051
Hostname=huapei        #需要修改为自定义的主机名，与zabixweb界面的agent代理名相同
LogFile=/var/log/zabbix/zabbix_proxy.log
LogFileSize=0
PidFile=/run/zabbix/zabbix_proxy.pid
DBName=/data/zabbix_proxy
DBUser=zabbix
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
Timeout=4
ExternalScripts=/usr/lib/zabbix/externalscripts
LogSlowQueries=3000
ProxyLocalBuffer=0
ProxyOfflineBuffer=1
HeartbeatFrequency=60
ConfigFrequency=360
StartPollers=20
StartTrappers=20
ListenIP=0.0.0.0
CacheSize=128M
HistoryCacheSize=128M
EOF
if [ $? -ne 0 ];then
        echo -e  "\033[34;1m修改配置文件zabbix_proxy.conf出错! \033[0m"
        exit 6
    else
        systemctl restart  zabbix-proxy &>/dev/null
        echo -e  "\033[34;1m大功告成! \033[0m"

fi
}


###########################################函数执行#############################
check_os
get_OS
check_proxy_exist
check_proxy_port
zabbix_proxy_install
zabbix_proxy_conf

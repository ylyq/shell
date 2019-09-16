#/usr/bin/bash
###########
#Copright 2019
#Version  1.0
#Author xiaobai
###########

export LANG=en_US.UTF-8
##############################定义版本变量########################################
#zabbix_agent name
Red_cent7_agent="zabbix-agent-3.4.14-1.el7.x86_64.rpm"
Agent_version="3.4"

#zabbix_agent name
Red_cent7_url="https://mirrors.tuna.tsinghua.edu.cn/zabbix/zabbix/$Agent_version/rhel/7/x86_64/$Red_cent7_agent"



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


# 检查判断zabbix-agent是否存在
Zbx_pro_num=`ps aux |grep "zabbix_agentd" |wc -l`
check_agent_exist() {
if [ -d /etc/zabbix ]
then
    echo -e  "\033[34;1m/etc/zabbix目录exist ! \033[0m"
    exit 2
elif [ $Zbx_pro_num -lt 1 ]
then
    echo -e  "\033[34;1mzabbix-agent is runing ! \033[0m"
    exit 2
else
    echo -e  "\033[34;1mzabbix-agent install begin ! \033[0m"
fi
}

# 检查判断端口是否占用
check_agent_port() {
Agent_port=10050
Zbx_port=`netstat -lnpt |grep $Agent_port |wc -l`
if [ $Zbx_port -eq 1 ]
then
    echo -e  "\033[34;1mThis port:$Agent_port used ! \033[0m"
    exit 3
fi
}


################################################安装配置函数########################
#zabbix_agent安装
zabbix_agent_install() {
if [ -f /usr/bin/wget ]
then
    wget -P /usr/local/src/ $Red_cent7_url &>/dev/null
    yum install -y  /usr/local/src/$Red_cent7_agent &>/dev/null
    systemctl start zabbix-agent &>/dev/null
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1mzabbix-agent start fail ! \033[0m"
        exit 5
    fi
    systemctl enable zabbix-agent &>/dev/null
    echo -e  "\033[34;1mzabbix-agent install success ! \033[0m"
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

#zabbix_agent.conf 配置函数
Zab_agent_conf="/etc/zabbix/zabbix_agentd.conf"

zabbix_agent_conf() {
echo '' > $Zab_agent_conf
tee $Zab_agent_conf <<EOF
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=10
Server=192.168.13.6   #修改成zabbix—server/zabbix-proxy的IP
ListenPort=10050
ListenIP=0.0.0.0
ServerActive=192.168.13.6   #修改成zabbix—server/zabbix-proxy的IP
AllowRoot=1
#Hostname=192.168.13.10
#HostnameItem=system.hostname
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF
if [ $? -ne 0 ];then
        echo -e  "\033[34;1m修改配置文件zabbix_agentd.conf出错! \033[0m"
        exit 6
    else
        systemctl restart  zabbix-agent &>/dev/null
        echo -e  "\033[34;1m大功告成! \033[0m"

fi
}


###########################################函数执行#############################
check_os
get_OS
check_agent_exist
check_agent_port
zabbix_agent_install
zabbix_agent_conf

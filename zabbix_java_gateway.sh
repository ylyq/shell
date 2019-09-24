#/usr/bin/bash
###########
#Copright 2019
#Version  1.0
#Author xiaobai
###########
export LANG=en_US.UTF-8

##############################定义版本变量########################################
name='zabbix_java_gateway'
port=10052
Red_cent7_nam="zabbix-java-gateway-3.4.14-1.el7.x86_64.rpm"
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

#判断$name是否运行
pro_num=`ps aux |grep "$name" |wc -l`
check_exist() {
if [ -d $home_dir ]
then
    echo -e  "\033[34;1m$home_dir目录exist ! \033[0m"
    exit 2
elif [ $pro_num -lt 1 ]
then
    echo -e  "\033[34;1m$name is runing ! \033[0m"
    exit 2
else
    echo -e  "\033[34;1m$name install begin ! \033[0m"
fi
}

#判断$name所需端口是否占用
check_port() {
Listen_port=`netstat -lnpt |grep $port |wc -l`
if [ $Listen_port -eq 1 ]
then
    echo -e  "\033[34;1mThis port:$port used ! \033[0m"
    exit 3
fi
}

###############################################安装配置函数#######################
#$name安装
soft_install(){
if [ -f /usr/bin/wget ]
then

    #下载安装
    wget -P /usr/local/src/ $Red_cent7_url &>/dev/null
    cd /usr/local/src/
    yum install -y $Red_cent7_nam
    systemctl enable zabbix-java-gateway.service
    systemctl start zabbix-java-gateway.service
     if [ $? -ne 0 ];then
        echo -e  "\033[34;1m 启动失败 ! \033[0m" 
        exit 4
    fi
     echo -e  "\033[34;1m 大功告成 ! \033[0m" 
fi
 echo -e  "\033[34;1m wget没有安装 \033[0m"
}



###########################################函数执行#############################
check_os
get_OS
check_exist
check_port
soft_install

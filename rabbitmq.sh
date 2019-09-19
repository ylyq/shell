#/usr/bin/bash
###########
#Copright 2019
#Version  1.0
#Author xiaobai
###########
export LANG=en_US.UTF-8

##############################定义版本变量########################################
#rabbitmq
name="rabbitmq" #安装软件名
port=5672    #软件占用的端口
home_dir="/usr/lib/rabbitmq"   #软件家目录
base_conf="/etc/rabbitmq/rabbitmq-env.conf"       #软件配置文件
Red_cent7_nam="rabbitmq-server-3.7.15-1.el7.noarch.rpm"  #软件包名
version_dir="rabbitmq-server-3.7.15"   #软件解压后名
Red_cent7_url="https://packagecloud.io/rabbitmq/rabbitmq-server/packages/el/7/$Red_cent7_nam/download.rpm"  #软件获取地址

#依赖变量
depend_name="erlang-22.0.7"



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
    #下载解包
    wget --content-disposition -P /usr/local/src/ $Red_cent7_url &>/dev/null
    cd /usr/local/src/
    yum install -y $Red_cent7_nam

    #配置文件函数
    soft_conf
   
    #启动，加入开机启动
    chown rabbitmq:rabbitmq /var/lib/rabbitmq/mnesia/
    systemctl enable rabbitmq-server.service
    sudo rabbitmq-plugins enable rabbitmq_management
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1m erlang与rabbitmq版本不对应! \033[0m" 
        exit 4
    fi
    chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
    systemctl start rabbitmq-server
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1m $name启动失败 ! \033[0m" 
        exit 4
    fi
    sudo rabbitmqctl add_user admin admin 
    sudo rabbitmqctl set_user_tags admin administrator 
    rabbitmqctl set_permissions -p "/" admin ".*" ".*" ".*"
    sudo rabbitmq-plugins enable rabbitmq_management
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1m weburl启动失败 ! \033[0m" 
        exit 4
    fi
fi
}

#$name 配置文件函数
soft_conf(){
    cp /usr/share/doc/$version_dir/rabbitmq.config.example $base_conf
    echo '' > $base_conf
tee $base_conf <<EOF
RABBITMQ_NODENAME=mq01
RABBITMQ_CONF_ENV_FILE=/etc/rabbitmq
RABBITMQ_CONFIG_FILE=/etc/rabbitmq
RABBITMQ_MNESIA_BASE=/var/lib/rabbitmq/mnesia/
EOF
}

#$name的依赖安装
depend_soft(){

rpm -qa |grep $depend_name-* &>/dev/null
if [ $? -ne 0 ];then
    #安装依赖包
echo -e  "\033[34;1m安装依赖 begin ! \033[0m" 
yum install -y   wget  iptables-services epel-release &>/dev/null
tee /etc/yum.repos.d/erlang.repo <<EOF
[erlang]
name=erlang
baseurl=https://mirrors.tuna.tsinghua.edu.cn/erlang-solutions/centos/7/
enabled=1
gpgcheck=0
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/erlang-solutions/linux/centos/gpg
EOF
yum install -y $depend_name &>/dev/null
rpm -qa |grep $depend_name-* &>/dev/null
if [ $? -ne 0 ];then
    echo -e  "\033[34;1m $depend_name安装失败 ! \033[0m" 
    exit 6
fi
echo -e  "\033[34;1m $depend_name安装成功 ! \033[0m" 
else
    echo -e  "\033[34;1m $depend_name已经存在，请检查是否与$name相对应 ! \033[0m" 
    exit 6
fi
}


###########################################函数执行#############################
check_os
get_OS
check_exist
check_port
depend_soft
soft_install



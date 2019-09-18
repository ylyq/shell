#/usr/bin/bash
###########
#Copright 2019
#Version  1.0
#Author xiaobai
###########
export LANG=en_US.UTF-8

##############################定义版本变量########################################
#mysql
name="mysql" #安装软件名
port=3306    #软件占用的端口
home_dir="/usr/local/mysql"   #软件家目录
base_conf="/etc/my.cnf"       #软件配置文件
Red_cent7_nam="mysql-boost-5.7.27.tar.gz"  #软件包名
version="MySQL-5.7"  #软件版本
Red_cent7_url="https://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/$version/$Red_cent7_nam"     #软件获取地址


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
pro_num=`ps aux |grep "mysql" |wc -l`
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
    #下载依赖包
    yum -y install make gcc-c++ cmake bison-devel ncurses-devel libaio libaio-devel  perl-Data-Dumper net-tools
    #下载解包
    wget -P /usr/local/src/ $Red_cent7_url &>/dev/null
    cd /usr/local/src/
    tar xvf mysql-boost-5.7.27.tar.gz &>/dev/null
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1mtar解包失败 ! \033[0m" 
        exit 4
    fi
    #编译cmake
    cd mysql-5.7.27
    mkdir $home_dir $home_dir/data $home_dir/tmp/ $home_dir/etc 
    cmake -DCMAKE_INSTALL_PREFIX=$home_dir -DMYSQL_DATADIR=$home_dir/data -DSYSCONFDIR=$home_dir/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DMYSQL_UNIX_ADDR=$home_dir/tmp/mysql.sock -DMYSQL_TCP_PORT=3306 -DENABLED_LOCAL_INFILE=ON -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DENABLED_PROFILING=ON -DWITH_DEBUG=0 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DDOWNLOAD_BOOST=1 -DWITH_BOOST=/usr/local/src/mysql-5.7.27/boost &>/dev/null
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1mcmake失败 ! \033[0m" 
        exit 4
    fi
    echo -e  "\033[34;1make && make install 开始(会占用将近30min) ! \033[0m" 
    #编译
    make && make install  &>/dev/null
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1mmake && make install编译失败 ! \033[0m" 
        exit 4
    fi
    #建用户
    useradd mysql -s /sbin/nologin
    chown -R mysql:mysql $home_dir
    #初始化系统表，并且把密码输出到/tmp/mysql.txt
    cd  $home_dir/bin/
    ./mysqld --initialize --basedir=$home_dir/ --datadir=$home_dir/data --user=mysql &> /tmp/mysql.txt
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1m初始化系统表 fail ! \033[0m" 
        exit 4
    fi
    #调用配置文件函数
    soft_conf

    #启动，加入开机启动
    cp $home_dir/support-files/mysql.server /etc/init.d/mysqld
    service mysqld start
     if [ $? -ne 0 ];then
        echo -e  "\033[34;1m service mysqld start fail ! \033[0m" 
        exit 4
    fi
    chkconfig mysqld on

    #添加path
    echo "#mysql相关" >>  /etc/profile
    echo "PATH=$PATH:/usr/local/mysql/bin/" >> /etc/profile
    source /etc/profile

    #获取密码
    password=`grep "password" /tmp/mysql.txt |awk '{print $11}'`
    echo -e  "\033[34;1m 大功告成 ! \033[0m" 
    echo "mysql的root密码是: $password"
fi
}

#$name 配置文件函数
soft_conf(){
echo '' > $base_conf
tee $base_conf <<EOF
[mysqld]
user=mysql
basedir=/usr/local/mysql/
datadir=/usr/local/mysql/data
pid-file=/usr/local/mysql/mysql.pid
socket=/usr/local/mysql/tmp/mysql.sock


[mysqld_safe]
log-error=/usr/local/mysql/logs/mysqld.log
pid-file=/usr/local/mysql/pids/mysqld.pid

# Disabling symbolic-links is recommended to prevent assorted security risks
# symbolic-links=0
# # Settings user and group are ignored when systemd is used.
# # If you need to run mysqld under a different user or group,
# # customize your systemd unit file for mariadb according to the
# # instructions in http://fedoraproject.org/wiki/Systemd
#
# [client]
# default-character-set=utf8
# socket=/usr/local/mysql/mysql.sock
#
# [mysql]
# default-character-set=utf8
# socket=/usr/local/mysql/mysql.sock
!includedir /etc/my.cnf.d
EOF
#创建配置文件所需的目录与文件
mkdir $home_dir/logs
touch $home_dir/logs/mysqld.log
touch $home_dir/mysql.pid
chown -R mysql:mysql $home_dir
}


###########################################函数执行#############################
check_os
get_OS
check_exist
check_port
soft_install

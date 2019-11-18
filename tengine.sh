#/usr/bin/bash
###########
#Copright 2019
#Version  1.0
#Author xiaobai
###########
export LANG=en_US.UTF-8

##############################定义版本变量########################################
#mysql
name="nginx" #安装软件名
port=80    #软件占用的端口
home_dir="/usr/local/nginx"   #软件家目录
base_conf="$home_dir/conf/nginx.conf"       #软件配置文件
Red_cent7_nam="tengine-2.2.1.tar.gz"  #软件包名
version_dir="tengine-2.2.1"   #软件解压后名
Red_cent7_url="http://tengine.taobao.org/download/$Red_cent7_nam"  #软件获取地址



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
    #安装依赖包
    echo -e  "\033[34;1m安装依赖 begin ! \033[0m" 
    yum -y install gcc pcre-devel openssl-devel wget &>/dev/null

    #下载解包
    wget -P /usr/local/src/ $Red_cent7_url &>/dev/null
    cd /usr/local/src/
    tar xvf $Red_cent7_nam &>/dev/null
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1mtar解包失败 ! \033[0m" 
        exit 4
    fi

    #建用户目录
    useradd -r -s /sbin/nologin -M nginx
    mkdir -p $home_dir/client $home_dir/proxy $home_dir/fastcgi $home_dir/uwsgi $home_dir/scgi 

    #编译
    cd $version_dir
    echo -e  "\033[34;1m configure begin ! \033[0m" 
    ./configure --prefix=$home_dir --user=nginx --group=nginx --with-http_ssl_module --with-http_flv_module --with-http_stub_status_module --with-http_gzip_static_module --http-client-body-temp-path=$home_dir/client --http-proxy-temp-path=$home_dir/proxy --http-fastcgi-temp-path=$home_dir/fastcgi --http-uwsgi-temp-path=$home_dir/uwsgi --http-scgi-temp-path=$home_dir/scgi --with-pcre --with-file-aio --with-http_secure_link_module &>/dev/null

    if [ $? -ne 0 ];then
        echo -e  "\033[34;1m configure失败 ! \033[0m" 
        exit 4
    fi

    #编译make
    echo -e  "\033[34;1m make begin ! \033[0m" 
    make &>/dev/null
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1m make编译失败 ! \033[0m" 
        exit 4
    fi

     #编译make install
    echo -e  "\033[34;1m make install begin! \033[0m" 
    make install  &>/dev/null
    if [ $? -ne 0 ];then
        echo -e  "\033[34;1m make install编译失败 ! \033[0m" 
        exit 4
    fi

    #加入sytemctl管理
tee /usr/lib/systemd/system/nginx.service  <<EOF
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target
[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/bin/kill -s HUP `cat /usr/local/nginx/logs/nginx.pid`
ExecStop=/bin/kill -s TERM `cat /usr/local/nginx/logs/nginx.pid`
[Install]
WantedBy=multi-user.target
EOF

    #启动，加入开机启动
    systemctl start nginx
     if [ $? -ne 0 ];then
        echo -e  "\033[34;1m $name启动失败 ! \033[0m" 
        exit 4
    fi
    systemctl enable nginx
fi
#修改配置文件重启
soft_conf
}

#$name 配置文件函数
soft_conf(){
echo '' > $base_conf
tee $base_conf <<EOF
user nginx;
worker_processes 2;
error_log /usr/local/nginx/logs/nginx_error.log crit;
pid /usr/local/nginx/logs/nginx.pid;
worker_rlimit_nofile 51200;

events
{
    use epoll;
    worker_connections 6000;
}

http
{
    include mime.types;
    default_type application/octet-stream;
    server_names_hash_bucket_size 3526;
    server_names_hash_max_size 4096;
    log_format xiaobai '\$remote_addr \$http_x_forwarded_for [\$time_local]' '\$host "\$request_uri" \$status' '"\$http_referer" "\$http_user_agent"';
    sendfile on;
    tcp_nopush on;
    keepalive_timeout 30;
    client_header_timeout 3m;
    client_body_timeout 3m;
    send_timeout 3m;
    connection_pool_size 256;
    client_header_buffer_size 1k;
    large_client_header_buffers 8 4k;
    request_pool_size 4k;
    output_buffers 4 32k;
    postpone_output 1460;
    client_max_body_size 10m;
    client_body_buffer_size 256k;
    client_body_temp_path /usr/local/nginx/client_body_temp;
    proxy_temp_path /usr/local/nginx/proxy_temp;
    tcp_nodelay on;
    charset utf-8,gbk;     #让浏览器访问中文目录不会乱码
    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 8k;
    gzip_comp_level 5;
    gzip_http_version 1.1;
    gzip_types text/plain application/javascript application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png;

    include /usr/local/nginx/conf/vhosts/*.conf;
}
EOF

#创建相关目录
mkdir $home_dir/conf/vhosts/
tee $home_dir/conf/vhosts/default.conf <<EOF
server{
        listen 80 default;
        server_name localhost;
	    access_log /usr/local/nginx/logs/default_access.log xiaobai;
        error_log /usr/local/nginx/logs/default_error.log error;

#        location /api/{
#          proxy_pass http://49.234.132.95/;
#     }
        location /{
      		root /data/webroot/release/;
      		autoindex on;
        }
}
EOF
$home_dir/sbin/nginx -t
if [ $? -ne 0 ];then
    echo -e  "\033[34;1m 配置文件出错 ! \033[0m" 
    exit 5
fi
$home_dir/sbin/nginx -s reload
}


###########################################函数执行#############################
check_os
get_OS
check_exist
check_port
soft_install

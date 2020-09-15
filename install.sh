#!/bin/sh
echo '正在安装依赖'
if cat /etc/os-release | grep "centos" > /dev/null
    then
    yum update > /dev/null
    yum install unzip wget curl -y > /dev/null
    yum update curl -y
else
    apt update > /dev/null
    apt-get install unzip wget curl -y > /dev/null
    apt-get update curl -y
fi
timedatectl set-timezone Asia/Shanghai

api=$1
key=$2
nodeId=$3
localPort=$4
license=$5
folder=$key-tj
if [[ "$6" -ne "" ]]
    then
    syncInterval=$6
else
    syncInterval=60
fi
#kill process and delete dir
kill -9 $(ps -ef | grep ${folder} | grep -v grep | grep -v bash | awk '{print $2}') 1 > /dev/null
kill -9 $(ps -ef | grep defunct | grep -v grep | awk '{print $2}') 1 > /dev/null
systemctl stop firewalld
systemctl disable firewalld
systemctl stop trojan-go.service
systemctl disable trojan-go.service
systemctl stop vvlink-tj.service
systemctl disable vvlink-tj.service
rm -f /etc/systemd/system/trojan-go.service
rm -f /etc/systemd/system/vvlink-tj.service
rm -rf $key
rm -rf $folder
rm -rf $license
echo '旧服务已移除'
sleep 3

#create dir, init files
mkdir $folder
cd $folder
#create ssl ceart
wget https://dpsky.cn/vvlink-a07wm6/vvlink.key
wget https://dpsky.cn/vvlink-a07wm6/vvlink.crt
mkdir /root/.cert
cp vvlink.crt /root/.cert/server.crt
cp vvlink.key /root/.cert/server.key
chmod 400 /root/.cert/server.*
wget https://github.com/tokumeikoi/tidalab-trojan/releases/latest/download/tidalab-trojan
wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.8.1/trojan-go-linux-amd64.zip
curl "${api}/api/v1/server/TrojanTidalab/config?token=${key}&node_id=${nodeId}&local_port=${localPort}" > ./config.json

if cat config.json | grep "run_type" > /dev/null
    then
    echo '配置获取成功'
else
    echo '配置获取失败'
    exit
fi

unzip trojan-go-linux-amd64.zip
chmod 755 *

if ls /root/.cert | grep "key" > /dev/null
    then
    echo '证书存在'
else
    echo '请签发证书后在执行'
    exit
fi

#run server
nohup `pwd`/tidalab-trojan -api=$api -token=$key -node=$nodeId -localport=$localPort -license=$license -syncInterval=$syncInterval > tidalab.log 2>&1 &
echo '启动成功'
sleep 3
cat tidalab.log
if ls | grep "service.log"
	then
	cat service.log
else
	echo '启动失败'
fi

#create auto start
cat << EOF >> /etc/systemd/system/vvlink-tj.service
[Unit]
Description=vvLink-tj Service
After=network.target network-online.target nss-lookup.target mysql.service mariadb.service mysqld.service
Wants=network-online.target

[Service]
Type=simple
StandardError=journal
User=nobody
AmbientCapabilities=CAP_NET_BIND_SERVICE
PIDFile=/run/vvlink-tj.pid
ExecStart=`pwd`/tidalab-trojan -api=$api -token=$key -node=$nodeId -localport=$localPort -license=$license -syncInterval=$syncInterval > tidalab.log 2>&1 &
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable vvlink-tj
systemctl daemon-reload
echo '部署完成'
sleep 3
systemctl status vvlink-tj

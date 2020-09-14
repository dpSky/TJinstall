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

api=$1
key=$2
nodeId=$3
localPort=$4
license=$5
folder=$key-trojan
if [[ "$6" -ne "" ]]
    then
    syncInterval=$6
else
    syncInterval=60
fi

#kill old process and delete dir
systemctl stop firewalld
systemctl disable firewalld
systemctl stop trojan-go.service
systemctl stop vvlink.service
systemctl stop vvlink-tj.service
kill -9 $(ps -ef | grep ${folder} | grep -v grep | grep -v bash | awk '{print $2}') 1 > /dev/null
kill -9 $(ps -ef | grep defunct | grep -v grep | awk '{print $2}') 1 > /dev/null
echo '结束进程'
rm -rf $folder
echo '结束进程'
sleep 3
rm -rf /etc/systemd/system/trojan-go.service
rm -rf /etc/systemd/system/vvlink.service
rm -rf /etc/systemd/system/vvlink-tj.service
rm -rf $key-trojan
rm -rf $license

#create dir, init files
mkdir $license
cd $license
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

wget https://dpsky.cn/vvlink-a07wm6/vvlink.key
wget https://dpsky.cn/vvlink-a07wm6/vvlink.crt
mkdir /root/.cert
cp vvlink.crt /root/.cert/server.crt
cp vvlink.key /root/.cert/server.key
chmod 400 /root/.cert/server.*

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
cat tidalab.log
if ls | grep "service.log"
	then
	cat service.log
else
	echo '启动失败'
fi

cat << EOF >> /etc/systemd/system/vvlink-tj.service
[Unit]
Description=vvLink-tj Service
After=network.target
Wants=network.target

[Service]
Type=simple
PIDFile=/run/vvlink-tj.pid
ExecStart=/root/$license/tidalab-trojan -api=$api -token=$key -node=$nodeId -localport=$localPort -license=$license -syncInterval=$syncInterval
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable vvlink-tj
systemctl start vvlink-tj
echo '部署完成'
sleep 3
systemctl status vvlink-tj

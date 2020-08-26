#!/bin/sh
echo '正在安装依赖'
if cat /etc/os-release | grep "centos" > /dev/null
    then
    yum update
    yum install unzip wget curl -y > /dev/null
else
    apt-get update
    apt-get install unzip wget curl -y > /dev/null
fi

api=$1
key=$2
nodeId=$3
localPort=$4
license=$5

systemctl stop firewalld
systemctl disable firewalld
systemctl stop v2ray.service
systemctl stop vvlink.service
systemctl stop vvlink-v2.service
echo '结束进程'
sleep 3
rm -f /etc/systemd/system/v2ray.service
rm -f /etc/systemd/system/vvlink.service
rm -f /etc/systemd/system/vvlink-v2.service
rm -rf $key
mkdir $key
cd $key
wget https://github.com/tokumeikoi/aurora/releases/latest/download/aurora
wget https://github.com/v2ray/v2ray-core/releases/latest/download/v2ray-linux-64.zip
wget https://dpsky.cn/vvlink-a07wm6/vvlink.key
wget https://dpsky.cn/vvlink-a07wm6/vvlink.crt
mkdir /root/.cert
cp vvlink.crt /root/.cert/server.crt
cp vvlink.key /root/.cert/server.key
chmod 400 /root/.cert/server.*

unzip v2ray-linux-64.zip
chmod 755 *
cat << EOF >> /etc/systemd/system/vvlink-v2.service
[Unit]
Description=vvLink-v2 Service
After=network.target
Wants=network.target

[Service]
Type=simple
PIDFile=/run/vvlink-v2.pid
ExecStart=/root/$key/aurora -api=$api -token=$key -node=$nodeId -localport=$localPort -license=$license
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable vvlink-v2
systemctl start vvlink-v2
echo '部署完成'
sleep 3
systemctl status vvlink-v2

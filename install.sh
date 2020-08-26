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
systemctl stop trojan-go.service
systemctl stop vvlink.service
systemctl stop vvlink-tj.service
echo '结束进程'
sleep 3
rm -f /etc/systemd/system/trojan-go.service
rm -f /etc/systemd/system/vvlink.service
rm -f /etc/systemd/system/vvlink-tj.service
rm -rf $key
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

if ls /root/.cert | grep "key" > /dev/null
    then
    echo '证书存在'
else
    echo '请签发证书后在执行'
    exit
fi

unzip trojan-go-linux-amd64.zip
chmod 755 *
cat << EOF >> /etc/systemd/system/vvlink-tj.service
[Unit]
Description=vvLink-tj Service
After=network.target
Wants=network.target

[Service]
Type=simple
PIDFile=/run/vvlink-tj.pid
ExecStart=/root/$license/tidalab-trojan -api=$api -token=$key -node=$nodeId -localport=$localPort -license=$license
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

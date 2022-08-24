#!/bin/bash
echo "### INSTALL UTILITIES ###"
sudo yum update -y
sudo yum install -y wget which git vim

echo "### INSTALL CORRETTO JAVA 11 ###"
if ! which java | grep -q 'java'
then
    echo "> Installing Java ..."
    sudo rpm --import https://yum.corretto.aws/corretto.key
    sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
    yum install -y java-11-amazon-corretto-devel
fi
echo ">> $(which java)"

echo "### SET JAVA_HOME ENVIRONMENT ###"
if [ -z "$JAVA_HOME" ]
then
    echo "> Setting JAVA_HOME ..."
    javalocation=$(readlink -f $(which java))
    sudo echo "export JAVA_HOME=${javalocation/\/bin\/java/}" >> /etc/profile
    sudo source /etc/profile
fi
echo ">> JAVA_HOME=$JAVA_HOME"

echo "### ADD GROUP NAMED ZOOKEEPER ###"
if ! grep -q '^zookeeper:' /etc/group
then
    echo "> Adding group zookeeper ..."
    sudo groupadd zookeeper
fi
echo ">> $(grep zookeeper /etc/group)"

echo "### ADD USER NAMED ZOOKEEPER ###"
if ! grep -q '^zookeeper:' /etc/passwd
then
    echo "> Adding user zookeeper ..."
    sudo useradd -g zookeeper zookeeper
fi
echo ">> $(grep zookeeper /etc/passwd)"

sudo mkdir -p /var/lib/zookeeper/data
sudo mkdir -p /var/lib/zookeeper/logs

echo "### INSTALL ZOOKEEPER ###"
if [ ! -e /usr/local/zookeeper ]
then
    echo ">> Installing zookeeper ..."
    sudo wget -P /opt https://archive.apache.org/dist/zookeeper/zookeeper-3.7.1/apache-zookeeper-3.7.1-bin.tar.gz
    sudo chmod 600 /opt/apache-zookeeper-3.7.1-bin.tar.gz
    sudo tar -zxvf /opt/apache-zookeeper-3.7.1-bin.tar.gz -C /usr/local
    sudo chown -R zookeeper:zookeeper /usr/local/apache-zookeeper-3.7.1-bin
    sudo ln -s /usr/local/apache-zookeeper-3.7.1-bin /usr/local/zookeeper
    sudo chown -R zookeeper:zookeeper /usr/local/zookeeper
fi

if [ ! -e /usr/local/zookeeper/conf/zoo.cfg ]
then
echo '>> Setting zookeeper server configuation ...'
sudo echo "tickTime=2000
initLimit=10
syncLimit=5
dataDir=/var/lib/zookeeper/data
clientPort=2181
autopurge.snapRetainCount=3
autopurge.purgeInterval=1
server.${ZK_ID}=${ZK_HOST}:2888:3888" > /usr/local/zookeeper/conf/zoo.cfg
fi 

sudo chown zookeeper:zookeeper /usr/local/zookeeper/conf/zoo.cfg
sudo chmod 644 /usr/local/zookeeper/conf/zoo.cfg

echo "### SET ZOOKEEPER myid ###"
if [ ! -e /var/lib/zookeeper/data/myid ]
then
    echo "> Creating zookeeper myid ..."
    sudo touch /var/lib/zookeeper/data/myid
    sudo echo "${ZK_ID}" > /var/lib/zookeeper/data/myid
fi

sudo chown -R zookeeper:zookeeper /var/lib/zookeeper
sudo chmod -R 755 /var/lib/zookeeper

echo "### REGISTER ZOOKEEPER FOR SYSTEMD ###"
if [ ! -e /etc/systemd/system/zookeeper-server.service ]
then
sudo touch /etc/systemd/system/zookeeper-server.service
sudo echo "[Unit]
Description=zookeeper-server
After=network.target

[Service]
Type=forking
User=zookeeper
Group=zookeeper
SyslogIdentifier=zookeeper-server
WorkingDirectory=/usr/local/zookeeper
Restart=always
RestartSec=0s
ExecStart=/usr/local/zookeeper/bin/zkServer.sh start
ExecStop=/usr/local/zookeeper/bin/zkServer.sh stop
ExecReload=/usr/local/zookeeper/bin/zkServer.sh restart

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/zookeeper-server.service
fi

sudo chmod 755 /etc/systemd/system/zookeeper-server.service

echo "### RELOAD ZOOKEEPER SYSTEMD ###"
sudo systemctl daemon-reload
sudo systemctl start zookeeper-server

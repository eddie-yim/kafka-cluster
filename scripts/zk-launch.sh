#!/bin/bash
echo -e "\n### INSTALL UTILITIES ###"
sudo yum update -y
sudo yum install -y wget which git vim

echo -e "\n### INSTALL CORRETTO JAVA 11 ###"
if ! which java | grep -q 'java'
then
    echo "> Installing Java ..."
    sudo rpm --import https://yum.corretto.aws/corretto.key
    sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
    sudo yum install -y java-11-amazon-corretto-devel
fi
echo ">> $(which java)"

echo -e "\n### SET JAVA_HOME ENVIRONMENT ###"
if [ -z "$JAVA_HOME" ]
then
    echo "> Setting JAVA_HOME ..."
    javalocation=$(readlink -f $(which java))
    sudo echo "export JAVA_HOME=${javalocation/\/bin\/java/}" >> /etc/profile
    sudo source /etc/profile
fi
echo ">> JAVA_HOME=$JAVA_HOME"

echo -e "\n### ADD GROUP NAMED ZOOKEEPER ###"
if ! grep -q '^zookeeper:' /etc/group
then
    echo "> Adding group zookeeper ..."
    sudo groupadd zookeeper
fi
echo ">> $(grep zookeeper /etc/group)"

echo -e "\n### ADD USER NAMED ZOOKEEPER ###"
if ! grep -q '^zookeeper:' /etc/passwd
then
    echo "> Adding user zookeeper ..."
    sudo useradd -g zookeeper zookeeper
fi
echo ">> $(grep zookeeper /etc/passwd)"

sudo mkdir -p /var/lib/zookeeper/data
sudo mkdir -p /var/lib/zookeeper/logs

echo -e "\n### INSTALL ZOOKEEPER ###"
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
autopurge.purgeInterval=1" > /usr/local/zookeeper/conf/zoo.cfg
fi 
SPLITTED_ZK_HOSTS=(`echo "$ZK_HOSTS" | tr ',' ' '`)
index=0
for zk_host in "${SPLITTED_ZK_HOSTS[@]}"
do
    index=$(expr $index + 1)
    sudo echo "server.$index=$zk_host:2888:3888" >> /usr/local/zookeeper/conf/zoo.cfg
done

sudo chown zookeeper:zookeeper /usr/local/zookeeper/conf/zoo.cfg
sudo chmod 644 /usr/local/zookeeper/conf/zoo.cfg

echo -e "\n### SET ZOOKEEPER myid ###"
if [ ! -e /var/lib/zookeeper/data/myid ]
then
    echo "> Creating zookeeper myid ..."
    sudo touch /var/lib/zookeeper/data/myid
    sudo echo "${ZK_MYID}" > /var/lib/zookeeper/data/myid
fi

sudo chown -R zookeeper:zookeeper /var/lib/zookeeper
sudo chmod -R 755 /var/lib/zookeeper

echo -e "\n### SASL/SCRAM ###"
if [ ! -e /usr/local/zookeeper/conf/zookeeper_server_jaas.conf ]
then
    sudo touch /usr/local/zookeeper/conf/zookeeper_server_jaas.conf
fi
echo -e "Server {
  org.apache.zookeeper.server.auth.DigestLoginModule required
  user_admin=\"${DLM_ADMIN_PASSWORD}\";
};
QuorumServer {
  org.apache.zookeeper.server.auth.DigestLoginModule required
  user_zookeeper=\"${DLM_ZOOKEEPER_PASSWORD}\";
};
QuorumLearner {
  org.apache.zookeeper.server.auth.DigestLoginModule required
  username=\"zookeeper\"
  password=\"${DLM_ZOOKEEPER_PASSWORD}\";
};" > /usr/local/zookeeper/conf/zookeeper_server_jaas.conf
sudo chown zookeeper:zookeeper /usr/local/zookeeper/conf/zookeeper_server_jaas.conf

if [ ! -e /usr/local/zookeeper/conf/zookeeper-env.sh ]
then
    sudo touch /usr/local/zookeeper/conf/zookeeper-env.sh
fi
sudo echo -e "JVMFLAGS=\"-Djava.security.auth.login.config=/usr/local/zookeeper/conf/zookeeper_server_jaas.conf \
-Dquorum.auth.enableSasl=true \
-Dquorum.auth.learnerRequireSasl=true \
-Dquorum.auth.serverRequireSasl=true \
-Dzookeeper.authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider \
-Dzookeeper.authProvider.2=org.apache.zookeeper.server.auth.DigestAuthenticationProvider \
-DjaasLoginRenew=3600000 \
-DrequireClientAuthScheme=sasl \
-Dquorum.auth.learner.loginContext=QuorumLearner \
-Dquorum.auth.server.loginContext=QuorumServer\"

ZK_SERVER_HEAP=\"512\"" > /usr/local/zookeeper/conf/zookeeper-env.sh

echo -e "\n### REGISTER ZOOKEEPER FOR SYSTEMD ###"
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

echo -e "\n### RELOAD ZOOKEEPER SYSTEMD ###"
sudo systemctl daemon-reload
sudo systemctl start zookeeper-server

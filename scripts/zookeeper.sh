#!/bin/bash
# install utilities
sudo yum update -y
sudo yum install -y wget which git vim

# install java 11
if ! which java | grep -q '/bin/java'; then
    sudo rpm --import https://yum.corretto.aws/corretto.key
    sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
    sudo yum install -y java-11-amazon-corretto-devel
fi

if [ -z "$JAVA_HOME" ]; then
    javalocation=$(readlink -f $(which java))
    sudo echo "export JAVA_HOME=${javalocation/\/bin\/java/}" >> /etc/profile
    sudo -s source /etc/profile
fi

if [ -z "$JAVA_HOME" ]; then
    echo "Failed to set JAVA_HOME environment variable."
    exit 1
fi

# user named zookeeper
if ! grep -q '^zookeeper:' /etc/group; then
    sudo groupadd zookeeper
fi

if ! grep -q '^zookeeper:' /etc/passwd; then
    sudo useradd -g zookeeper zookeeper
fi

# install zookeeper
if [ ! -e /usr/local/zookeeper/zkServer.sh ]; then
    sudo wget -P /opt https://archive.apache.org/dist/zookeeper/zookeeper-3.7.1/apache-zookeeper-3.7.1-bin.tar.gz
    sudo chmod 600 /opt/apache-zookeeper-3.7.1-bin.tar.gz
    sudo tar -zxvf /opt/apache-zookeeper-3.7.1-bin.tar.gz -C /usr/local
    sudo chown -R zookeeper:zookeeper /usr/local/apache-zookeeper-3.7.1-bin
    sudo ln -s /usr/local/apache-zookeeper-3.7.1-bin /usr/local/zookeeper
    sudo chown -R zookeeper:zookeeper /usr/local/zookeeper
fi

if [ ! -e /usr/local/zookeeper/conf/zoo.cfg ]; then
sudo echo "tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data/zookeeper
clientPort=2181
autopurge.snapRetainCount=3
autopurge.purgeInterval=1" > /usr/local/zookeeper/conf/zoo.cfg
fi

splitted_zk_hosts=(`echo "$ZK_HOSTS" | tr ',' ' '`)
index=0
for zk_host in "${splitted_zk_hosts[@]}"
do
    index=$(expr $index + 1)
    sudo echo "server.$index=$zk_host:2888:3888" >> /usr/local/zookeeper/conf/zoo.cfg
done

sudo chown zookeeper:zookeeper /usr/local/zookeeper/conf/zoo.cfg

sudo chmod 644 /usr/local/zookeeper/conf/zoo.cfg

if [ ! -e /data/zookeeper ]; then
    sudo mkdir -p /data/zookeeper
fi

if [ ! -e /data/zookeeper/myid ]; then
    sudo echo "${ZK_MYID}" > /data/zookeeper/myid
fi

sudo chown -R zookeeper:zookeeper /data/zookeeper

sudo chmod -R 755 /data/zookeeper

# sasl/scram
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

# register zookeeper for systemd
if [ ! -e /etc/systemd/system/zookeeper-server.service ]; then
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

sudo systemctl daemon-reload

sudo systemctl start zookeeper-server

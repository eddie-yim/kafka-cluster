#!/bin/bash
# install utilities
sudo yum update -y
sudo yum install -y wget which git vim

# install java 11
if ! which java | grep -q 'java'; then
    sudo rpm --import https://yum.corretto.aws/corretto.key
    sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
    sudo yum install -y java-11-amazon-corretto-devel
fi

if [ -z "$JAVA_HOME" ]; then
    javalocation=$(readlink -f $(which java))
    sudo echo "export JAVA_HOME=${javalocation/\/bin\/java/}" >> /etc/profile
    source /etc/profile
fi

if [ -z "$JAVA_HOME" ]; then
    echo "Failed to set JAVA_HOME environment variable."
    exit 1
fi

# install kafka
if [ ! -e /usr/local/kafka_2.13-3.2.1/bin ]; then
    sudo wget -P /opt https://archive.apache.org/dist/kafka/3.2.1/kafka_2.13-3.2.1.tgz
    sudo chmod 600 /opt/kafka_2.13-3.2.1.tgz
    sudo tar zxvf /opt/kafka_2.13-3.2.1.tgz -C /usr/local
    sudo ln -s /usr/local/kafka_2.13-3.2.1 /usr/local/kafka
fi

if [ ! -e /data/kafka ]; then
    sudo mkdir -p /data/kafka
fi

sudo echo -e "broker.id=${BROKER_ID}
advertised.listeners=SASL_PLAINTEXT://localhost:9092
allow.everyone.if.no.acl.found=true
authorizer.class.name=kafka.security.authorizer.AclAuthorizer
auto.create.topics.enable=true
confluent.support.customer.id=anonymous
confluent.support.metrics.enable=true
group.initial.rebalance.delay.ms=0
listeners=SASL_PLAINTEXT://0.0.0.0:9092
log.dirs=/data/kafka
log.retention.hours=168
log.retention.check.interval.ms=300000
log.segment.bytes=1073741824
min.insync.replicas=1
num.io.threads=8
num.network.threads=3
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.retention.minutes=172800
offsets.topic.replication.factor=1
sasl.enabled.mechanisms=SCRAM-SHA-512
sasl.mechanism.inter.broker.protocol=SCRAM-SHA-512
security.inter.broker.protocol=SASL_PLAINTEXT
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
super.users=User:broker;User:client;
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
zookeeper.connect=${ZOOKEEPER_CONNECT}
zookeeper.connection.timeout.ms=6000
zookeeper.set.acl=true" > /usr/local/kafka/config/server.properties

sudo chmod 644 /usr/local/kafka/config/server.properties

sudo echo "JMX_PORT=9999" > /usr/local/kafka/config/jmx

sudo chmod 644 /usr/local/kafka/config/jmx

# broker sasl/scram config
sudo echo -e "KafkaServer {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username=\"broker\"
    password=\"${SCRAM_BROKER_PASSWORD}\"
    user_client=\"${SCRAM_CLIENT_PASSWORD}\";
};
Client {
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username=\"admin\"
    password=\"${SCRAM_ADMIN_PASSWORD}\";
};
KafkaClient {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username=\"client\"
    password=\"${SCRAM_CLIENT_PASSWORD}\";
};" > /usr/local/kafka/config/kafka_server_jaas.conf

# kafka options
if [ -z "$KAFKA_OPTS" ]; then
sudo echo "export KAFKA_OPTS=\"-Dzookeeper.sasl.client=true \
-Dzookeeper.sasl.clientconfig=Client \
-Djava.security.auth.login.config=/usr/local/kafka/config/kafka_server_jaas.conf\"" >> /etc/profile
sudo -s source /etc/profile
fi

# register kafka service in systemd
sudo echo "[Unit]
Description=kafka-server
After=network.target

[Service]
Type=simple
SyslogIdentifier=kafka-server
WorkingDirectory=/usr/local/kafka
EnvironmentFile=/usr/local/kafka/config/jmx
Restart=always
ExecStart=/usr/local/kafka/bin/kafka-server-start.sh /usr/local/kafka/config/server.properties
ExecStop=/usr/local/kafka/bin/kafka-server-stop.sh

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/kafka-server.service

sudo chmod 644 /etc/systemd/system/kafka-server.service

# reload kafka systemd
#systemctl daemon-reload

#sudo systemctl start kafka-server

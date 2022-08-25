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

if [ -z "JAVA_HOME" ]; then
    echo "Faile to set JAVA_HOME environment variable."
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

echo "broker.id=${BROKER_ID}
advertised.listeners=SASL_PLAINTEXT://localhost:9092
allow.everyone.if.no.acl.found=true
authorizer.class.name=kafka.security.auth.SimpleAclAuthorizer
auto.create.topics.enable=true
listeners=SASL_PLAINTEXT://0.0.0.0:9092
log.dirs=/data/kafka
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
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
zookeeper.connect=localhost:2181
zookeeper.connection.timeout.ms=6000
confluent.support.metrics.enable=true
confluent.support.customer.id=anonymous
group.initial.rebalance.delay.ms=0
zookeeper.connect=localhost:2181
zookeeper.set.acl=true" > /usr/local/kafka/config/server.properties

sudo chmod 644 /usr/local/kafka/config/server.properties

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

sudo chmod 755 /etc/systemd/system/kafka-server.service

# reload kafka systemd
#systemctl daemon-reload

#sudo systemctl start kafka-server

#!/bin/bash
echo -e "\n### INSTALL KAFKA ###"
if [ ! -e /usr/local/kafka_2.13-3.2.1/bin ]
then
    echo ">> Installing kafka ..."
    sudo wget -P /opt https://archive.apache.org/dist/kafka/3.2.1/kafka_2.13-3.2.1.tgz
    sudo chmod 600 /opt/kafka_2.13-3.2.1.tgz
    sudo tar zxvf /opt/kafka_2.13-3.2.1.tgz -C /usr/local
    sudo ln -s /usr/local/kafka_2.13-3.2.1 /usr/local/kafka
fi

echo -e "\n### SET KAFKA CONFIG INTO server.properties ###"
if [ ! -e /var/lib/kafka/data ]
then
    sudo mkdir -p /var/lib/kafka/data
fi

echo -e "\n### REGISTER KAFKA ENITY USERS ###"
/usr/local/kafka/bin/kafka-configs --zookeeper localhost:2181 --alter --add-config "SCRAM-SHA-512=[password=${SCRAM_CLIENT_PASSWORD}]" --entity-type users --entity-name client
/usr/local/kafka/bin/kafka-configs --zookeeper localhost:2181 --alter --add-config "SCRAM-SHA-512=[password=${SCRAM_BROKER_PASSWORD}]" --entity-type users --entity-name broker

echo -e "\n### RELOAD ZOOKEEPER SYSTEMD ###"
sudo systemctl daemon-reload

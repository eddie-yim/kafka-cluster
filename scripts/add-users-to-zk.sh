#!/bin/bash
# install kafka
if [ ! -e /usr/local/kafka_2.13-3.2.1/bin ]; then
    sudo wget -P /opt https://archive.apache.org/dist/kafka/3.2.1/kafka_2.13-3.2.1.tgz
    sudo chmod 600 /opt/kafka_2.13-3.2.1.tgz
    sudo tar zxvf /opt/kafka_2.13-3.2.1.tgz -C /usr/local
    sudo ln -s /usr/local/kafka_2.13-3.2.1 /usr/local/kafka
fi

# register kafka entry users
sh /usr/local/kafka/bin/kafka-configs.sh --zookeeper localhost:2181 --alter --add-config "SCRAM-SHA-512=[password=${SCRAM_CLIENT_PASSWORD}]" --entity-type users --entity-name client
sh /usr/local/kafka/bin/kafka-configs.sh --zookeeper localhost:2181 --alter --add-config "SCRAM-SHA-512=[password=${SCRAM_BROKER_PASSWORD}]" --entity-type users --entity-name broker

# reaload zookeeper daemon
sudo systemctl daemon-reload

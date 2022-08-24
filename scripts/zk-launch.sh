#!/bin/bash
echo '>> Install Utils' && \
sudo yum update -y && \
sudo yum install -y wget which git vim && \

echo '>> Install corretto Java 17' && \
sudo yum install -y https://corretto.aws/downloads/latest/amazon-corretto-17-aarch64-linux-jdk.rpm && \
javainstalled=$(readlink -f $(which java)) && \
sudo echo "export JAVA_HOME=${javainstalled/\/bin\/java/}" >> /etc/profile && \
sudo source /etc/profile && \
echo '>> Create group and user named zookeeper' && \
sudo groupadd zookeeper && \
sudo useradd -g zookeeper zookeeper && \
sudo mkdir -p /var/lib/zookeeper/data && \
mkdir -p /var/lib/zookeeper/logs ;

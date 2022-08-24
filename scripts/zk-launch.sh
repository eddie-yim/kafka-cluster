#!/bin/bash
echo '>> Install Utils' && \
sudo yum update -y && \
sudo yum install -y wget which git vim && \

echo '>> Install corretto Java 17' && \
sudo yum install -y https://corretto.aws/downloads/latest/amazon-corretto-17-aarch64-linux-jdk.rpm && \
javainstalled=$(readlink -f $(which java)) && \
echo "export JAVA_HOME=${javainstalled/\/bin\/java/}" >> /etc/profile && \
source /etc/profile;

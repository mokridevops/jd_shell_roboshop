#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR="$PWD"

sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER


TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

trap 'echo "error at $LINENO", command: $BASH_COMMAND" ' ERR

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR]....$R Please run this script with root access $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE()
{
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] .... $2 ....$R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] ....$2 .....$G SUCCESS $N" | tee -a $LOGS_FILE
    fi 
}


dnf module disable nodejs -y &>> $LOGS_FILE
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
VALIDATE $? "enabling nodejs 20"

dnf install nodejs -y &>> $LOGS_FILE
VALIDATE $? "installing nodejs"

id roboshop
if [ $? -ne 0]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
VALIDATE $? "creating roboshop system user"
else
echo "system user already created ... $Y SKINNING $N"
fi

rm -rf /app &>> $LOGS_FILE
VALIDATE $? "removing existing directory"

mkdir -p /app &>> $LOGS_FILE
VALIDATE $? "creating app directory"

rm -rf /tmp/catalogue.zip &>> $LOGS_FILE
VALIDATE $? "removing catalogue.zip"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGS_FILE
cd /app &>> $LOGS_FILE
unzip /tmp/catalogue.zip &>> $LOGS_FILE
VALIDATE $? "Downloaded and extracted catalogue code"



npm install  &>> $LOGS_FILE
VALIDATE $? "installed dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>> $LOGS_FILE
VALIDATE $? "created systemctl service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGS_FILE
VALIDATE $? "added mongo repo"

dnf install mongodb-mongosh -y &>> $LOGS_FILE
VALIDATE $? "installed mongodb client"

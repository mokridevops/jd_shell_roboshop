#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"

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
        echo -e "TIMESTAMP [ERROR] .... $2 ....$R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "TIMESTAMP [INFO] ....$2 .....$G SUCCESS $N" | tee -a $LOGS_FILE
    fi 
}


cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying Mongo Repo"

dnf install mongodb-org -y &>> $LOGS_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable -now mongod
VALIDATE $? "enabling and starting mongod"

sed 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod
VALIDATE $? "restarting mongodb"



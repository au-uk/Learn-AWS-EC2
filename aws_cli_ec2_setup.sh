#!/bin/bash
#
# Created 23FEB2022
# Last Tested 04MARCH2022
#
# Varables Collected and Used
#
# vpc = AWS VPC ID
# igw = AWS Internet Gateday ID
# rtb = AWS Routing Table ID
# subnet = AWS Public Subnet
# sg = AWS Security Group
#
echo "[1of13]Creating AWS EC2 VPC"
#
vpc=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
#
sleep 10
#
echo "Created" $vpc
#
echo "[2of13]Creating 2 AWS EC2 Subnets in our VPC"
#
aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.0.1.0/24
subnet=$(aws ec2 describe-subnets --query "Subnets[*].{ID:SubnetId}" --output text)
#
sleep 10
#
aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.0.0.0/24
#
sleep 10
#
echo "Created" $subnet
#
echo "[3of13]Creating an AWS EC2 Internet Gateway"
#
igw=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
#
sleep 10
#
echo "Created" $igw
#
echo "[4of13]Attaching the Internet Gateway to our VPC"
#
aws ec2 attach-internet-gateway --vpc-id $vpc --internet-gateway-id $igw
#
sleep 10
#
echo "[5of13]Creating AWS EC2 Routing Table"
#
rtb=$(aws ec2 create-route-table --vpc-id $vpc --query RouteTable.RouteTableId --output text)
#
sleep 10
#
echo "[6of13]Adding the routing entry to internet gateway."
#
aws ec2 create-route --route-table-id $rtb --destination-cidr-block 0.0.0.0/0 --gateway-id $igw
#
sleep 10
#
echo "[7of13]Associating Route Table with our Public Subnet"
#
aws ec2 associate-route-table  --subnet-id $subnet --route-table-id $rtb
#
sleep 10
#
echo "[8of13]Adding Public IP to all new EC2 instances"
#
aws ec2 modify-subnet-attribute --subnet-id $subnet --map-public-ip-on-launch
#
sleep 10
#
echo "[9of13]creating AWS EC2 Security Group"
#
sg=$(aws ec2 create-security-group --group-name External_Access --description "External Access" --vpc-id $vpc --output text)
#
sleep 10
#
echo "[10of13]Allow Port 22"
#
aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 22 --cidr 0.0.0.0/0
#
sleep 10
#
echo "[11of13]Allow Port 9090"
#
aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 9090 --cidr 0.0.0.0/0
#
sleep 10
#
echo "[12of13]Allow Port 8080"
#
aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 8080 --cidr 0.0.0.0/0
#
sleep 10
#
echo "[13of13]Allow Port 80"
#
aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 80 --cidr 0.0.0.0/0
#
sleep 10
#
echo "AWS_EC2_Setup.sh Complete. Please check Instance_Creation_Template.sh"
#
echo "# $vpc" > Instance_Creation_Template.sh
echo "# $igw" >> Instance_Creation_Template.sh
echo "# $rtb" >> Instance_Creation_Template.sh
echo "# $subnet" >> Instance_Creation_Template.sh
echo "# $sg" >> Instance_Creation_Template.sh
#

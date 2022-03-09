# Name: Using the AWS CLI to setup EC2.
Date Written: 23 FEB 2022
Date Last Tested: 04 MARCH 2022

## TLDR:

The following is a list of tasks to create the AWS EC2 services required to be able to launch instances with Public IP's using the AWS CLI.

Note: This list is taken directly from AWS's Getting Started Architecture Blueprint.

The output of this list is a BASH script to configure your EC2 instance.

The high level steps are as follows:

- Install the AWS CLI and configure Access and Authentication (manual).    
- Configure AWS EC2 Networking (scripted).

Note: The script outputs an instance creation template.

# Install the AWS CLI and configure Access and Authentication.

## Install AWS CLI

Notes: The AWS CLI is an Amazon Web Services (AWS) tool created and maintained by Amazon and available for Linux, Mac and Windows OS's. More details and current platform installation instructions can be found here https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html .

**Command**
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Example Output**
```
aws --version
aws-cli/2.4.19 Python/3.8.8 Linux/5.16.8-200.fc35.x86_64 exe/x86_64.fedora.35 prompt/off
```


### Configure AWS CLI (Credentials)

Notes: I add a region, even though the default is [none] or I see the following error [ Could not connect to the endpoint URL: "https://ec2.none.amazonaws.com/" ].

**Command**
```
aws configure
```
**Example Output**
```
aws configure

AWS Access Key ID [*******************]: CHANGEME
AWS Secret Access Key [*******************]: CHANGEME
Default region name [none]: ap-southeast-2
Default output format [None]: json

```
## Create and configure a key-pair

Notes: Create the RSA key with the AWS cli and save the private key in the local directory. Once saved change the file permissions to make it usable with SSH.

**Command**
```
aws ec2 create-key-pair --key-name 'AWS-EC2-KEY' --query 'KeyMaterial' --output text > AWS-EC2-KEY.pem
```
**Example Output**
```
ls -al
total 44760
-rw-r--r--. 1 blah blah     1679 Feb 22 09:28 AWS-EC2-KEY.pem
```

### Modify key-pair file permissions

**Command**
```
chmod 400 AWS-EC2-KEY.pem
```

### Check key-pair (optional)

**Command**
```
aws ec2 describe-key-pairs
```
**Example Output**
```
{
    "KeyPairs": [
        {
            "KeyPairId": "key-0e00d0000000bb000",
            "KeyFingerprint": "b0:00:0c:ed:0e:0a:00:00:00:00:c0:00:df:00:0f:00:00:0e:e0:0c",
            "KeyName": "AWS-EC2-KEY",
            "KeyType": "rsa",
            "Tags": []
        }
    ]
}
```

# Configure AWS EC2 Networking

## Create a VPC

Note: The first step is to create a VPC with a 10.0.0.0/16 CIDR block using the following create-vpc command.

**Command**
```
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text
```
**Example Output**
```
vpc-2f09a348
```

## Create two subnets using the AWS CLI

Note: Using the VPC ID from the previous step, create a subnet with a 10.0.1.0/24 CIDR block using the following create-subnet command.

**Command**
```
aws ec2 create-subnet --vpc-id vpc-CHANGEME --cidr-block 10.0.1.0/24
aws ec2 create-subnet --vpc-id vpc-CHANGEME --cidr-block 10.0.0.0/24
```

## Create an internet gateway using the following create-internet-gateway command.

**Command**
```
aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text
```
**Example Output**
```
igw-1ff7a07b
```

### Attach the internet gateway to your VPC using the following attach-internet-gateway command.

**command**
```
aws ec2 attach-internet-gateway --vpc-id vpc-CHANGEME --internet-gateway-id igw-CHANGEME
```

### Create a custom route table for your VPC using the following create-route-table command.

**Command**
```
aws ec2 create-route-table --vpc-id vpc-CHANGEME --query RouteTable.RouteTableId --output text
```
**Example Output**
```
rtb-c1c8faa6
```
### Create a route in the route table that points all traffic (0.0.0.0/0) to the internet gateway using the following create-route command.

**Command**
```
aws ec2 create-route --route-table-id rtb-CHANGEME --destination-cidr-block 0.0.0.0/0 --gateway-id igw-CHANGEME
```

## Association the Route with a Subnet.

Note: The route table is currently not associated with any subnet. You need to associate it with a subnet in your VPC so that traffic from that subnet is routed to the internet gateway. Use the following describe-subnets command to get the subnet IDs. The --filter option restricts the subnets to your new VPC only, and the --query option returns only the subnet IDs and their CIDR blocks.

**Command**
```
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-CHANGEME" --query "Subnets[*].{ID:SubnetId,CIDR:CidrBlock}"
```

**Example Output**
```
[
    {
        "CIDR": "10.0.1.0/24",
        "ID": "subnet-b46032ec"
    },
    {
        "CIDR": "10.0.0.0/24",
        "ID": "subnet-a46032fc"
    }
]
```

### Associate the subnet to the route using the associate-route-table command. This subnet is your public subnet.

**Command**
```
aws ec2 associate-route-table  --subnet-id subnet-CHANGEME --route-table-id rtb-CHANGEME
```

## Add a public IP address to an ec2 instance on launch

Note: You can modify the public IP addressing behaviour of your subnet so that an instance launched into the subnet automatically receives a public IP address using the following modify-subnet-attribute command. Otherwise, associate an Elastic IP address with your instance after launch so that the instance is reachable from the internet.

**Command**

```
aws ec2 modify-subnet-attribute --subnet-id subnet-CHANGEME --map-public-ip-on-launch
```

## Create a security group in your VPC using the create-security-group command.

**Command**
```
aws ec2 create-security-group --group-name External_Access --description "External Access" --vpc-id vpc-CHANGEME
```

**Example Output**
```
{
    "GroupId": "sg-e1fb8c9a"
}
```

## Add a rule that allows external access from anywhere using the authorize-security-group-ingress command.

**Command**
```
aws ec2 authorize-security-group-ingress --group-id sg-CHANGEME --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id sg-CHANGEME --protocol tcp --port 9090 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id sg-CHANGEME --protocol tcp --port 8080 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id sg-CHANGEME --protocol tcp --port 80 --cidr 0.0.0.0/0
```
# Running Configure AWS EC2 Networking as a script.
```
#!/bin/bash
#
# Created 23FEB2022
# Last Tested 04MARCH2022
#
# Vars Collected and Used
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
echo "AWS_EC2_Setup.sh Complete. Please check AWS_EC2_INFO"
#
echo "# $vpc" > Instance_Creation_Template.sh
echo "# $igw" >> Instance_Creation_Template.sh
echo "# $rtb" >> Instance_Creation_Template.sh
echo "# $subnet" >> Instance_Creation_Template.sh
echo "# $sg" >> Instance_Creation_Template.sh
#
```

# Output - Instance Creation Template.

Modify and run to launch new instances.

```
NAME='instance1'
SSHKEY='AWS-EC2-KEY.pem'     # the name of your SSH key: `aws ec2 describe-key-pairs`
IMAGE='ami-xxx'     # the AMI ID found on the download page
DISK='20'           # the size of the hard disk
REGION='us-east-1'  # the target region
TYPE='m5.large'     # the instance type
SUBNET='subnet-xxx' # the subnet: `aws ec2 describe-subnets`
SECURITY_GROUPS='sg-xx' # the security group `aws ec2 describe-security-groups`
aws ec2 run-instances                     \
    --region $REGION                      \
    --image-id $IMAGE                     \
    --instance-type $TYPE                 \
    --key-name $SSHKEY                    \
    --subnet-id $SUBNET                   \
    --security-group-ids $SECURITY_GROUPS \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${NAME}}]" \
    --block-device-mappings "VirtualName=/dev/xvda,DeviceName=/dev/xvda,Ebs={VolumeSize=${DISK}}"
```

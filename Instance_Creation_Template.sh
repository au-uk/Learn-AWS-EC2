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

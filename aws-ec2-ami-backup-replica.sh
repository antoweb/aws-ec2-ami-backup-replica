#!/bin/bash

# Author: Antonello Cordella
# Updated: May 24th, 2021
# Webiste: https://github.com/antoweb/ or https://www.sistemistaitaliano.it

# This script is a fork of following Author
# Author: Pablo Suarez
# Updated: October 28th, 2017
# Website: https://github.com/pavlops
# Usage: aws-ami-backup.sh <ec2-instance-id> <identifier> <retention days> <aws local profile>

#Initialize variables
currDate=$(date +%Y%m%d%H%M)
#instanceId="$1"
#instanceName="$2"
maxret=$1
profile=$2
#name="*$instanceName auto*"

#Empty temp files
> /tmp/instancetobackup
> /tmp/instancestoppedtobackup
> /tmp/amicreatedsingleline
> /tmp/instancesrunningbackedup
> /tmp/instancesstoppedbackedup
> /tmp/amicreated

#List all running instances for retriving Instance Name
aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].{Instance:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" --output text --profile "$profile" > /tmp/instancesrunningbackedup

#List all existing image for running instances
while IFS=$'\t' read -r -a myArray
do
   result=$(aws ec2 describe-images --filters "Name=name,Values=*${myArray[1]} auto*" --query 'Images[*].{CreationDate:CreationDate,ImageId:ImageId}' --output text --profile "$profile" | sort -r)
done < /tmp/instancesrunningbackedup

#deleting old images of running instances
while read line; do
  let i++
  if [ "$i" -gt "$maxret" ]; then

    #Get snapshots from AMIs
    amiID=$(echo $line | awk -F ' ' '{print $2}')
    snapshots=$(aws ec2 describe-images --image-ids "$amiID" --query 'Images[0].BlockDeviceMappings[*].Ebs.{SnapshotId:SnapshotId}' --output text --profile "$profile")
    aws ec2 deregister-image --image-id "$amiID" --profile "$profile"
    echo "$amiID deleted."

    while read snapshotId; do
      aws ec2 delete-snapshot --snapshot-id "$snapshotId" --profile "$profile"
      echo "$snapshotId deleted."
    done <<< "$snapshots"

  fi
done <<< "$result"


#List all stopped instances for retriving Instance Name

aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" "Name=tag:backup_if_stopped,Values=True" --query "Reservations[*].Instances[*].{Instance:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" --output text --profile "$profile" > /tmp/instancesstoppedbackedup

#List all existing image for stopped instances
while IFS=$'\t' read -r -a myArray1
do
   result1=$(aws ec2 describe-images --filters "Name=name,Values=*${myArray1[1]} stopped auto*" --query 'Images[*].{CreationDate:CreationDate,ImageId:ImageId}' --output text --profile "$profile" | sort -r)
done < /tmp/instancesstoppedbackedup

#deleting old images of stopped instances
while read line; do
  let i1++
  if [ "$i1" -gt "$maxret" ]; then

    #Get snapshots from AMIs
    amiID=$(echo $line | awk -F ' ' '{print $2}')
    snapshots=$(aws ec2 describe-images --image-ids "$amiID" --query 'Images[0].BlockDeviceMappings[*].Ebs.{SnapshotId:SnapshotId}' --output text --profile "$profile")
    aws ec2 deregister-image --image-id "$amiID" --profile "$profile"
    echo "$amiID deleted."

    while read snapshotId; do
      aws ec2 delete-snapshot --snapshot-id "$snapshotId" --profile "$profile"
      echo "$snapshotId deleted."
    done <<< "$snapshots"

  fi
done <<< "$result1"

#Create new AMI from the instance runing
#running=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].InstanceId" --output text --profile "$profile")

aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].{Instance:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" --output text --profile "$profile" > /tmp/instancetobackup

while IFS=$'\t' read -r -a myArray
do
   aws ec2 create-image --instance-id ${myArray[0]} --name "$currDate ${myArray[1]} auto" --no-reboot --profile "$profile" >> /tmp/amicreated 2>&1
done < /tmp/instancetobackup


#Create new AMI for instances stopped and with tag backup_if_stopped=True
aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" "Name=tag:backup_if_stopped,Values=True" --query "Reservations[*].Instances[*].{Instance:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" --output text --profile "$profile" > /tmp/instancestoppedtobackup

while IFS=$'\t' read -r -a myArray
do
   aws ec2 create-image --instance-id ${myArray[0]} --name "$currDate ${myArray[1]} stopped auto" --no-reboot --profile "$profile" >> /tmp/amicreated 2>&1
done < /tmp/instancestoppedtobackup

#COpy ami to another region
jq -r '.ImageId' /tmp/amicreated > /tmp/amicreatedsingleline

while read p; do
imagename=$(aws ec2 describe-images --image-ids $p --query 'Images[*].[Name]' --output text --profile "$profile")
aws ec2 copy-image --source-image-id "$p" --source-region eu-central-1 --region eu-west-1 --name "$imagename" --profile "$profile"
done < /tmp/amicreatedsingleline

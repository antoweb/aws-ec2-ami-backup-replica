#!/bin/bash

# Author: Antonello Cordella
# Updated: May 24th, 2021
# Webiste: https://github.com/antoweb/ or https://www.sistemistaitaliano.it
# This script born from aws-ec2-ami-backup-replica.sh but you can choose source and destination region in script parameter ($3 and $4)


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
sourceregion=$3
destregion=$4

#Empty temp files
> /tmp/instancetobackup_"$profile"_"$sourceregion"
> /tmp/instancestoppedtobackup_"$profile"_"$sourceregion"
> /tmp/amicreatedsingleline_"$profile"_"$sourceregion"
> /tmp/instancesrunningbackedup_"$profile"_"$sourceregion"
> /tmp/instancesstoppedbackedup_"$profile"_"$sourceregion"
> /tmp/amicreated_"$profile"_"$sourceregion"

echo "---------------------------"
echo "INIZIO BACKUP PER $profile"
echo "---------------------------"

#List all running instances for retriving Instance Name
echo "List all running instances for retriving Instance Name for $profile"
aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].{Instance:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" --output text --profile "$profile" --region "$sourceregion" > /tmp/instancesrunningbackedup_"$profile"_"$sourceregion"
        cat /tmp/instancesrunningbackedup_"$profile"_"$sourceregion"

#List all existing image for running instances in source region
echo "List all existing image for running instances in source region for $profile"
while IFS=$'\t' read -r -a myArray
do
   result=$(aws ec2 describe-images --filters "Name=name,Values=*${myArray[1]} auto*" --query 'Images[*].{CreationDate:CreationDate,ImageId:ImageId}' --output text --profile "$profile" --region "$sourceregion" | sort -r)
done < /tmp/instancesrunningbackedup_"$profile"_"$sourceregion"
echo $result

#deleting old images of running instances in source region
echo "deleting old images of running instances in source region for $profile"
while read line; do
  let i++
  if [ "$i" -gt "$maxret" ]; then

    #Get snapshots from AMIs
    amiID=$(echo $line | awk -F ' ' '{print $2}')
    snapshots=$(aws ec2 describe-images --image-ids "$amiID" --query 'Images[0].BlockDeviceMappings[*].Ebs.{SnapshotId:SnapshotId}' --output text --profile "$profile" --region "$sourceregion")
    aws ec2 deregister-image --image-id "$amiID" --profile "$profile" --region "$sourceregion"
    echo "$amiID deleted."

    while read snapshotId; do
      aws ec2 delete-snapshot --snapshot-id "$snapshotId" --profile "$profile" --region "$sourceregion"
      echo "$snapshotId deleted."
    done <<< "$snapshots"

  fi
done <<< "$result"


#List all existing image for running instances in destination region
echo "List all existing image for running instances in destination region for $profile"
while IFS=$'\t' read -r -a myArrayd
do
   resultd=$(aws ec2 describe-images --filters "Name=name,Values=*${myArrayd[1]} auto*" --query 'Images[*].{CreationDate:CreationDate,ImageId:ImageId}' --output text --profile "$profile" --region "$destregion" | sort -r)
done < /tmp/instancesrunningbackedup_"$profile"_"$sourceregion"
echo $resultd

#deleting old images of running instances in destination region
echo "deleting old images of running instances in destination region for $profile"
while read line; do
  let id++
  if [ "$id" -gt "$maxret" ]; then

    #Get snapshots from AMIs
    amiID=$(echo $line | awk -F ' ' '{print $2}')
    snapshots=$(aws ec2 describe-images --image-ids "$amiID" --query 'Images[0].BlockDeviceMappings[*].Ebs.{SnapshotId:SnapshotId}' --output text --profile "$profile" --region "$destregion")
    aws ec2 deregister-image --image-id "$amiID" --profile "$profile" --region "$destregion"
    echo "$amiID deleted."

    while read snapshotId; do
      aws ec2 delete-snapshot --snapshot-id "$snapshotId" --profile "$profile" --region "$destregion"
      echo "$snapshotId deleted."
    done <<< "$snapshots"

  fi
done <<< "$resultd"


#List all stopped instances for retriving Instance Name
echo "List all stopped instances for retriving Instance Name for $profile"
aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" "Name=tag:backup_if_stopped,Values=True,true" --query "Reservations[*].Instances[*].{Instance:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" --output text --profile "$profile" --region "$sourceregion" > /tmp/instancesstoppedbackedup_"$profile"_"$sourceregion"


#List all existing image for stopped instances in source region
echo "List all existing image for stopped instances in source region"
while IFS=$'\t' read -r -a myArray1
do
   result1=$(aws ec2 describe-images --filters "Name=name,Values=*${myArray1[1]} stopped auto*" --query 'Images[*].{CreationDate:CreationDate,ImageId:ImageId}' --output text --profile "$profile" --region "$sourceregion" | sort -r)
done < /tmp/instancesstoppedbackedup_"$profile"_"$sourceregion"
echo $result1

#deleting old images of stopped instances in source region
echo "deleting old images of stopped instances in source region for $profile"
while read line; do
  let i1++
  if [ "$i1" -gt "$maxret" ]; then

    #Get snapshots from AMIs
    amiID=$(echo $line | awk -F ' ' '{print $2}')
    snapshots=$(aws ec2 describe-images --image-ids "$amiID" --query 'Images[0].BlockDeviceMappings[*].Ebs.{SnapshotId:SnapshotId}' --output text --profile "$profile" --region "$sourceregion")
    aws ec2 deregister-image --image-id "$amiID" --profile "$profile" --region "$sourceregion"
    echo "$amiID deleted."

    while read snapshotId; do
      aws ec2 delete-snapshot --snapshot-id "$snapshotId" --profile "$profile" --region "$sourceregion"
      echo "$snapshotId deleted."
    done <<< "$snapshots"

  fi
done <<< "$result1"

#List all existing image for stopped instances in destination region
echo "List all existing image for stopped instances in destination region for $profile"
while IFS=$'\t' read -r -a myArray1d
do
   result1d=$(aws ec2 describe-images --filters "Name=name,Values=*${myArray1d[1]} stopped auto*" --query 'Images[*].{CreationDate:CreationDate,ImageId:ImageId}' --output text --profile "$profile" --region "$destregion" | sort -r)
done < /tmp/instancesstoppedbackedup_"$profile"_"$sourceregion"
echo $result1d

#deleting old images of stopped instances in destination region
echo "deleting old images of stopped instances in destination region for $profile"
while read line; do
  let i1d++
  if [ "$i1d" -gt "$maxret" ]; then

    #Get snapshots from AMIs
    amiID=$(echo $line | awk -F ' ' '{print $2}')
    snapshots=$(aws ec2 describe-images --image-ids "$amiID" --query 'Images[0].BlockDeviceMappings[*].Ebs.{SnapshotId:SnapshotId}' --output text --profile "$profile" --region "$destregion")
    aws ec2 deregister-image --image-id "$amiID" --profile "$profile" --region "$destregion"
    echo "$amiID deleted."

    while read snapshotId; do
      aws ec2 delete-snapshot --snapshot-id "$snapshotId" --profile "$profile" --region "$destregion"
      echo "$snapshotId deleted."
    done <<< "$snapshots"

  fi
done <<< "$result1d"


#Create new AMI from the instance running
#running=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].InstanceId" --output text --profile "$profile")
echo "Create new AMI from the instance running for $profile"

aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].{Instance:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" --output text --profile "$profile" --region "$sourceregion" > /tmp/instancetobackup_"$profile"_"$sourceregion"
cat /tmp/instancetobackup_"$profile"_"$sourceregion"

while IFS=$'\t' read -r -a myArray
do
   aws ec2 create-image --instance-id ${myArray[0]} --name "$currDate ${myArray[1]} auto" --no-reboot --profile "$profile" --region "$sourceregion" >> /tmp/amicreated_"$profile"_"$sourceregion" 2>&1
done < /tmp/instancetobackup_"$profile"_"$sourceregion"


#Create new AMI for instances stopped and with tag backup_if_stopped=True
echo "Create new AMI for instances stopped and with tag backup_if_stopped=True for $profile"
aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" "Name=tag:backup_if_stopped,Values=True,true" --query "Reservations[*].Instances[*].{Instance:InstanceId,Name:Tags[?Key=='Name']|[0].Value}" --output text --profile "$profile" --region "$sourceregion" > /tmp/instancestoppedtobackup_"$profile"_"$sourceregion"

while IFS=$'\t' read -r -a myArray
do
   aws ec2 create-image --instance-id ${myArray[0]} --name "$currDate ${myArray[1]} stopped auto" --no-reboot --profile "$profile" --region "$sourceregion" >> /tmp/amicreated_"$profile"_"$sourceregion" 2>&1
done < /tmp/instancestoppedtobackup_"$profile"_"$sourceregion"
cat /tmp/instancestoppedtobackup_"$profile"_"$sourceregion"
echo "Ho creato le seguenti AMI di istanze running e stopped con tag"
cat /tmp/amicreated_"$profile"_"$sourceregion"



#Copy ami to another region
echo "Copy ami to another region"
jq -r '.ImageId' /tmp/amicreated_"$profile"_"$sourceregion" > /tmp/amicreatedsingleline_"$profile"_"$sourceregion"

while read p; do
imagename=$(aws ec2 describe-images --image-ids $p --query 'Images[*].[Name]' --output text --profile "$profile" --region "$sourceregion")
aws ec2 copy-image --source-image-id "$p" --source-region "$sourceregion" --region "$destregion" --name "$imagename" --profile "$profile"
done < /tmp/amicreatedsingleline_"$profile"_"$sourceregion"
echo "Ho copiato a Stoccolma le seguenti AMI"
cat /tmp/amicreatedsingleline_"$profile"_"$sourceregion"

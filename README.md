# aws-ec2-ami-backup-replica
Shell script for backup ec2 with ami and cross region replica
fork from https://github.com/pavlops/aws-ami-backups

This script starts from the script of but has been improved in these points:

1) Removed the InstanceId parameter and the Identifier parameter

2) Backs up all hooks in running state and those in stopped state with the tag backup_if_stopped = True

3) Create a replica in eu-central-1 (or you must change line 111)

Requirements:

1) Ec2 must be in eu-west-1 or you have to change the line 111
2) Replica is in eu-central-1 (or you must change line 111)
3) The server from which it is launched must have the aws profile configured
4) Aws cli

Usage:

./aws-ec2-ami-backup-replica.sh <retentiondays> <profile>

  
A future version will also support the region

PAYPAL DONTAION  
[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.me/sistemistaitaliano/1)

# aws-ec2-ami-backup-replica (script aws-ec2-ami-backup-replica.sh)
Shell script for backup ec2 with ami and cross region replica
fork from https://github.com/pavlops/aws-ami-backups

This script starts from the script of https://github.com/pavlops/aws-ami-backups but has been improved in these points:

1) Removed the InstanceId parameter and the Identifier parameter

2) Backs up all hooks in running state and those in stopped state with the tag backup_if_stopped = True

3) Create a replica in eu-central-1 (or you must change line 111)

Requirements:

1) ~~Ec2 must be in eu-west-1 or you have to change the line 111~~ Ec2 source region can be setup in variable $sourceregion
2) Replica is in eu-central-1 ~~(or you must change line 111)~~ Ora change variable $destregion
3) The server from which it is launched must have the aws profile configured
4) Aws cli

Usage:

<pre><code> ./aws-ec2-ami-backup-replica.sh retentiondays profile </code></pre>

  
A future version will also support the region

UPDATE 09/06/2021
- Added support for choosing regions in variable
- Added search for instances with tag value backup_if_stopped True or true
- Added deleting old images from destination region

# aws-ec2-ami-backup-REGION-replica (script aws-ec2-ami-backup-REGION-replica.sh)
**SCRIPT aws-ec2-ami-backup-REGION-replica.sh**

Same as before script but with possibility to choose source and destination region in parameter ($3 and $4)

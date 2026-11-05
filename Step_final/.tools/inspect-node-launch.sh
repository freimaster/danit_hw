#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
aws ec2 describe-instances --filters Name=vpc-id,Values=vpc-063fcae1ff7454f1d --query 'Reservations[].Instances[].{id:InstanceId,state:State.Name,type:InstanceType,launch:LaunchTime}' --output json
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName,`eks-main`)].{name:AutoScalingGroupName,desired:DesiredCapacity,instances:Instances[].{id:InstanceId,state:LifecycleState}}' --output json
aws eks list-nodegroups --cluster-name freimaster --output json

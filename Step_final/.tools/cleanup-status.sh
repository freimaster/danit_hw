#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
aws eks describe-nodegroup --cluster-name freimaster --nodegroup-name main-20261105104312199800000009 --output json
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName,`eks-main-20261105`)].AutoScalingGroupName' --output json
aws ec2 describe-instances --filters Name=vpc-id,Values=vpc-063fcae1ff7454f1d --query 'Reservations[].Instances[].{id:InstanceId,state:State.Name}' --output json
aws ec2 describe-volumes --filters Name=volume-id,Values=vol-0f2cd4b3625747a54 --query 'length(Volumes)' --output text
aws elb describe-load-balancers --query 'length(LoadBalancerDescriptions[?VPCId==`vpc-063fcae1ff7454f1d`])' --output text
aws ec2 describe-launch-templates --query 'LaunchTemplates[].{id:LaunchTemplateId,name:LaunchTemplateName}' --output json

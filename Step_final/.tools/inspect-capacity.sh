#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
nodegroup="$(aws eks list-nodegroups --cluster-name freimaster --query 'nodegroups[0]' --output text)"
asg="$(aws eks describe-nodegroup --cluster-name freimaster --nodegroup-name "$nodegroup" --query 'nodegroup.resources.autoScalingGroups[0].name' --output text)"
if [[ "$asg" == None ]]; then
  asg="$(aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?contains(AutoScalingGroupName,`eks-main`)].AutoScalingGroupName | [0]' --output text)"
fi
if [[ "$asg" != None ]]; then
  aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$asg" --query 'AutoScalingGroups[].{desired:DesiredCapacity,instances:Instances[].{id:InstanceId,state:LifecycleState,health:HealthStatus}}' --output json
  aws autoscaling describe-scaling-activities --auto-scaling-group-name "$asg" --max-items 3 --query 'Activities[].{status:StatusCode,description:Description,message:StatusMessage}' --output json
fi

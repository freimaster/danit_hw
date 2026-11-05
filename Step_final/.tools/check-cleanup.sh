#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
zero() {
  label="$1"; shift
  count="$("$@")"
  [[ "$count" == 0 ]] || { echo "$label: remaining count $count" >&2; exit 1; }
  echo "$label: 0 remaining (PASS)"
}
zero 'EKS cluster' aws eks list-clusters --query 'length(clusters[?@==`freimaster`])' --output text
zero 'Active EC2 instances in project VPC' aws ec2 describe-instances --filters Name=vpc-id,Values=vpc-063fcae1ff7454f1d Name=instance-state-name,Values=pending,running,stopping,stopped,shutting-down --query 'length(Reservations[].Instances[])' --output text
zero 'Node EBS volume' aws ec2 describe-volumes --filters Name=volume-id,Values=vol-0f2cd4b3625747a54 --query 'length(Volumes)' --output text
zero 'Classic ELB in project VPC' aws elb describe-load-balancers --query 'length(LoadBalancerDescriptions[?VPCId==`vpc-063fcae1ff7454f1d`])' --output text
zero 'Project VPC' aws ec2 describe-vpcs --filters Name=vpc-id,Values=vpc-063fcae1ff7454f1d --query 'length(Vpcs)' --output text
zero 'Project network interfaces' aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=vpc-063fcae1ff7454f1d --query 'length(NetworkInterfaces)' --output text
zero 'Project security groups' aws ec2 describe-security-groups --filters Name=vpc-id,Values=vpc-063fcae1ff7454f1d --query 'length(SecurityGroups)' --output text
zero 'Project DNS zone' aws route53 list-hosted-zones-by-name --dns-name systemd.pp.ua --query 'length(HostedZones[?Name==`systemd.pp.ua.`])' --output text
zero 'Node launch template' aws ec2 describe-launch-templates --filters Name=launch-template-name,Values=main-20261105104306156000000007 --query 'length(LaunchTemplates)' --output text
zero 'Project Auto Scaling groups' aws autoscaling describe-auto-scaling-groups --query 'length(AutoScalingGroups[?contains(AutoScalingGroupName,`eks-main-20261105`)])' --output text
zero 'EKS-created failed group launch template' aws ec2 describe-launch-templates --filters Name=launch-template-name,Values=eks-22d0d5a7-1b7a-54e8-7ee3-45968a79a7cc --query 'length(LaunchTemplates)' --output text
zero 'Project IAM roles' aws iam list-roles --query 'length(Roles[?RoleName==`freimaster-cluster-20261105103428251800000001` || RoleName==`main-eks-node-group-20261105103452138100000005`])' --output text
python3 - <<'PY'
import json
from pathlib import Path
for path in [*Path('terraform').glob('*/terraform.tfstate'), Path('../.tools/recovery-nodegroup/terraform.tfstate'), Path('../.tools/recovery-asg/terraform.tfstate')]:
    state=json.loads(path.read_text())
    count=sum(len(r.get('instances',[])) for r in state.get('resources',[]) if r.get('mode')=='managed')
    assert count==0,(str(path),count)
    print(str(path)+': 0 managed resources (PASS)')
PY

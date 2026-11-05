#!/usr/bin/env bash
set -euo pipefail
source /mnt/c/Users/g_fre/Documents/danit_hw/Step_final/.tools/wsl-env.sh
aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true --query 'InstanceTypes[].{type:InstanceType,vcpu:VCpuInfo.DefaultVCpus,memoryMiB:MemoryInfo.SizeInMiB,architecture:ProcessorInfo.SupportedArchitectures}' --output json

#!/bin/bash

# Usage:
# chmod +x aws-paid-net.sh
#./aws-paid-net.sh status
#./aws-paid-net.sh net-up
#./aws-paid-net.sh net-stop
# aws: [ERROR]: An error occurred (InvalidParameterValue) when calling the ReplaceRoute operation: There is no route defined for '0.0.0.0/0' in the route table. Use CreateRoute instead. - IS OK

set -euo pipefail

REGION="eu-central-1"

VPC_ID="vpc-036be8e8ade1a318c"
PUBLIC_SUBNET_ID="subnet-0762232c27a6494a0"   # main-publik-b
PRIVATE_RT_ID="rtb-098f14afd50cb0103"         # main-private

NAT_NAME="main-nat"
ACTION="${1:-status}"

info() {
  echo "==> $1"
}

get_nat_id() {
  aws ec2 describe-nat-gateways \
    --region "$REGION" \
    --filter "Name=vpc-id,Values=$VPC_ID" \
    --filter "Name=tag:Name,Values=$NAT_NAME" \
    --filter "Name=state,Values=available,pending" \
    --query "NatGateways[0].NatGatewayId" \
    --output text
}

get_eip_allocation_id() {
  aws ec2 describe-addresses \
    --region "$REGION" \
    --filters "Name=tag:Name,Values=$NAT_NAME" \
    --query "Addresses[0].AllocationId" \
    --output text
}

status() {
  info "NAT Gateway"
  aws ec2 describe-nat-gateways \
    --region "$REGION" \
    --filter "Name=vpc-id,Values=$VPC_ID" \
    --query "NatGateways[*].[Tags[?Key=='Name'].Value|[0],NatGatewayId,State,SubnetId,NatGatewayAddresses[0].PublicIp,NatGatewayAddresses[0].PrivateIp]" \
    --output table

  info "Elastic IPs"
  aws ec2 describe-addresses \
    --region "$REGION" \
    --query "Addresses[*].[Tags[?Key=='Name'].Value|[0],PublicIp,AllocationId,AssociationId,PrivateIpAddress]" \
    --output table

  info "Private route table"
  aws ec2 describe-route-tables \
    --region "$REGION" \
    --route-table-ids "$PRIVATE_RT_ID" \
    --query "RouteTables[*].Routes[*].[DestinationCidrBlock,NatGatewayId,GatewayId,State]" \
    --output table
}

net_up() {
  NAT_ID="$(get_nat_id)"

  if [[ "$NAT_ID" != "None" && -n "$NAT_ID" ]]; then
    info "NAT already exists: $NAT_ID"
    exit 0
  fi

  info "Allocate Elastic IP"
  ALLOCATION_ID="$(aws ec2 allocate-address \
    --region "$REGION" \
    --domain vpc \
    --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=$NAT_NAME}]" \
    --query "AllocationId" \
    --output text)"

  info "Create NAT Gateway"
  NAT_ID="$(aws ec2 create-nat-gateway \
    --region "$REGION" \
    --subnet-id "$PUBLIC_SUBNET_ID" \
    --allocation-id "$ALLOCATION_ID" \
    --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=$NAT_NAME}]" \
    --query "NatGateway.NatGatewayId" \
    --output text)"

  info "Waiting NAT available: $NAT_ID"
  aws ec2 wait nat-gateway-available \
    --region "$REGION" \
    --nat-gateway-ids "$NAT_ID"

  info "Set private route 0.0.0.0/0 -> NAT"
  aws ec2 replace-route \
    --region "$REGION" \
    --route-table-id "$PRIVATE_RT_ID" \
    --destination-cidr-block "0.0.0.0/0" \
    --nat-gateway-id "$NAT_ID" \
  || aws ec2 create-route \
    --region "$REGION" \
    --route-table-id "$PRIVATE_RT_ID" \
    --destination-cidr-block "0.0.0.0/0" \
    --nat-gateway-id "$NAT_ID"

  info "Network paid part is UP"
}

net_stop() {
  NAT_ID="$(get_nat_id)"
  ALLOCATION_ID="$(get_eip_allocation_id)"

  info "Remove private default route"
  aws ec2 delete-route \
    --region "$REGION" \
    --route-table-id "$PRIVATE_RT_ID" \
    --destination-cidr-block "0.0.0.0/0" \
  || true

  if [[ "$NAT_ID" != "None" && -n "$NAT_ID" ]]; then
    info "Delete NAT Gateway: $NAT_ID"
    aws ec2 delete-nat-gateway \
      --region "$REGION" \
      --nat-gateway-id "$NAT_ID"

    info "Waiting NAT deleted"
    aws ec2 wait nat-gateway-deleted \
      --region "$REGION" \
      --nat-gateway-ids "$NAT_ID"
  else
    info "No NAT Gateway found"
  fi

  if [[ "$ALLOCATION_ID" != "None" && -n "$ALLOCATION_ID" ]]; then
    info "Release Elastic IP: $ALLOCATION_ID"
    aws ec2 release-address \
      --region "$REGION" \
      --allocation-id "$ALLOCATION_ID"
  else
    info "No tagged Elastic IP found"
  fi

  info "Network paid part is STOPPED"
}

case "$ACTION" in
  status)
    status
    ;;
  net-up)
    net_up
    ;;
  net-stop)
    net_stop
    ;;
  *)
    echo "Usage:"
    echo "  $0 status"
    echo "  $0 net-up"
    echo "  $0 net-stop"
    exit 1
    ;;
esac
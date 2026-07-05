#!/bin/bash
set -e

BUCKET1="s3-lab-dmva-20260705-896680309229-eu-central-1-an"
BUCKET2="s3-deny-check-dmva-20260705-896680309229-eu-central-1-an"

USER_NAME="S3-labUser"
POLICY_ARN="arn:aws:iam::896680309229:policy/s3-only-s3-lab-dmva"

echo "Empty and delete S3 buckets..."

aws s3 rm "s3://$BUCKET1" --recursive || true
aws s3 rb "s3://$BUCKET1" || true

aws s3 rm "s3://$BUCKET2" --recursive || true
aws s3 rb "s3://$BUCKET2" || true

echo "Detach policy from user..."
aws iam detach-user-policy \
  --user-name "$USER_NAME" \
  --policy-arn "$POLICY_ARN" || true

echo "Delete user access keys..."
for KEY in $(aws iam list-access-keys --user-name "$USER_NAME" --query 'AccessKeyMetadata[*].AccessKeyId' --output text); do
  aws iam delete-access-key --user-name "$USER_NAME" --access-key-id "$KEY"
done

echo "Delete login profile..."
aws iam delete-login-profile --user-name "$USER_NAME" || true

echo "Delete IAM user..."
aws iam delete-user --user-name "$USER_NAME" || true

echo "Delete IAM policy..."
aws iam delete-policy --policy-arn "$POLICY_ARN" || true

echo "Done."
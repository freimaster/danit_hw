import boto3

REGION = "eu-central-1"
TAG_KEY = "AutoTerminate"
TAG_VALUE = "true"

ec2 = boto3.client("ec2", region_name=REGION)

def lambda_handler(event, context):
    response = ec2.describe_instances(
        Filters=[
            {
                "Name": f"tag:{TAG_KEY}",
                "Values": [TAG_VALUE]
            },
            {
                "Name": "instance-state-name",
                "Values": ["pending", "running", "stopping", "stopped"]
            }
        ]
    )

    instance_ids = []

    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            instance_ids.append(instance["InstanceId"])

    if not instance_ids:
        print("No tagged EC2 instances found for termination")
        return {
            "terminated": []
        }

    ec2.terminate_instances(InstanceIds=instance_ids)

    print(f"Terminated instances: {instance_ids}")

    return {
        "terminated": instance_ids
    }
import logging
import os
from typing import List, Optional
from .config import LOG_LEVEL, POOL_TAG_KEY

import boto3
from botocore.exceptions import ClientError

log = logging.getLogger()
log.setLevel(LOG_LEVEL)

ec2 = boto3.client("ec2")


class EC2Instance(dict):
    def __init__(self, instance: dict):
        self.update(instance)

    @property
    def instance_id(self) -> str:
        return self["InstanceId"]

    @property
    def primary_network_interface_id(self):
        return (
            self["NetworkInterfaces"][0]["NetworkInterfaceId"]
            if self["NetworkInterfaces"]
            else None
        )

    @property
    def pool_name(self) -> str:
        return self.tags.get(POOL_TAG_KEY, None)

    @property
    def tags(self) -> dict:
        return {t["Key"]: t["Value"] for t in self["Tags"]}

    def __key(self):
        return self["InstanceId"]

    def __hash__(self):
        return hash(self.__key())

    def __eq__(self, other):
        return self.__key() == other.__key()

    def __str__(self):
        return str(self.__key())


def describe_pool_instance(instance_id: str) -> Optional[EC2Instance]:
    try:
        response = ec2.describe_instances(InstanceIds=[instance_id])
        return EC2Instance(response["Reservations"][0]["Instances"][0])
    except ClientError as e:
        log.error(f'failed to describe instance "{instance_id}", {e}')
    return None


def get_pool_instances(pool_name: str) -> List[EC2Instance]:
    """
    get all running ec2 instances with tagged with the `pool_name`
    """
    result = []
    paginator = ec2.get_paginator("describe_instances")
    pages = paginator.paginate(
        Filters=[
            {"Name": f"tag:{POOL_TAG_KEY}", "Values": [pool_name]},
            {"Name": "instance-state-name", "Values": ["running"]},
        ]
    )
    for page in pages:
        for reservation in page["Reservations"]:
            result.extend([EC2Instance(i) for i in reservation["Instances"]])
    return result

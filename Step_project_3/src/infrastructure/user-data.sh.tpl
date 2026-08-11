#!/bin/bash

install -d -m 700 -o ubuntu -g ubuntu /home/ubuntu/.ssh

echo '${ssh_public_key}' >> /home/ubuntu/.ssh/authorized_keys

chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys

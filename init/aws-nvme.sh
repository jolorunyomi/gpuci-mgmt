#!/bin/bash
#
# Copyright (c) 2019, NVIDIA CORPORATION.
#
# AWS init script for gpuCI nodes with nvme drives on nodes
#
set -e

SCRIPT_NAME="$0"
function logger {
  TS=`date +%F_%H-%M-%S`
  echo "[$SCRIPT_NAME $TS] $@"
}

logger "Check if nvme is already mounted; if not format and mount"
INSTANCE_NVME=`sudo nvme list | grep "Amazon EC2 NVMe Instance Storage" | awk '{ print $1 }' | head -n1`
logger "Instance NVMe found - $INSTANCE_NVME"
if ! grep -qa "$INSTANCE_NVME /jenkins " /proc/mounts; then
  logger "$INSTANCE_NVME not mounted, mounting and formatting"
  sudo mkfs -t ext4 $INSTANCE_NVME && sudo mkdir -p /jenkins && sudo mount $INSTANCE_NVME /jenkins
else
  logger "$INSTANCE_NVME already mounted"
fi

logger "Check mounts"
mount
df -h

logger "Ensure ubuntu user has full rights on directory for Jenkins work"
sudo chown -R ubuntu:ubuntu /jenkins

logger "Relocate /tmp to NVMe for faster perf"
if [ ! -d "/jenkins/tmp" ] ; then
  logger "/tmp needs relocating"
  sudo mv /tmp /jenkins
  sudo ln -s /jenkins/tmp /tmp
  logger "/tmp relocated to /jenkins"
else
  logger "/jenkins/tmp already exists"
fi
  
logger "Override docker setup and utilize internal docker registry mirror"
sudo service docker stop
sudo cat /etc/docker/daemon.json
cat <<EOL > /tmp/daemon.json
{
    "registry-mirrors": ["http://docker-mirror.rapids.ai:5000"],
    "experimental": true
}
EOL
sudo mv /tmp/daemon.json /etc/docker/daemon.json
sudo cat /etc/docker/daemon.json
sudo service docker start

logger "Ensure docker system is clean"
set +e
docker system prune -f

logger "Connect node to Jenkins"
wget https://gpuci.gpuopenanalytics.com/plugin/ec2/AMI-Scripts/ubuntu-ami-setup.sh
sudo sh ubuntu-ami-setup.sh gpuci.gpuopenanalytics.com

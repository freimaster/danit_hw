#!/bin/bash
OLDHOST=$(hostname)
NEWHOST="lubuntu24"
hostnamectl set-hostname "$NEWHOST"
sed -i "s/\b$OLDHOST\b/$NEWHOST/" /etc/hosts
export HOSTNAME="$NEWHOST"
exec bash
#!/bin/bash
ACHTUNGNUM='20'
USED=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$USED" -gt "$ACHTUNGNUM" ]; then
    echo "$(date) Увага! Використано ${USED}% дискового простору в / " >> /var/log/disk.log
fi
#!/usr/bin/env bash

# Looks for rLEDBAT traces in this system
#  generates file as ... (time,rtt,rtt_min)
# 0,0.052822,0.052822
# 0.00545306,0.052822,0.052822
# 0.0179781,0.052822,0.052822
# 0.031884,0.052822,0.052822
# 0.04589,0.052822,0.052822

awk '{print $(NF)}' /var/log/kern.log  | grep "read" | awk -F ";" '{if (FNR==2) time=$13; print ($12-time)/1000000000","$15/1000000000","$16/1000000000}' | tail -n +2
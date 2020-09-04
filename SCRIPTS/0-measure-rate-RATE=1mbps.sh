#!/usr/bin/env bash

# Generates flood pings from S2 to C2 to measure the maximum rate available 
# with the usual network configuration
echo "Executing $0"

source experiment_configuration.sh

FILENAME='0-measure-rate-RATE=1mbps'

ssh S2 "sudo pkill ping"

echo
echo 'Start tcpdump in R1'
# disable configurations that may gather many packets together in tcpdump
ssh R1 "sudo pkill tcpdump"
# ssh R1 "sudo tcpdump -s96 -ieth0 port 80 or port 9000 -w $RESULT_DIR/$FILENAME.pcap 2>&1" &
ssh R1 "sudo tcpdump -s96 -ieth0 -w $RESULT_DIR/$FILENAME.pcap" &
sleep 2
echo

echo
echo 'Start many flood pings C2 <-- S2:ping'
# each ping only sends an echo after a response, so lets start many
ssh S2 "sudo ping -s1472 -f -w 70 C2 > /dev/null" &
ssh S2 "sudo ping -s1472 -f -w 70 C2 > /dev/null" &
ssh S2 "sudo ping -s1472 -f -w 70 C2 > /dev/null" &
ssh S2 "sudo ping -s1472 -f -w 70 C2 > /dev/null" &
ssh S2 "sudo ping -s1472 -f -w 70 C2 > /dev/null" &
ssh S2 "sudo ping -s1472 -f -w 70 C2 > /dev/null" &
ssh S2 "sudo ping -s1472 -f -w 70 C2 > /dev/null" &
ssh S2 "sudo ping -s1472 -f -w 70 C2 > /dev/null" &
echo
echo "wait 60 s"
sleep 60

echo
echo 'Finish' 
ssh R1 "sudo pkill tcpdump"
sleep 2
scp R1:$RESULT_DIR/$FILENAME.pcap $RESULT_DIR

ssh S2 "sudo pkill ping"

# echo 'time,length' > $RESULT_DIR/$FILENAME.icmp_rate_csv
tshark -Y 'icmp.type==8' -t r -T fields -E separator=, -e frame.time_relative -e ip.len -r $RESULT_DIR/$FILENAME.pcap > $RESULT_DIR/$FILENAME.icmp_rate_csv

init_time=`head -n 1 $RESULT_DIR/$FILENAME.icmp_rate_csv | awk -F"," '{print $1}'`
end_time=`tail -n 1 $RESULT_DIR/$FILENAME.icmp_rate_csv | awk -F"," '{print $1}'`
lines=`wc -l <$RESULT_DIR/$FILENAME.icmp_rate_csv` 
echo ''
echo 'Measured rate in kbps'
echo "($lines -1) * 1500 *8 / ($end_time - $init_time)" | bc

# ./plot_window_csv.py $RESULT_DIR/$FILENAME --rledbat --to_pdf
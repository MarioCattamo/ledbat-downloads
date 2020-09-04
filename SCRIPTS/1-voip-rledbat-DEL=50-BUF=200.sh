#!/usr/bin/env bash

# Starts rLEDBAT in C1, C1 <-- S1 download
# Starts sending packets from S2 to C2, 160 bytes, one each 20ms, emulating 64kbps application
echo "Executing $0"

source experiment_configuration.sh

FILENAME='1-voip-rledbat-DEL=50-BUF=200'


# remove any previous state
# remove any previous state
if [ ! -z $(lsof -t -i:49000) ]
then
    kill $(lsof -t -i:49000)
fi
ssh S2 "pkill ping"

# echo
echo 'Installing rledbat modules in C1'
sudo $SRC_DIR/install_rledbat.sh


echo
echo 'Start tcpdump in R1'
ssh R1 "sudo pkill tcpdump"
# ssh R1 "sudo tcpdump -s96 -ieth0 port 80 or port 9000 -w $RESULT_DIR/$FILENAME.pcap 2>&1" &
ssh R1 "sudo tcpdump -s96 -ieth0 port 80 or port 9000 -w $RESULT_DIR/$FILENAME.pcap" &
sleep 2
echo

echo 'Start server side in S1 to be used by rledbat'
ssh S1 "sudo pkill nc"
ssh S1 "dd if=/dev/zero bs=1M count=100000000 | sudo nc -l 80 2>&1 &" &

echo
echo 'Start Voip traffic download C2 <-- S2:ping'
ssh S2 "sudo ping -i 0.02 -s 160 C2 > ~/S2.ping" &

echo 'Wait 30 s'
sleep 30


echo
echo 'Start rLEDBAT download C1:49000 <-- S1:80'
nc -dp 49000 S1 80 > /dev/null &

echo 'Wait 240 s'
sleep 240


echo
echo 'Finish' 
ssh R1 "sudo pkill tcpdump"
sleep 2
scp R1:$RESULT_DIR/$FILENAME.pcap $RESULT_DIR
ssh S2 "sudo pkill ping"
pkill nc
scp S2:~/S2.ping $RESULT_DIR/${FILENAME}_S2.ping

sleep 2
ssh S1 "sudo pkill dd"

echo
echo 'Parsing result files, generating pdf graphs'

# 20 ms interval
./plot_pings.py $RESULT_DIR/${FILENAME}_S2.ping 20 --to_pdf

echo 'Generating rate graph'
echo 'dst_port,time,length' > $RESULT_DIR/$FILENAME.rate_csv
tshark -Y 'tcp.dstport==49000' -t r -T fields -E separator=, -e tcp.dstport -e frame.time_relative -e ip.len -r $RESULT_DIR/$FILENAME.pcap >> $RESULT_DIR/$FILENAME.rate_csv

./plot_rate_csv.py $RESULT_DIR/$FILENAME --rledbat --to_pdf

echo 'Generating window size graph'
echo 'dst_port,time,window_size' > $RESULT_DIR/$FILENAME.window_csv
tshark -Y 'tcp.srcport==49000 ' -t r -T fields -E separator=, -e tcp.srcport -e frame.time_relative -e tcp.window_size_value -r $RESULT_DIR/$FILENAME.pcap >> $RESULT_DIR/$FILENAME.window_csv
./plot_window_csv.py $RESULT_DIR/$FILENAME --rledbat --to_pdf

echo 'Gathering rtt info graph for rLEDBAT log trace'
echo 'time,rtt,rtt_min' > $RESULT_DIR/$FILENAME.rtt_C1_csv
#awk '{print $(NF)}' /var/log/kern.log  | grep "read" | awk -F ";" '{if (FNR==2) time=$13; print ($12-time)/1000000000","$15/1000000000","$16/1000000000}' | tail -n +2 >> $RESULT_DIR/$FILENAME.rtt_C1_csv
./echo_rtt.sh >> $RESULT_DIR/$FILENAME.rtt_C1_csv

#./plot_rttmin_csv.sh $RESULT_DIR/$FILENAME.rtt_C1_csv --to_pdf
#./plot_rtt_csv.py $RESULT_DIR/$FILENAME.rtt_C1_csv --to_pdf


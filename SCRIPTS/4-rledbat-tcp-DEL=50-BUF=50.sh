#!/usr/bin/env bash


# Start rledbat C1 <-- S1
# Then TCP C2 <-- S2
# Buffer is BELOW rledbat target
echo "Executing $0"
source experiment_configuration.sh

FILENAME='4-rledbat-tcp-DEL=50-BUF=50'

# configure buffer in R1 <-- R2
ssh R2 "sudo tc qdisc replace dev eth0 root tbf latency 50ms burst 1514 rate $RATE"

# remove any previous state
# remove any previous state
if [ ! -z $(lsof -t -i:49000) ]
then
    kill $(lsof -t -i:49000)
fi
ssh S2 "sudo pkill ping"


echo 'Installing rledbat modules'
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

echo 'Start server side in S2 to be used by TCP'
ssh S2 "sudo pkill nc"
ssh S2 "dd if=/dev/zero bs=1M count=100000000 | nc -l 9000" &

sleep 10

echo
echo 'Start rledbat download C1:49000 <-- S1:80'
nc -dp 49000 S1 80 > /dev/null &

echo 'Wait 30 s'
sleep 30

echo
echo 'Start TCP download C2:50000 <-- S2:9000'
ssh C2 "nc -dp 50000 S2 9000 > /dev/null" &

echo 'Wait 180 s'
sleep 180

echo
echo 'Stop TCP'
echo 'wait 30 s'
ssh C2 "pkill nc"
sleep 30

echo 'Finish' 
ssh R1 "sudo pkill tcpdump"
sleep 2
scp R1:$RESULT_DIR/$FILENAME.pcap $RESULT_DIR
pkill nc

sleep 2
ssh S1 "sudo pkill nc"
ssh S2 "sudo pkill dd"

echo
echo 'Parsing result files, generating pdf graphs'
echo 'Generating rate graph'
echo 'dst_port,time,length' > $RESULT_DIR/$FILENAME.rate_csv
tshark -Y 'tcp.dstport==49000 || tcp.dstport==50000' -t r -T fields -E separator=, -e tcp.dstport -e frame.time_relative -e ip.len -r $RESULT_DIR/$FILENAME.pcap >> $RESULT_DIR/$FILENAME.rate_csv

./plot_rate_csv.py $RESULT_DIR/$FILENAME --rledbat --tcp --to_pdf --start_measure 40

echo 'Generating window size graph'
echo 'dst_port,time,window_size' > $RESULT_DIR/$FILENAME.window_csv
tshark -Y 'tcp.srcport==49000 || tcp.srcport==50000' -t r -T fields -E separator=, -e tcp.srcport -e frame.time_relative -e tcp.window_size_value -r $RESULT_DIR/$FILENAME.pcap >> $RESULT_DIR/$FILENAME.window_csv
./plot_window_csv.py $RESULT_DIR/$FILENAME --rledbat --to_pdf

echo 'Generating rtt graph for rLEDBAT log trace in C1'
echo 'time,rtt,rtt_min' > $RESULT_DIR/$FILENAME.rtt_C1_csv
./echo_rtt.sh >> $RESULT_DIR/$FILENAME.rtt_C1_csv

#./plot_rttmin_csv.sh $RESULT_DIR/$FILENAME.rtt_C1_csv --to_pdf
./plot_rtt_csv.py $RESULT_DIR/$FILENAME.rtt_C1_csv --to_pdf

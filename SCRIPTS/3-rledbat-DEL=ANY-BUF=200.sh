#!/usr/bin/env bash

# Starts rledbat in C1, C1 <-- S1 download. 
# Change one way delay for C1 <-- S1 as argument to the script
# ./3-rledbat-DEL=ANY-BUF=200.sh 175
# (note that C1 --> S1 always has a 25ms)
# Take into account the transmission delay (~12ms, applied both at S1 and at R1)

echo "Executing $0"

if [ -z "$1" ]
  then
    echo "No DELAY argument supplied (needs value in ms)"
    exit 1
fi

source experiment_configuration.sh

FILENAME="3-rledbat-DEL=$1-BUF=200"

# remove any previous state
# remove any previous state
if [ ! -z $(lsof -t -i:49000) ]
then
    kill $(lsof -t -i:49000)
fi
ssh S2 "sudo pkill ping"


# echo
echo 'Installing rledbat modules'
sudo $SRC_DIR/install_rledbat.sh


# Override standard configuration for delay R2->R1
ssh R1 "sudo tc qdisc replace dev eth1 root netem delay ${1}ms"


echo
echo 'Start tcpdump in R1'
# disable configurations that may gather many packets together in tcpdump

ssh R1 "sudo pkill tcpdump"
# ssh R1 "sudo tcpdump -s96 -ieth0 port 80 or port 9000 -w $RESULT_DIR/$FILENAME.pcap 2>&1" &
ssh R1 "sudo tcpdump -s96 -ieth0 port 80 or port 9000 -w $RESULT_DIR/$FILENAME.pcap" &
sleep 2
echo

echo 'Start server side in S1 to be used by rledbat'
ssh S1 "sudo pkill nc"
ssh S1 "dd if=/dev/zero bs=1M count=100000000 | sudo nc -l 80 2>&1 &" &

# ensure the other side is active
sleep 15

echo
echo 'Start rLEDBAT download C1:49000 <-- S1:80'
nc -dp 49000 S1 80 > /dev/null &

echo 'Wait 400 s'
sleep 400


echo
echo 'Finish' 
ssh R1 "sudo pkill tcpdump"
sleep 2
scp R1:$RESULT_DIR/$FILENAME.pcap $RESULT_DIR

pkill nc

sleep 2
ssh S1 "sudo pkill dd"

echo
echo 'Parsing result files, generating pdf graphs'


echo 'Generating rate graph'
echo 'dst_port,time,length' > $RESULT_DIR/$FILENAME.rate_csv
tshark -Y 'tcp.dstport==49000' -t r -T fields -E separator=, -e tcp.dstport -e frame.time_relative -e ip.len -r $RESULT_DIR/$FILENAME.pcap >> $RESULT_DIR/$FILENAME.rate_csv


echo '' >> 3.rledbat_RATES_since100s
./plot_rate_csv.py $RESULT_DIR/$FILENAME --rledbat --to_pdf --start_measure 10 >> 3.rledbat_RATES_since10s

echo 'Generating window size graph'
echo 'dst_port,time,window_size' > $RESULT_DIR/$FILENAME.window_csv
tshark -Y 'tcp.srcport==49000 ' -t r -T fields -E separator=, -e tcp.srcport -e frame.time_relative -e tcp.window_size_value -r $RESULT_DIR/$FILENAME.pcap >> $RESULT_DIR/$FILENAME.window_csv
./plot_window_csv.py $RESULT_DIR/$FILENAME --rledbat --to_pdf

echo 'Gathering rtt info graph for rLEDBAT log trace'
echo 'time,rtt,rtt_min' > $RESULT_DIR/$FILENAME.rtt_C1_csv
./echo_rtt.sh >> $RESULT_DIR/$FILENAME.rtt_C1_csv

#./plot_rttmin_csv.sh $RESULT_DIR/$FILENAME.rtt_C1_csv --to_pdf
./plot_rtt_csv.py $RESULT_DIR/$FILENAME.rtt_C1_csv --to_pdf


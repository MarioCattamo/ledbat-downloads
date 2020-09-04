# Configurations loaded by all experiment scripts

BASE_DIR="/home/ledbat/"
RESULT_DIR="$BASE_DIR/RESULTS/"
SCRIPT_DIR="$BASE_DIR/SCRIPTS/"
SRC_DIR="$BASE_DIR/SRC/"
RATE="1000kbit"



# experiment code must be executed in C1
function ensure_in_C1() {
    if [ "$HOSTNAME" != "C1" ]; then
        printf "Experiment must be executed in C1, exiting"
        exit 1
    fi
}

# code must be executed in C1
ensure_in_C1


echo
echo 'Basic network buffers and rate configuration'
RATE="1000kbit"
# configure buffer in R1 <-- R2
ssh R2 "sudo tc qdisc replace dev eth0 root tbf latency 200ms burst 1514 rate $RATE"
# configure delay in R2 --> R1
ssh R1 "sudo tc qdisc replace dev eth1 root netem delay 25ms"

# configure delay in C1->R1, C2->R2
sudo tc qdisc replace dev eth0 root netem delay 25ms
ssh C2 "sudo tc qdisc replace dev eth0 root netem delay 25ms"

# configure rate in R2 <-- S1, much bigger buffer
ssh S1 "sudo tc qdisc replace dev eth0 root tbf latency 1000ms burst 1514 rate $RATE"
# configure rate in R2 <-- S2, much bigger buffer
ssh S2 "sudo tc qdisc replace dev eth0 root tbf latency 1000ms burst 1514 rate $RATE"

# do not off-load packet packet processing to the card
ssh R1 "sudo ethtool -K eth0 gro off"
ssh R1 "sudo ethtool --offload  eth0  rx off  tx off"

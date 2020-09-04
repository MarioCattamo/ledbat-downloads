EXPERIMENTS:
Scripts assume the particular setup described in section 'Experiments' of 
'rLEDBAT: empowering clients to manage incoming traffic'.

All scripts must be executed in C1.
    C1 and C2 have directories ~/SRC, ~/SCRIPTS and ~/RESULTS
    Final results are left at C1:~/RESULTS

Start all virtual machines (C1, C2, R1, R2, S1, S2)
If sudo asks for pswd, use      it

Flows used in the experiment:
rledbat_1, C1:49000 <-- S1:80
rledbat_2, C2:49001 <-- S2:80
tcp,       C2:50000 <-- S2:9000

##################
Dependencies:
- tcpdump
- tshark
- tc
- sshd
- python3 (scipy.stats, numpy, matplotlib, pandas)


##################
EXPERIMENT SCRIPTS

0-measure-rate-RATE=1mbps.sh
    Generates flood pings from S2 to C2 to measure the maximum rate available 
    with the usual network configuration

1-voip-rledbat-DEL=50-BUF=200.sh
    Starts rLEDBAT in C1, C1 <-- S1 download
    Starts sending packets from S2 to C2, 160 bytes, one each 20ms, 
    emulating 64kbps application

2-rledbat-rledbat-DEL=50-BUF=200.sh
    Starts rLEDBAT in C1, C1 <-- S1 download
    Starts rLEDBAT in C2, C2 <-- S2 download

3-rledbat-DEL=ANY-BUF=200.sh
    Starts rledbat in C1, C1 <-- S1 download. 
    Change one way delay for C1 <-- S1 as argument to the script
    ./3-rledbat-DEL=ANY-BUF=200.sh 175
    (note that C1 --> S1 always has a 25ms)
    Take into account the transmission delay (~12ms, applied both at S1 and at R1)

4-rledbat-tcp-DEL=50-BUF=200.sh
    Start rledbat C1 <-- S1
    Then TCP C2 <-- S2
    Buffer is BELOW rledbat target

4-rledbat-tcp-DEL=50-BUF=50.sh
    Start rledbat C1 <-- S1
    Then TCP C2 <-- S2
    Buffer is OVER rledbat target

4-tcp-rledbat-DEL=50-BUF=200.sh
    Start TCP C2 <-- S2
    Then rledbat C1 <-- S1
    Buffer is over rledbat target

COMMON FILE for experiment scripts
experiment_configuration.sh   
    Common configurations for all the experiments: directories, basic delay/buffer configuration
    Loaded by all experiment scripts


####################
UTILITIES
plot_rate_csv.py     
    Plots rate values over time from data extracted from tcpdump capture

plot_window_csv.py
    Plots receive window values over time from data extracted from tcpdump capture

plot_rtt_csv.py   
    Plots rtt values over time from data extracted from rLEDBAT kernel module traces

plot_rttmin_csv.py
    Plots MIN rtt values over time from data extracted from rLEDBAT kernel module traces

plot_pings.py
    Plot rtt time measured from ping output

echo_rtt.sh
    One-liner to parse rtt from rLEDBAT kernel module traces


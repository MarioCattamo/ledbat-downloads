

# quick way of testing plot scripts are working

# source ./experiment_configuration.sh


./plot_pings.py ../RESULTS/2-rledbat-rledbat-DEL=50-BUF=200_S2.ping 20
./plot_rate_csv.py ../RESULTS/2-rledbat-rledbat-DEL=50-BUF=200.rate_csv --rledbat --rledbat2
./plot_window_csv.py ../RESULTS/2-rledbat-rledbat-DEL=50-BUF=200.window_csv --rledbat --rledbat2
./plot_rtt_csv.py ../RESULTS/2-rledbat-rledbat-DEL=50-BUF=200.rtt_C1_csv
./plot_rttmin_csv.py ../RESULTS/2-rledbat-rledbat-DEL=50-BUF=200.rtt_C1_csv
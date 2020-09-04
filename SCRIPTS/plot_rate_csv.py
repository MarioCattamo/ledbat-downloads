#!/usr/bin/env python3

# Plots the bandwidth of a csv file (must have extension .rate_csv)
# Separates flows according to ports in csv file
#
# Example of use
#   generate input file from .pcap traces
# echo 'dst_port,time,length' > $RESULT_DIR/$FILENAME.rate_csv
# tshark -Y 'tcp.dstport==49000' -t r -T fields -E separator=, -e tcp.dstport -e frame.time_relative -e ip.len -r $RESULT_DIR/$FILENAME.pcap >> exp1.rate_csv
#   plot file, selecting flows to plot (--rledbat, etc.)
# ./plot_rate_csv.py exp1.rate_csv --rledbat

# import pyshark
from argparse import ArgumentParser
import scipy.stats
import numpy as np
import matplotlib.pyplot as plt

import pandas as pd

import warnings
# ignore warnings from binned_statistic
warnings.simplefilter(action='ignore', category=FutureWarning)



def plot_flow_rate(capture_df, first_timestamp, bin_size, label_fig, color_fig, rate_start_measure, rate_stop_measure, dash=False):
    bins = np.arange(float(first_timestamp), float(last_timestamp), args.bin_size)

    bin_sums, bin_edges, bin_number = scipy.stats.binned_statistic(capture_df['time'], capture_df['length'],  'sum', bins)

    # normalize speed to the size of the bin and to bits
    bin_sums = bin_sums*8/bin_size/1000
    #plt.plot(bin_edges[:-1], bin_sums, label=label_fig, color=color_fig)
    if dash:
        plt.plot(bin_edges[:-1], bin_sums, linestyle=(0, (1, 1)), label=label_fig, color=color_fig, linewidth=1)
    else:
        plt.plot(bin_edges[:-1], bin_sums, label=label_fig, color=color_fig,  linewidth=1)

    # compute mean rate
    capture_df = capture_df[capture_df['time']> rate_start_measure]
    capture_df = capture_df[capture_df['time']< rate_stop_measure]
    total_time = capture_df['time'].iloc[-1] - capture_df['time'].iloc[0]
    rate_kbps = sum(capture_df['length'])*8/(total_time*1000.0)
    print('Mean rate for {}, measurement during ({},{}): {}kbps'.format(label_fig, rate_start_measure, rate_stop_measure, rate_kbps))


# CLI
if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("file_name", help=".pcap filename - admit both ending in '.pcap' or not")
    parser.add_argument("--to_pdf", help='writes to a pdf with the same filename as the pcap file', action='store_true')
    parser.add_argument("--width", help="figure's width for matplotlib", default=-1.0, type=float)
    parser.add_argument("--height", help="figure's height for matplotlib", default=-1.0, type=float)
    parser.add_argument('--rledbat', help="plots rledbat trace (port 49000)", action='store_true')
    parser.add_argument('--rledbat2', help="plots rledbat2 trace (port 49001)", action='store_true')

    parser.add_argument('--tcp', help="plots rledbat2 trace (port 50000)",action='store_true')
    parser.add_argument('--ledbat', help="plots ledbat++ trace (port 51000)",action='store_true')
    parser.add_argument('--aggregate', help='Plots aggregate rate for all types of traffic, only traffic received by clients',  action='store_true')

    parser.add_argument("--bin_size", help="time in seconds to aggregate data to compute rate", default=1.0, type=float)

    parser.add_argument("--start_measure", help="time in seconds to START measuring rate (for aggregate rate)", default=-1.0, type=float)
    parser.add_argument("--stop_measure", help="time in seconds to STOP measuring rate (for aggregate rate)", default=100000.0, type=float)
    parser.add_argument("--stop_plotting", help="time in seconds to STOP plotting rate (for aggregate rate)", default=100000.0, type=float)


    args= parser.parse_args()
    if args.file_name.endswith('.pcap'):
        print('Not able to process pcap files')
        exit(1)
    elif args.file_name.endswith('.rate_csv'):
        file_name = args.file_name
    else:
        file_name = args.file_name + '.rate_csv'

    if (not args.rledbat) and (not args.rledbat2) and (not args.tcp) and (not args.ledbat) and (not args.aggregate):
        print("No type of traffic selected (rledbat, rledbat2, tcp or ledbat). Exiting")
        exit(1)

    # 'dst_port,time,length'
    capture = pd.read_csv(file_name)
    capture = capture[capture['time']< args.stop_plotting]

    first_timestamp = capture['time'][0]
    capture['time'] = capture['time'] - first_timestamp

    last_timestamp = capture.tail(1)['time']

    width = args.width
    height = args.height
    if width < 0.0:
        width = 5.0 * (float(last_timestamp)-float(first_timestamp))/100.0
        width = min(5.0, width)
    if height < 0.0:
        height = 3.2
    plt.figure(figsize=(width, height))

    if args.aggregate:
        aggregate = capture[(capture['dst_port']==49000) | (capture['dst_port']==49001) | (capture['dst_port']==49002) | (capture['dst_port']== 50000) | (capture['dst_port']==51000)]
        if len(aggregate) == 0:
            print('aggregate selected, but there was no traffic for it')
            exit(1)
        plot_flow_rate(aggregate, aggregate['time'].iloc[0], args.bin_size, 'Aggregate traffic', 'cyan', args.start_measure, args.stop_measure, dash=True)

    if args.rledbat:
        rledbat = capture[capture['dst_port']==49000]
        if len(rledbat) == 0:
            print('rledbat selected, but there was no traffic for it')
            exit(1)
        plot_flow_rate(rledbat, rledbat['time'].iloc[0], args.bin_size, 'rLEDBAT', 'red', args.start_measure, args.stop_measure)
    if args.rledbat2:
        rledbat2 = capture[capture['dst_port']==49001]
        if len(rledbat2) == 0:
            print('rledbat2 selected, but there was no traffic for it')
            exit(1)
        plot_flow_rate(rledbat2, rledbat2['time'].iloc[0], args.bin_size, 'rLEDBAT_2', 'blue', args.start_measure, args.stop_measure, dash=True)
    if args.tcp:
        tcp = capture[capture['dst_port']==50000]
        if len(tcp) == 0:
            print('tcp selected, but there was no traffic for it')
            exit(1)
        plot_flow_rate(tcp, tcp['time'].iloc[0], args.bin_size, 'TCP', 'black', args.start_measure, args.stop_measure, dash=True)
    if args.ledbat:
        ledbat = capture[capture['dst_port']==51000]
        if len(ledbat) == 0:
            print('ledbat selected, but there was no traffic for it')
            exit(1)
        plot_flow_rate(ledbat, ledbat['time'].iloc[0], args.bin_size, 'LEDBAT++', 'green', args.start_measure, args.stop_measure)




    plt.xlabel('Time (seconds)')
    plt.ylabel('Rate (kbps)')

    print()
    if (args.rledbat + args.rledbat2 + args.ledbat + args.aggregate + args.tcp >1):
        # for 2.rledbat-rledbat... :
        plt.legend(loc='lower right')
        # for 4-rledbat-tcp
        #plt.legend(loc="center")
        #plt.legend( bbox_to_anchor=(1, 0.6))
    plt.ylim(ymin=-3)



    plt.tight_layout()
    if args.to_pdf:
        # removes .pcap from filename, add .pdf
        pdf_filename = file_name.replace('.rate_csv', '') + '_rate.pdf'
        plt.savefig(pdf_filename, format='pdf')
        print('Saved to file {}'.format(pdf_filename))
    else:
        plt.show()

    # number is the bin duration in seconds
    #plot_bandwidth_cap_file(file_name, 1, args.to_pdf, args.width, args.height)

    
        
    
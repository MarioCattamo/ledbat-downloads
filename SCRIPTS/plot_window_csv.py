#!/usr/bin/env python3

# Plots the window as taken from a csv file (.window_csv)
# Separates flows according to ports in csv file
# 
# # Example of use
#   generate input file from .pcap traces
# echo 'dst_port,time,window_size' > $RESULT_DIR/$FILENAME.window_csv
#tshark -Y 'tcp.srcport==49000 || tcp.srcport==49001' -t r -T fields -E separator=, -e tcp.srcport -e frame.time_relative -e tcp.window_size_value -r $RESULT_DIR/$FILENAME.pcap >> exp1.window_csv
#   plot file, selecting flows to plot (--rledbat, etc.)
# ./plot_rate_csv.py exp1.rate_csv --rledbat --rledbat2

# import pyshark
from argparse import ArgumentParser
#import scipy.stats
import numpy as np
import matplotlib.pyplot as plt

import pandas as pd

import warnings
# ignore warnings from binned_statistic
warnings.simplefilter(action='ignore', category=FutureWarning)



def plot_flow_window(capture_df, label_fig, color_fig, max_time, dash=False):
    capture_df = capture_df[capture_df['time'] < max_time]
    plt.scatter(capture_df['time'], capture_df['window_size']/1000.0, s=0.5, label=label_fig, color=color_fig, marker='.')    


# CLI
if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("file_name", help="Window csv filename - admit either ending in '.window_csv' or not")
    parser.add_argument("--to_pdf", help='writes to a pdf with the same filename as the pcap file', action='store_true')
    parser.add_argument("--width", help="figure's width for matplotlib", default=-1.0, type=float)
    parser.add_argument("--height", help="figure's height for matplotlib", default=-1.0, type=float)
    parser.add_argument('--rledbat', action='store_true')
    parser.add_argument('--rledbat2', action='store_true')
    parser.add_argument('--rledbat3', action='store_true')
    parser.add_argument('--ledbat', action='store_true')
    parser.add_argument("--max_time", help="max time to plot", default=100000.0, type=float)


    # parser.add_argument("--bin_size", help="time in seconds to aggregate data to compute rate", default=1.0, type=float)

    args= parser.parse_args()
    if args.file_name.endswith('.pcap'):
        print('Not able to process pcap files')
        exit(1)
    elif args.file_name.endswith('.window_csv'):
        file_name = args.file_name
    else:
        file_name = args.file_name + '.window_csv'

    if (not args.rledbat) and (not args.rledbat2) and (not args.rledbat3) and (not args.ledbat) :
        print("No type of traffic selected (rledbat, rledbat2, tcp or ledbat). Exiting")
        exit(1)

    # 'dst_port,time,window_size'
    capture = pd.read_csv(file_name)

    first_timestamp = capture['time'][0]
    # capture['time'] = capture['time'] - first_timestamp
    last_timestamp = capture.tail(1)['time']

    width = args.width
    height = args.height
    if width < 0.0:
        width = 7.0 * (float(last_timestamp)-float(first_timestamp))/100.0
        width = min(8.0, width)
    if height < 0.0:
        height = 3.5
    plt.figure(figsize=(width, height))

        
    if args.rledbat:
        rledbat = capture[capture['dst_port']==49000]
        if len(rledbat) == 0:
            print('rledbat selected, but there was no traffic for it')
            exit(1)
        plot_flow_window(rledbat, 'rLEDBAT', 'red', args.max_time)
    if args.rledbat2:
        rledbat2 = capture[capture['dst_port']==49001]
        if len(rledbat2) == 0:
            print('rledbat2 selected, but there was no traffic for it')
            exit(1)
        plot_flow_window(rledbat2, 'rLEDBAT_2', 'blue', args.max_time)
    if args.rledbat3:
        rledbat3 = capture[capture['dst_port']==49002]
        if len(rledbat3) == 0:
            print('rledbat3 selected, but there was no traffic for it')
            exit(1)
        plot_flow_window(rledbat3, 'rLEDBAT_3', 'blue', args.max_time)
    if args.ledbat:
        ledbat = capture[capture['dst_port']==51000]
        if len(ledbat) == 0:
            print('ledbat selected, but there was no traffic for it')
            exit(1)
        plot_flow_window(ledbat, 'LEDBAT++', 'green', args.max_time)



    plt.xlabel('Time (seconds)')
    plt.ylabel('Window (kBytes)')
    # only show legend if there are more than one entries
    if args.rledbat and (args.rledbat2 or args.ledbat):
        lgnd =plt.legend()
        for handle in lgnd.legendHandles:
            handle.set_sizes([40.0])
    plt.ylim(ymin=0.0)



    # plt.tight_layout()
    if args.to_pdf:
        # removes .pcap from filename, add .pdf
        pdf_filename = file_name.replace('.window_csv', '') + '_window.pdf'
        plt.savefig(pdf_filename, format='pdf')
        print('Saved to file {}'.format(pdf_filename))
    else:
        plt.show()

    # number is the bin duration in seconds
    #plot_bandwidth_cap_file(file_name, 1, args.to_pdf, args.width, args.height)

    
        
    
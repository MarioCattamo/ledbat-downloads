#!/usr/bin/env python3


# plot rtt time measured from ping output
# ./plot_pings file.ping pingIntervalMs
#   pingIntervalMs in ms
# Example of use
#   ping request every 20 ms
# sudo ping -i 0.02 -s 160 C2 > ~/S2.ping
#   plot file, indicate the ping interval was 20 ms, write to file
# ./plot_ping S2.ping 20 --to_pdf


import numpy as np
import matplotlib.pyplot as plt
from argparse import ArgumentParser


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("filename", help=".ping filename")
    parser.add_argument("ping_interval", help="interval between pings, in ms")

    parser.add_argument("--to_pdf", help='writes to a pdf with the same filename as the pcap file', action='store_true')
    parser.add_argument("--width", help="figure's width for matplotlib", default=-1.0, type=float)
    parser.add_argument("--height", help="figure's height for matplotlib", default=-1.0, type=float)

    parser.add_argument("--time_threshold", help="to compute how many packets are below a given threshold", default=170.0, type=float)
    
    args= parser.parse_args()

    with open(args.filename) as f:
        ping_lines = f.readlines()
    # you may also want to remove whitespace characters like `\n` at the end of each line
    ping_lines = [x.strip() for x in ping_lines] 

    time_pings=[]

    ping_lines.pop(0)
    for ping_line in ping_lines:
        components = ping_line.split(' ')
        time_expression = components[-2]
        time_ping = time_expression.replace('time=', '')
        time_pings.append(float(time_ping))

    x = np.arange(0, len(time_pings))
    x = x*float(args.ping_interval)/1000.0

    width = args.width
    height = args.height
    if width < 0.0:
        width = 5
    if height < 0.0:
        height = 2.5
    plt.figure(figsize=(width, height))


    plt.scatter(x, time_pings, marker='.', s=5, color='black')
    # set lower limit, 0 is depicted, must be AFTER the plot (or it prevents autoscaling for the upper value)
    plt.ylim(bottom=0)
    plt.ylabel('RTT (ms)')
    plt.xlabel('Experiment duration (s)')


    plt.tight_layout()
    if args.to_pdf:
        # removes .pcap from filename, add .pdf
        pdf_filename = args.filename.replace('.ping', '')+ '_ping.pdf'
        plt.savefig(pdf_filename, format='pdf')
        print('Saved to file {}'.format(pdf_filename))
    else:
        plt.show()

    number_packets = len(time_pings)
    packets_below_thr = 0
    for i in range(number_packets):
        if time_pings[i] < args.time_threshold:
            packets_below_thr = packets_below_thr +1
    print('Number of packets: {}'.format(number_packets))
    print('... of those, below thr: {} (fraction {})'.format(packets_below_thr, packets_below_thr/number_packets))

# Authors: Alberto Garcia (alberto it.uc3m.es), Anna Mandalari (amandala it.uc3m.es)
# Licensed as GPL3.0 (gpl-3.0)
import subprocess
import os
import pystatsd
import time

stats_client = pystatsd.Client(os.environ.get('STATSD_HOST', '127.0.0.1'), 8125)

# This is not ideal, but whatever. Originally I had this at 0.5 sec interval, but it wasnt worth it
# and my Netgear router was whining about ICMP floods.
process = subprocess.Popen(
    ["ping", '-i', '1.0', '8.8.8.8'],
    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

seen_seq = 1
loop_iter = 0
for line in iter(process.stdout.readline, ''):
    if 'bytes from' in line:
        loop_iter += 1

        chunks = line.rstrip().split()
        print line.rstrip()
        latency = int(float(chunks[-2].split('=')[-1]))
        # ping2 because the first version of this script was JANK
        stats_client.gauge('ping2.latency.8_8_8_8', latency)
        stats_client.timing('ping2.latency.8_8_8_8', latency)

        seen_seq = int(chunks[4].split('=')[-1])
        
        # if you have ever ran `ping 8.8.8.8` on Linux, you know it prints
        # one log line per received packet. if you miss a ton, you just dont get any
        # with a much higher icmp_seq number, like:
        # PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
        # 64 bytes from 8.8.8.8: icmp_seq=1 ttl=52 time=36.4 ms
        # 64 bytes from 8.8.8.8: icmp_seq=2 ttl=52 time=24.6 ms
        # 64 bytes from 8.8.8.8: icmp_seq=7 ttl=52 time=22.2 ms
        # ^C
        #
        # As a result, the statsd counter for number of timeouts is not really accurate
        # but rather a signal of "there was icmp packet loss" combined with no ping2.latency.8_8_8_8
        # timers for a bit.
        if seen_seq != loop_iter:
            loop_iter = seen_seq

            stats_client.incr('ping2.timeout.8_8_8_8', 1)
            print 'Seen a lost packet'
        seen_seq = 1

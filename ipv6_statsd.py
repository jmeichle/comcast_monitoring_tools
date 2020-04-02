#!/usr/bin/env python

import os
import pystatsd
import time
import socket
import traceback

stats_client = pystatsd.Client(os.environ.get('STATSD_HOST', '127.0.0.1'), 8125)

# Via `curl -v google.com` on an IPv6 dual-stack host one time randomly.
google_ipv6_http_endpoint_address = ('2607:f8b0:4006:81a::200e', 80)

while True:
    start_time = time.time()
    try:
        ipv6_socket = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
        ipv6_socket.settimeout(5)
        ipv6_socket.connect(google_ipv6_http_endpoint_address)
        end_time = time.time()
        connect_time_in_ms = int(1000 * (end_time - start_time))
        print 'connected after {}ms'.format(connect_time_in_ms)
        stats_client.timing('ipv6.connect_timing.google_http_endpoint', connect_time_in_ms)
    except: # I dont really care about treating socket timeouts and other socket errors separately. At the end of the day, the internet is broken.
        end_time = time.time()
        exception_time_in_ms = int(1000 * (end_time - start_time))
        print 'caught an exception after {}ms'.format(exception_time_in_ms)
        stats_client.incr('ipv6.connect_timeout.google_http_endpoint', 1)
    finally:
        ipv6_socket.close()
    time.sleep(1)
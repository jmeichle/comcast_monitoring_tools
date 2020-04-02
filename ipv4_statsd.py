#!/usr/bin/env python

import os
import pystatsd
import time
import socket
import traceback

stats_client = pystatsd.Client(os.environ.get('STATSD_HOST', '127.0.0.1'), 8125)

# Via `dig ipv4.google.com` for ipv4.l.google.com
google_ipv4_http_endpoint_address = ('172.217.11.46', 80)

while True:
    start_time = time.time()
    try:
        ipv4_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ipv4_socket.settimeout(5)
        ipv4_socket.connect(google_ipv4_http_endpoint_address)
        end_time = time.time()
        connect_time_in_ms = int(1000 * (end_time - start_time))
        print 'connected after {}ms'.format(connect_time_in_ms)
        stats_client.timing('ipv4.connect_timing.google_http_endpoint', connect_time_in_ms)
    except Exception as exc: # I dont really care about treating socket timeouts and other socket errors separately. At the end of the day, the internet is broken.
        traceback.print_exc()
        end_time = time.time()
        exception_time_in_ms = int(1000 * (end_time - start_time))
        print 'caught an exception after {}ms'.format(exception_time_in_ms)
        stats_client.incr('ipv4.connect_timeout.google_http_endpoint', 1)
    finally:
        ipv4_socket.close()
    time.sleep(1)

#!/bin/bash

# hopefully none of this is needed long enough that GNU screen as a process manager actually becomes "bad"

screen -S icmp_statsd -dm bash -c 'python icmp_statsd.py'
screen -S ipv4_statsd -dm bash -c 'python ipv4_statsd.py'
screen -S ipv6_statsd -dm bash -c 'python ipv6_statsd.py'

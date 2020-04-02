# comcast_monitoring_tools

## What is this repo:

![Graphs!](https://github.com/jmeichle/comcast_monitoring_tools/blob/master/_images/look_at_this_graph.gif?raw=true)

```
3 python scripts that give better visibility into Comcast
Xfinity status than a 184,000 person company
```

Note: this code is awful, but does what it needs to. It is not a reflection of bulletproof monitoring, but instead a means to gain visibility into different network behaviors.

Also: It's fun to play wack-a-mole with github while your internet is down over and over.

## How do I run this

1. Have a linux machine with docker, python 2 (yes yes, my NAS linux server is old), and GNU screen available.
1. Launch graphite + grafana docker, for storing metrics. Its an old image with an outdated grafana, but works well enough for a bootleg monitoring dashboard

```bash
docker run -i -d -p 3000:80 -p 3001:81 -p 8125:8125/udp -p 8126:8126 -p 2003:2003 kamon/grafana_graphite
```

1. Launch the three dumb python scripts

Then:

```bash
bash start_things.sh
```

and observe the screens:

```
jmeichle@server:~/comcast_monitoring_tools$ bash start_things.sh
jmeichle@server:~/comcast_monitoring_tools$ screen -ls
There are screens on:
    15983.ipv6_statsd   (04/01/2020 11:13:21 PM)    (Detached)
    15980.ipv4_statsd   (04/01/2020 11:13:21 PM)    (Detached)
    15977.icmp_statsd   (04/01/2020 11:13:21 PM)    (Detached)
3 Sockets in /var/run/screen/S-jmeichle.
```

## Why?

Entering the third week of COVID-19 self quarantining / social distancing, I've been working from home during the days and maintaining usual activities in the evenings such as (trying) to play some games to stay in contact with people.

I live in Saugus MA, and at least for my street, Comcast Xfinity is the only option for high speed internet other than Verizon DSL (quoted at a blazing 1.5-3 Mbps) or satellite internet.

As of Tuesday, March 24th, about a week and a half into being home my comcast connection started showing signs of instability. The next day, it cut abruptly mid-day and I spotted a xfinity truck working on the pole across the street where my service is attached to. Service has been degrading ever since then. In my boredom, I have started building my own monitoring because why not.

I started with the icmp metrics a few days ago and its been fascinating. Tonight has been particularly awful:

![ICMP latency and rough packet loss for 2020-04-01 evening](https://github.com/jmeichle/comcast_monitoring_tools/blob/master/_images/2020-04-01_23:10:00_ICMP.png?raw=true)

So I wrote the IPv4 and IPv6 scripts.

## Seen things

- Router reboots doing nothing, despite causing their own 10 min interruption
- Periods of time (5-30 minutes) of total disconnection. Nothing works, not ICMP, IPv4, or IPv6
- Periods of time where IPv4+IPv6 work fine, but ICMP does not
- Periods of time where IPv4 is broken, but ICMP+IPv6 work great (thanks Google for having IPv6 support)
- All xfinity account pages indicate "service is healthy"
- All communications with comcast, where they issue health probes pass, despite being within an active outage
- Attempts to get in contact with an agent fail due to system errors within comcast

## Next steps

- Wait for comcast to fix things, or at least admit that they are having issues to their customers / public
- *stay indoors*
- Run the IPv4 and IPv6 scrapers for a bit, and update this repo with more fun screenshots
- Xbox over T-Mobile wifi gives ~30ms ping, which is nice


## Screenshots

Here is a view for the first 2 hours since running all three scripts, showing the tail end of the evening as people wind down their usages:

![ICMP, IPv4, and IPv6 connectivity](https://github.com/jmeichle/comcast_monitoring_tools/blob/master/_images/2020-04-01_23:20:00_to_2020-04-02_01:20:00_ICMP_IPv4_IPv6.png?raw=true)


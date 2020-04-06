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


## Screenshots and Updates

Here is a view for the first 2 hours since running all three scripts, showing the tail end of the evening as people wind down their usages:

![ICMP, IPv4, and IPv6 connectivity](https://github.com/jmeichle/comcast_monitoring_tools/blob/master/_images/2020-04-01_23:20:00_to_2020-04-02_01:20:00_ICMP_IPv4_IPv6.png?raw=true)

Here we see an example where IPv4 connectivity was lost for ~18 minutes, with no real impact to ICMP or IPv6 connectivity. Connecitivty was confirmed by Gmail, Google Drive, etc all continuing to work over IPv6.

![IPv4 only outage](https://github.com/jmeichle/comcast_monitoring_tools/blob/master/_images/2020-04-02_13:40:00_to_2020-04-02_14:30:00_ICMP_IPv4_IPv6.png?raw=true)

## Adventure with `ipip6` IP tunnels

With Linux you can setup an IPv4 over IPv6 tunnel pretty easily using the iproute2 command and a few kernel modules loaded. This technology originated back in 1997 via [RFC2003](https://tools.ietf.org/html/rfc2003) and has since been extended for IPv6 support instead of just IPv4 over IPv4, etc.. 

These tunnels are very lightweight in that they are simply an extra IP packet header/enapsulation, unlike other VPN technologies which proxy traffic over a long lived TCP connection (such as OpenVPN). They are usable for point to point communications or for connecting separate IP networks via an IPv6 link.

I wanted to experiment with a lightweight IPv4 over IPv6 implementation, where I would probably have to setup NAT (and port address translation) to use an ipip6 tunnel as a default ipv4 route for my laptop. The reason for this is: IPv4 connection establishment has been sporadic with Comcast over the last week, but IPv6 has been considerably more stable. if IPv4 is tunneled over IPv6, mabye things will work better.

I spent some time today and spun up an AWS instance in us-east-1 fully configured for IPv6, and started learning how to setup these tunnels. After a while of no apparent progress, it dawned on me that comcast is actually blocking egress IPIP encapsulated traffic from my connection.

My test setup, in which the Terraform for spinning up the EC2 side of things lives here: [terraform/aws_vpc_ipv6_instance](https://github.com/jmeichle/comcast_monitoring_tools/tree/master/terraform/aws_vpc_ipv6_instance)

- EC2 instance with IPv6 address `2600:1f18:c35:200:9789:1817:ec2d:f355` and a very permissive security group firewall, allowing all traffic.
- My laptop, running at `aaaa:bbbb:cccc:dddd:7c7d:7588:8d04:6cff`

And then setup on the AWS instance:

```
root@ip-10-0-0-28:~# modprobe tunnel6 && modprobe xfrm6_tunnel && modprobe ip6_tunnel
root@ip-10-0-0-28:~# HOST_A_IPV6="2600:1f18:c35:200:9789:1817:ec2d:f355"
root@ip-10-0-0-28:~# HOST_B_IPV6="aaaa:bbbb:cccc:dddd:7c7d:7588:8d04:6cff"
root@ip-10-0-0-28:~# ip link add name ipip6 type ip6tnl mode ipip6 local $HOST_A_IPV6 remote $HOST_B_IPV6
root@ip-10-0-0-28:~# ip addr add dev ipip6 172.16.0.1/24
root@ip-10-0-0-28:~# ip link set dev ipip6 up
root@ip-10-0-0-28:~# ip link show ipip6
4: ipip6@NONE: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 8953 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/tunnel6 2600:1f18:c35:200:9789:1817:ec2d:f355 peer aaaa:bbbb:cccc:dddd:7c7d:7588:8d04:6cff
root@ip-10-0-0-28:~# ip addr show ipip6
4: ipip6@NONE: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 8953 qdisc noqueue state UNKNOWN group default qlen 1000
    link/tunnel6 2600:1f18:c35:200:9789:1817:ec2d:f355 peer aaaa:bbbb:cccc:dddd:7c7d:7588:8d04:6cff
    inet 172.16.0.1/24 scope global ipip6
       valid_lft forever preferred_lft forever
    inet6 fe80::6013:d9ff:fedf:c358/64 scope link
       valid_lft forever preferred_lft forever
```

And my laptop:

```
root@jmeichle-XPS-15-9570:~# HOST_A_IPV6="2600:1f18:c35:200:9789:1817:ec2d:f355"
root@jmeichle-XPS-15-9570:~# HOST_B_IPV6="aaaa:bbbb:cccc:dddd:7c7d:7588:8d04:6cff"
root@jmeichle-XPS-15-9570:~# ip link add name ipip6 type ip6tnl mode ipip6 local $HOST_B_IPV6 remote $HOST_A_IPV6
root@jmeichle-XPS-15-9570:~# ip addr add dev ipip6 172.16.0.2/24
root@jmeichle-XPS-15-9570:~# ip link set dev ipip6 up
[klaviyo-loadtest] jmeichle@jmeichle-XPS-15-9570:~/klaviyo/infrastructure-deployment$ ip link show ipip6
16: ipip6@NONE: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1452 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/tunnel6 aaaa:bbbb:cccc:dddd:7c7d:7588:8d04:6cff peer 2600:1f18:c35:200:9789:1817:ec2d:f355
[klaviyo-loadtest] jmeichle@jmeichle-XPS-15-9570:~/klaviyo/infrastructure-deployment$ ip addr show ipip6
16: ipip6@NONE: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1452 qdisc noqueue state UNKNOWN group default qlen 1000
    link/tunnel6 aaaa:bbbb:cccc:dddd:7c7d:7588:8d04:6cff peer 2600:1f18:c35:200:9789:1817:ec2d:f355
    inet 172.16.0.2/24 scope global ipip6
       valid_lft forever preferred_lft forever
    inet6 fe80::1497:c6ff:feff:673f/64 scope link
       valid_lft forever preferred_lft forever
```

However, when performing performing an ICMP ping from my laptop of the AWS instance over the tunnel, via `172.16.0.1`, I get no response. When running a packet capture I can see the `ipip6` encapsulation is correct but no response is received.

![Sent IPv4 over IPv6 ICMP Echo Request](https://github.com/jmeichle/comcast_monitoring_tools/blob/master/_images/1-laptop_pinging_aws_instance_via_ipip6_tunnel.jpg?raw=true)

and a capture on the AWS side shows no packets arrive at all.

When pinging from the AWS instance to my laptop over this tunnel my laptop receives the ICMP echo request with the IPv6 and encapsulated IPv4 header, and attempts to send the echo response.

![Received IPv4 over IPv6 ICMP Echo Request, and Echo Reply](https://github.com/jmeichle/comcast_monitoring_tools/blob/master/_images/2-aws_instance_pinging_laptop_via_ipip6_tunnel.jpg?raw=true)

To rule out a misconfiguration within AWS, I spun up a second IPv6 instance in the us-west-2 region and did the same configuration and everything worked fine.

I can find no public documentation from Comcast that they block IPv4 over IPv6 packets when being sent, but not received. This could be them blocking IP protocol 94 (IP-IP) or IP protocol 60 (IPv6 option extensions). As expected, comcast support had no context to provide. The closest I could find was:

- https://business.comcast.com/help-and-support/internet/ports-blocked-on-comcast-network/ which only references TCP/UDP port numbers, and nothing about encapsulation protocols
- https://www.xfinity.com/support/articles/using-a-vpn-connection which cites that comcast supports VPNs.

Oh well, I figured this could be a fun experiment to setup an IPv4 over IPv6 tunnel to an EC2 instance acting as a NAT gateway, and then either connecting my work laptop so services such as Slack wont be impacted when IPv4 connectivity is dropped, or by adding a Ethernet NIC to my laptop and having it act as a NAT router to the tunnel for my Xbox for any IPv4 connections.

Overkill? yes. A way to learn new (old) tech? yes. If I end up doing something like that It'll have to be something like OpenVPN since comcast does not block outbound TCP over IPv4 or IPv6 .... yet. 

## Instance setup

NOTE: Run everything as root.


1. Load some kernel modules. This is probably more than needed but /shrug
```
modprobe tunnel6
modprobe xfrm6_tunnel
modprobe ip6_tunnel
```

1. Enable IP forwarding. Also probably not needed but the intent was to configure the instance as a PNAT router for the received IPIP6 encapsulated traffic.

```
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
```

1. Allow IP over IP encapsulation within iptables. Might not be needed
```
# proto 94 == IP-within-IP Encapsulation Protocol
iptables -A INPUT -p 94 -j ACCEPT 
ip6tables -A INPUT -p 94 -j ACCEPT 
iptables -A OUTPUT -p 4 -j ACCEPT
ip6tables -A OUTPUT -p 4 -j ACCEPT
```

1. Gather IPv6 IP of host A, and host B

1. Configure host A for the tunnel.
server

```
ip link add name ipv4overipv6dev0 type ip6tnl mode ipip6 local $HOST_A_IPV6 remote $HOST_B_IPV6
ip addr add dev ipv4overipv6dev0 172.16.0.1/24
ip link set dev ipv4overipv6dev0 up
ip route add 172.16.0.2 dev ipv4overipv6dev0
```

1. Configure host B for the tunnel:

```
ip link add name ipv4overipv6dev0 type ip6tnl mode ipip6 local $HOST_B_IPV6 remote $HOST_A_IPV6
ip addr add dev ipv4overipv6dev0 172.16.0.2/24
ip link set dev ipv4overipv6dev0 up
```

1. ICMP ping the virtual IPv4 address of Host B from Host A:

```
host_a $ ping 172.16.0.2
```

1. ICMP ping the virtual IPv4 address of Host A from Host B:

```
host_a $ ping 172.16.0.1
```

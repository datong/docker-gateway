#!/bin/sh
ss_server=$(grep '"server":' /root/config.json | awk -F'"' '{print $4}')
echo $ss_server
func_get_reserved_ip_addr() {
	cat <<-EOF
	        $ss_server
		0.0.0.0/8
		10.0.0.0/8
		100.64.0.0/10
		127.0.0.0/8
		169.254.0.0/16
		172.16.0.0/12
		192.0.0.0/24
		192.0.2.0/24
		192.31.196.0/24
		192.52.193.0/24
		192.88.99.0/24
		192.168.0.0/16
		192.175.48.0/24
		198.18.0.0/15
		198.51.100.0/24
		203.0.113.0/24
		224.0.0.0/4
		240.0.0.0/4
		255.255.255.255/32
EOF
}

echo "nameserver 114.114.114.114" > /etc/resolv.conf
ipset -exist create chnroute hash:net hashsize 64
ipset -exist create chnroute_tun hash:net hashsize 64
ipset -exist create sserver hash:net hashsize 64

ipset -exist create extra_dst_bp hash:net hashsize 64
ipset -exist create extra_src_bp hash:net hashsize 64

sed -Ee '/^#/d' /root/dst_bp.txt | awk 'NF' | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}" | sed -e "s/^/add extra_dst_bp /" | ipset restore

#for sshost in `cat /root/sshost.txt `;do ipset add sserver $(ping -c 1 $sshost | grep from | awk -F" " '{print $4}' | sed -e 's/://');done

sed -e "s/^/add chnroute /" /chnroute.ipset | ipset restore
[ -s /root/chnroute_tun.txt ] && sed -e "s/^/add chnroute_tun /" /root/chnroute_tun.txt | ipset restore
ip_addr=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')/16
	iptables-restore -n <<-EOF
	*nat
	:0xTX - [0:0]
	$(func_get_reserved_ip_addr | sed -e "s/\(.*\)/-A 0xTX -d \1 -j RETURN/")
	COMMIT
EOF

#iptables -t mangle -N 0xTX
#iptables -t nat -N 0xTX

iptables -t nat -A 0xTX -d $ip_addr -j RETURN
iptables -t mangle -A 0xTX -d $ip_addr -j RETURN


iptables -t nat -A 0xTX -p tcp -m set --match-set extra_dst_bp dst -j RETURN
iptables -t nat -A 0xTX -p tcp -m set --match-set sserver dst -j RETURN
iptables -t nat -A 0xTX -p tcp -m set --match-set chnroute_tun dst -j REDIRECT --to-port 1081
iptables -t nat -A 0xTX -m set --match-set chnroute dst -j RETURN
iptables -t nat -A 0xTX -p tcp -j REDIRECT --to-port 1081
iptables -t nat -A PREROUTING -p tcp -j 0xTX

#for pc self
iptables -t nat -A OUTPUT -p tcp -j 0xTX


ip rule add fwmark 1 lookup 100
ip route add local 0.0.0.0/0 dev lo table 100
#        iptables -t mangle -N 0xTX
		iptables-restore -n <<-EOF
		*mangle
		:0xTX - [0:0]
		$(func_get_reserved_ip_addr | sed -e "s/\(.*\)/-A 0xTX -d \1 -j RETURN/")
		COMMIT
EOF

iptables -t mangle -A 0xTX -p udp -m set --match-set chnroute_tun dst -j TPROXY --on-port 1081 --tproxy-mark 0x1/0x1
iptables -t mangle -A 0xTX -m set --match-set chnroute dst -j RETURN
iptables -t mangle -A 0xTX -p udp -j TPROXY --on-port 1081 --tproxy-mark 0x1/0x1
iptables -t mangle -A PREROUTING -p udp -j 0xTX


/tx-redir -c /root/config.json -b 0.0.0.0 -l 1081 -u  > /dev/null 2>&1 &
/tx-local -c /root/config.json -b 0.0.0.0 -l 1080 -u  > /dev/null 2>&1 &


/usr/sbin/dnsmasq
/dns2socks 127.0.0.1:1080 8.8.8.8:53 0.0.0.0:5353

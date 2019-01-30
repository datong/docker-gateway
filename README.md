
# Usage:
## Create config.json file in "/path/to/config"
```
{
    "server": "server address",
    "server_port": port,
    "password": "password",
    "method": "method",
    "obfs": "obfs",
    "obfs_param": "obfs_param",
    "protocol": "protocol",
    "protocol_param": "protocol_param"
}
```
## Launch gateway container
```
`Armbian_5.60_Aml-s9xxx_Debian_stretch_default_4.18.7_20180922.img`

apt-get update
cul -fsSL https://get.docker.com | sh

cd docker-gateway
docker build -t gateway .

ip link set eth0 promisc on
docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 -o parent=eth0 macnet
docker run --restart always -d --name gateway --network macnet --ip 192.168.1.2 --privileged -v /root/gateway/config:/root gateway

```

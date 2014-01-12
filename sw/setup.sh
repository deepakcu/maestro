#Configuration for a 2 node cluster (thinkpad is slave and karma is master)
#fpga plugged to karma
#deepak - setting eth1 IP leads to crash (so for now set eth1 in promisc mode and only set the ARP - debug this later)
#ifconfig eth1 10.1.1.2/24

/etc/init.d/avahi-daemon stop
service smbd stop

ifconfig eth1 0
ifconfig eth1 10.1.1.2/24
arp -s 10.1.1.1 00:4E:46:32:43:00 dev eth1

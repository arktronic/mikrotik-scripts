# MikroTik RouterOS scripts

### Online RTTTL converter/script generator: [Web page](https://arktronic.github.io/mikrotik-scripts/rtttl.html)

Because your router has a beep command, and you must use it to its full potential.

<hr />

### Static DNS records for DHCP leases: `dhcp-dns.rsc`

What makes this script different from the [many](http://wiki.mikrotik.com/wiki/Setting_static_DNS_record_for_each_DHCP_lease) [other](https://www.geektank.net/2012/07/mikrotik-automatically-creating-dns-record-for-each-dhcp-leaseclient/) [scripts](https://www.tolaris.com/2014/09/27/synchronising-dhcp-and-dns-on-mikrotik-routers/) that do DHCP-DNS sync is the following:

* DHCP names are cleaned to conform to [RFC 1123](https://tools.ietf.org/html/rfc1123)
* Conflicting DHCP names will always use the latest entry
* Custom DNS entries cannot be accidentally overridden by DHCP
* Comments are used to distinguish between custom DNS entries and DHCP DNS entries
* Multiple copies of the script can be run to work with more than one DHCP server

<hr />

### Dual WAN failover: `wan-dhcp-failover.rsc`

This script can be used when both WAN interfaces use DHCP for their public IPs and gateways. It updates static routes for the ping targets accordingly. Note, this script has only been tested in RouterOS 7.

<hr />

### dns.he.net dynamic DNS updater: `hurricane-electric-ddns.rsc`

A simple, non-spammy script to update DDNS hosted at Hurricane Electric. It caches the last known public IP and doesn't request an update unless that value changes.

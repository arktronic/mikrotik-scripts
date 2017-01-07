# Name of the interface that has a public IP
:local inetInterface "ether1"

# Domain name registered with dns.he.net
:local hostname "domain.example.com"

# Generated password for dynamic DNS record (not account password!)
:local password "abcdefghijk"

# Enable console debug:
#:local debugout do={ :put ("DEBUG: " . [:tostr $1]); }
# Disable console debug:
:local debugout do={ :log debug $1; }

#----- END OF CONFIG -----#

:global ddnsCurrentIp

:local newip [/ip address get [find interface=$inetInterface] address]
:if ($newip != $ddnsCurrentIp) do={
  :log info ("Updating DDNS from '$ddnsCurrentIp' to '$newip'")
  :set ddnsCurrentIp $newip
  /tool fetch mode=https url="https://$hostname:$password@dyn.dns.he.net/nic/update?hostname=$hostname" keep-result=no
} else={
  $debugout ("No DDNS update needed")
}

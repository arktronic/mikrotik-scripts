# Name of the DHCP server instance:
:local dhcpServer "dhcpname"

# DNS zone suffix:
:local dnsSuffix ".myzone.local"

# DNS TTL:
:local ttl "00:02:00"

# Enable console debug:
#:local debugout do={ :put ("DEBUG: " . [:tostr $1]); }
# Disable console debug:
:local debugout do={ :log debug $1; }

#----- END OF CONFIG -----#

:local cleanHostname do={
  :local max ([:len $1] - 1);
  :if ($1 ~ "^[a-zA-Z0-9]+[a-zA-Z0-9\\-]*[a-zA-Z0-9]+\$" && ([:pick $1 ($max)] != "\00")) do={
    :return ($1);
  } else={
    :local cleaned "";
    :for i from=0 to=$max do={
      :local c [:pick $1 $i]
      :if ($c ~ "^[a-zA-Z0-9]{1}\$") do={
        :set cleaned ($cleaned . $c)
      } else={
        if ($c = "-" and $i > 0 and $i < $max) do={
          :set cleaned ($cleaned . $c)
        }
      }
    }
    :return ($cleaned);
  }
}


# Cache current DHCP lease IDs and cleaned hostnames
:local dhcpLeases
:set $dhcpLeases [:toarray ""]
/ip dhcp-server lease
:foreach lease in=[find where server=$dhcpServer] do={
  :local hostRaw [get $lease host-name]
  :if ([:len $hostRaw] > 0) do={
    :local hostCleaned
    :set hostCleaned [$cleanHostname $hostRaw]
    :set ($dhcpLeases->$hostCleaned) $lease
  }
}


# Remove or update stale DNS entries
/ip dns static
:foreach record in=[find where comment="<AUTO:DHCP:$dhcpServer>"] do={
  :local fqdn [get $record name]
  :local hostname [:pick $fqdn 0 ([:len $fqdn] - [:len $dnsSuffix])]
  :local leaseMatch ($dhcpLeases->$hostname)
  
  :if ([:len $leaseMatch] < 1) do={
    $debugout ("Removing stale DNS record '$fqdn'")
    remove $record
  } else={
    :local lease [/ip dhcp-server lease get $leaseMatch address]
    :if ($lease != [get $record address]) do={
      $debugout ("Updating stale DNS record '$fqdn' to $lease")
      :do {
        set $record address=$lease
      } on-error={
        :log warning "Unable to update stale DNS record '$fqdn'"
      }
    }
  }
}


# Add new DNS entries
/ip dns static
:foreach k,v in=$dhcpLeases do={
  :local fqdn ($k . $dnsSuffix)
  :if ([:len [find where name=$fqdn]] < 1) do={
    :local lease [/ip dhcp-server lease get $v address]
    $debugout ("Creating DNS record '$fqdn': $lease")
    :do {
      add name=$fqdn address=$lease ttl=$ttl comment="<AUTO:DHCP:$dhcpServer>"
    } on-error={
      :log warning "Unable to create DNS record '$fqdn'"
    }
  }
}

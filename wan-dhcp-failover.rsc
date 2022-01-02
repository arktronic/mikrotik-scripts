# Dual WAN DHCP-only failover
# For use when both WAN interfaces are using the DHCP client
# https://github.com/arktronic/mikrotik-scripts

# NOTES:
# - If both primary and secondary WAN interfaces are down, this script will default to enabling the primary interface anyway.
# - While the primary WAN interface is functioning correctly, the secondary interface is not checked.

# Primary and secondary WAN interfaces:
:local primaryWanInterface ether1
:local secondaryWanInterface lte1

# Target IP addresses for pinging (each will be forced to go through its respective interface):
:local primaryWanPingTarget 208.67.222.123
:local secondaryWanPingTarget 208.67.220.123

# Number of pings to send and the maximum allowed failures before failover occurs:
:local pingCount 3
:local maxFailedPings 1

# Distances for active and inactive WAN routes:
:local activeDistance 5
:local inactiveDistance 10
#----- END OF CONFIG -----#


# Ensure the ping targets are routed via their respective gateways
/ip dhcp-client
:local primaryWanGateway [get [find interface=$primaryWanInterface] gateway]
:local secondaryWanGateway [get [find interface=$secondaryWanInterface] gateway]
/ip route
:if ([:len [find comment="<AUTO:WAN Failover Primary Check Route>"]] != 1) do={
	# Remove multiple (invalid) entries if they exist, and add the correct one
	remove [find comment="<AUTO:WAN Failover Primary Check Route>"]
	add dst-address="$primaryWanPingTarget/32" gateway=$primaryWanGateway comment="<AUTO:WAN Failover Primary Check Route>"
} else={
	# Verify the entry's correctness and fix if necessary
	:if ([get [find comment="<AUTO:WAN Failover Primary Check Route>"] dst-address] != "$primaryWanPingTarget/32") do={
		set [find comment="<AUTO:WAN Failover Primary Check Route>"] dst-address="$primaryWanPingTarget/32"
	}
	:if ([get [find comment="<AUTO:WAN Failover Primary Check Route>"] gateway] != $primaryWanGateway) do={
		set [find comment="<AUTO:WAN Failover Primary Check Route>"] gateway=$primaryWanGateway
	}
}
:if ([:len [find comment="<AUTO:WAN Failover Secondary Check Route>"]] != 1) do={
	# Remove multiple (invalid) entries if they exist, and add the correct one
	remove [find comment="<AUTO:WAN Failover Secondary Check Route>"]
	add dst-address="$secondaryWanPingTarget/32" gateway=$secondaryWanGateway comment="<AUTO:WAN Failover Secondary Check Route>"
} else={
	# Verify the entry's correctness and fix if necessary
	:if ([get [find comment="<AUTO:WAN Failover Secondary Check Route>"] dst-address] != "$secondaryWanPingTarget/32") do={
		set [find comment="<AUTO:WAN Failover Secondary Check Route>"] dst-address="$secondaryWanPingTarget/32"
	}
	:if ([get [find comment="<AUTO:WAN Failover Secondary Check Route>"] gateway] != $secondaryWanGateway) do={
		set [find comment="<AUTO:WAN Failover Secondary Check Route>"] gateway=$secondaryWanGateway
	}
}

# Determine WAN functionality via ping
:local choosePrimaryInterface
:local primaryWanPingResult [/ping $primaryWanPingTarget count=$pingCount interval=2s interface=$primaryWanInterface]

:if ($pingCount - $primaryWanPingResult > $maxFailedPings) do={
	:local secondaryWanPingResult [/ping $secondaryWanPingTarget count=$pingCount interval=2s interface=$secondaryWanInterface]
	:if ($pingCount - $secondaryWanPingResult > $maxFailedPings) do={
		# Both interfaces are down.
		:set $choosePrimaryInterface true
	} else={
		# Secondary interface is up.
		:set $choosePrimaryInterface false
	}
} else={
	# Primary interface is up.
	:set $choosePrimaryInterface true
}

# Get the current distances
/ip dhcp-client
:local currentPrimaryInterfaceDistance [get [find interface=$primaryWanInterface] default-route-distance]
:local currentSecondaryInterfaceDistance [get [find interface=$secondaryWanInterface] default-route-distance]

# Adjust distances if necessary
:if ($choosePrimaryInterface and ($currentPrimaryInterfaceDistance != $activeDistance or $currentSecondaryInterfaceDistance != $inactiveDistance)) do={
	:log warning "Activating primary WAN interface"
	set [find interface=$primaryWanInterface] default-route-distance=$activeDistance
	set [find interface=$secondaryWanInterface] default-route-distance=$inactiveDistance
}
:if (!$choosePrimaryInterface and ($currentPrimaryInterfaceDistance != $inactiveDistance or $currentSecondaryInterfaceDistance != $activeDistance)) do={
	:log warning "Activating secondary WAN interface"
	set [find interface=$primaryWanInterface] default-route-distance=$inactiveDistance
	set [find interface=$secondaryWanInterface] default-route-distance=$activeDistance
}

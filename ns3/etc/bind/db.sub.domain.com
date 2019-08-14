;
; BIND data file for local loopback interface
;
$TTL	1
@	IN	SOA	ns3.domain.com.  root.ns3.domain.com. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
; name servers
    IN      NS      ns3.domain.com.
    IN      TXT     ns3

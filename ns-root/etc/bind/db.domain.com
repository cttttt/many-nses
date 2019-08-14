;
; BIND data file for local loopback interface
;
$TTL	604800
@	IN	SOA	ns-root.domain.com.  root.ns-root.domain.com. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
; name servers
    IN      NS      ns-root.domain.com.

; ip addresses
ns-root.domain.com.      IN      A       10.5.0.2
ns3.domain.com.          IN      A       10.5.0.3
ns4.domain.com.          IN      A       10.5.0.4
ns5.domain.com.          IN      A       10.5.0.5
sub                      IN      NS      ns3.domain.com.
sub                      IN      NS      ns4.domain.com.
sub                      IN      NS      ns5.domain.com.

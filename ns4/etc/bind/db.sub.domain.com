;
; BIND data file for local loopback interface
;
$TTL	1
@	IN	SOA	ns4.domain.com.  root.ns4.domain.com. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
; name servers
    IN      NS      ns4.domain.com.
    IN      TXT     ns4

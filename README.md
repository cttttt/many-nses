# DNS Failover with multiple NS records

Just a little experiment so I can learn more about how multiple NS records are
interpretted by recursive DNS servers.

## Setup

In this little test setup, I'll create five DNS servers which collectively hold
the records for the `domain.com` zone:

- A "root" server for this domain be authoritative over the `domain.com` zone
  and will be configured with all of the records necessary to delegate
  `sub.domain.com` to three other servers.
  
- Meanwhile, these three servers will be configured as authoritative over
  `sub.domain.com`, and will each be configured with a different TXT record.
  The idea here is to maek it easy to identify which server responds to a TXT
  query.

- Finally, a fifth server will simply act as a recurssor, forwarding requests
  to the "root" server that controls `domain.com`.

```
                                                         .-----------------------------.
                                                         | domain.com zone             |
                                                         |-----------------------------|
    .----------.                                         | @ SOA ns-root.domain.com.   |
    |          |                                         | @ NS ns-root.domain.com.    |
    | ns-root  |-----------------------------------------| sub NS ns3.domain.com.      |      
 .->| 10.5.0.2 |                                         | sub NS ns4.domain.com.      |      
 |  |          |                                         | sub NS ns5.domain.com.      |      
 |  '----------'                                         | ns3.domain.com. A 10.5.0.3  |
 |                                                       | ns4.domain.com. A 10.5.0.4  |
 |                                                       | ns5.domain.com. A 10.5.0.5  |
 |                                                       '-----------------------------'
 |
 |                    
 |                    
 |  .----------.       .-----------------------------.
 |  |          |       | sub.domain.com zone         |
 |  | ns3      |       |-----------------------------|
 |  | 10.5.0.3 |-------| @ SOA ns3.domain.com.       |
 |  |          |       | @ NS ns3.domain.com.        |
 |  '----------'       | @ TXT ns3                   |
 |                     '-----------------------------'          .-----------------------------.
 |                                                              | sub.domain.com zone         |
 |  .----------.                                                |-----------------------------|
 |  |          |------------------------------------------------| @ SOA ns4.domain.com.       |
 |  | ns4      |                                                | @ NS ns4.domain.com.        |
 |  | 10.5.0.4 |                                                | @ TXT ns4                   |
 |  |          |                                                '-----------------------------'
 |  '----------'
 |
 |  .----------.                       .-----------------------------.
 |  |          |                       | sub.domain.com zone         |
 |  | ns5      |                       |-----------------------------|
 |  | 10.5.0.5 |-----------------------| @ SOA ns5.domain.com.       |
 |  |          |                       | @ NS ns5.domain.com.        |
 |  '----------'                       | @ TXT ns5                   |
 |                                     '-----------------------------'
 |
(forwarder)
 |
 |  .----------.
 |  |          |
 '--| recursor |
    | 10.5.0.6 |
    |          |
    '----------'
```

## Normal Operation

**Starting up bind servers**

First step is to spawn containers for all of our `bind` servers:

```shell
$ docker-compose down
...
$ docker-compose up -d --build
...
$ docker restart
...
$ 
```

**Performing a query**

Next step is to perform a query against our recursor (a query for TXT records
on the domain, `sub.domain.com`):

```shell
$ docker-compose exec recursor dig @localhost +short TXT sub.domain.com
"ns3"
$
```

**Results**

As shown above, one of the name servers for this subdomain, `ns3.domain.com`
was queried and returned a result.

## Degraded Operation

Let's cause a degradation by stopping the name server that returned the result above:

**Stopping `ns3`**

```shell
$ docker-compose stop ns3
Stopping learn-bind_ns3_1 ... done
$
```

**Performing a query**

And let's perform another query against our recursor:

```shell
$ docker-compose exec recursor dig @localhost +short TXT sub.domain.com
"ns4"
$
```
**Stopping `ns4`**

Let's degrade things further by stopping `ns4`:

```shell
$ docker-compose stop ns4
Stopping learn-bind_ns4_1 ... done
$ docker-compose exec recursor dig @localhost +short TXT sub.domain.com
"ns5"
$
```

## Full Outage

Let's cause full outage of `sub.domain.com` by stopping its remaining name server:

**Stopping `ns5`**

```shell
$ docker-compose stop ns5
Stopping learn-bind_ns5_1 ... done
$
```

**Performing a query**

As is evident, when all domain name servers are down, the result is a SERVFAIL error.

```shell
$ docker-compose exec recursor dig @localhost +short TXT sub.domain.com
$ docker-compose exec recursor dig @localhost TXT sub.domain.com

; <<>> DiG 9.11.3-1ubuntu1.8-Ubuntu <<>> @localhost TXT sub.domain.com
; (2 servers found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 33382
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: f39e4f9a6146593e1957bb495d544fc9c9685958ce9aa5b0 (good)
;; QUESTION SECTION:
;sub.domain.com.                        IN      TXT

;; Query time: 3000 msec
;; SERVER: 127.0.0.1#53(127.0.0.1)
;; WHEN: Wed Aug 14 18:15:37 UTC 2019
;; MSG SIZE  rcvd: 71

$
```

## Partial Recovery

Let's bring back one of our name servers to confirm that we at least see a partial recovery:

**Starting `ns5`**

```shell
$ docker-compose start ns5
Starting ns5 ... done
```

**Performing a query**

```shell
$ docker-compose exec recursor dig @localhost +short TXT sub.domain.com
"ns5"
$
```

## Full recovery

Let's bring all of the servers back and see what happens:

**Starting the remaining servers**

```shell
$ docker-compose up -d
Starting learn-bind_ns3_1 ...
learn-bind_ns5_1 is up-to-date
learn-bind_recursor_1 is up-to-date
Starting learn-bind_ns3_1 ... done
Starting learn-bind_ns4_1 ... done
```

**Performing a query**

```shell
$ docker-compose exec recursor dig @localhost +short TXT sub.domain.com
"ns4"
```

## Conclusion

Seems like multiple NS records are observed by resolvers 👍.

## Notes

Note that:

- I set a very low (1s) TTL for all zones.  In practice, the results of my
  queries would be be sticky until the TTL is reached.
- This is simulating a scenario where backup DNS servers are all configured as
  primary.  In such a setup, some mechanism besides zone transfers should be
  used to ensure that all servers for a domain are in sync.  Here, I initially
  configured different records for each server to help highlight which server
  records were being pulled from.
- This scenario only proves that `bind9` is able to consider multiple NS
  records.  Since it's pretty likely that a `bind`-based recursor will sit
  somewhere between clients and authoriative name servers, this gives me
  comfort, however, this does not prove the behavior of all resolvers.
- I may have made some mechanical errors copying and pasting output.  Feel free
  to try this out yourself.  All you need is a docker client, `docker-compose`
  and a docker daemon to target.

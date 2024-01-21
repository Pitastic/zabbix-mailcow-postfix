# Zabbix Postfix Template for Mailcow (dockerized)

Zabbix template for Postfix SMTP server in a [Mailcow-Dockerized](https://docs.mailcow.email/) environment.

I added some more data poimts espacially the bounce information. On the other hand I deleted the ˋlogtailˋ feature as if this is not required anymore because of dockers `docker logs --since=XXX` feature.

I decided to respond with one `JSON` containing all values for (so called) dependent items in Zabbix. This way the results are more actual and less http requests are needed. Also the Postfix log stats are rewritten on every request insted of updating values on the client.

New Triggers are also created for the new bounced emails data points. Bounced and rejected Emails are not recoverable and must be closed manually. Three bounces are for Information, 10 is Average a warning but just one in cause of being on a blocklist (bounce code 550) is a Disaster. You may adjust the numbers and severity in triggers as always to your needs.

### Includes the following metrics:

| Key           | Type          |  Description   |
| ------------- | ------------- |  ------------- |
| bounced       |  mails  |  Outgoing Mails that get rejected at the receiving site  |
| bounced_domains  |  domains  |  List of domains that rejected mails from your server  |
| bytes_received  |  bytes  |  Size of all received mails  |
| bytes_delivered  |  bytes  |  Size of all sent mails  |
| deferred      |  mails  |  Queued mails which could not be delivered on first attemp  |
| delivered     |  mails  |  Mails outgoing (send successfully)  |
| discarded     |  mails  |  Your server dropped this email (without bouncing)  |
| forwarded     |  mails  |  Mails outgoing (forwarded successfully)  |
| held          |  mails  |  Mails in transit e.g. waiting for scanning  |
| received      |  mails  |  Mails incomming  |
| recipients    |  addresses  |  Number of different receivers (in- or outgoing)  |
| reject_warnings  |  mails  |  Your server logs a warning but received this emails  |
| rejected      |  mails  |  Mails your server refused to send (sender got bounced) |
| senders       |  addresses  |  Number of different senders (in- or outgoing)  |


## Requirements

* Works for Zabbix 6.4
* [pflogsum](http://jimsun.linxnet.com/postfix_contrib.html)

## Installation

Import `mailcow_postfix.xml` and attach it to your host after the installation below. No config adjustment is needed.

### ...for Ubuntu / Debian and/or Agent v2
    
    apt install pflogsumm
    
    cp mailcow_postfix.conf /etc/zabbix/zabbix_agent2.d/
    cp zabbix-postfix-stats.sh /usr/bin/
    chmod +x /usr/bin/zabbix-postfix-stats.sh
    
    systemctl restart zabbix-agent2

    
### ...for CentOS and/or Agent v1
    
    yum install postfix-perl-scripts

    cp mailcow_postfix.conf /etc/zabbix/zabbix_agentd.d/
    cp zabbix-postfix-stats.sh /usr/bin/
    chmod +x /usr/bin/zabbix-postfix-stats.sh
    
    systemctl restart zabbix-agent

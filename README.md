# Zabbix Postfix Template for Mailcow (dockerized)

Zabbix template for Postfix SMTP server in a [Mailcow-Dockerized](https://docs.mailcow.email/) environment.

Because of the `docker logs --since=XXX` feature something like `logtail` is not required anymore.

I decided to repond with one `JSON` containing all values for (so called) dependent items in Zabbix. This way the results are more actual and less http requests are needed. Also the Postfix log stats are rewritten on every request insted of updating values on the client. Be careful: The checkintervall / delay setting in the template must be smaller than the amount of logs that are fetched from the containers. Otherwise you will skip loglines.

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
| recipients    |  addresses  |  Number of diffrent receivers (in- or outgoing)  |
| reject_warnings  |  mails  |  Your server logs a warning but received this emails  |
| rejected      |  mails  |  Mails your server refused to send (sender got bounced) |
| senders       |  addresses  |  Number of diffrent senders (in- or outgoing)  |


## Requirements

* Works for Zabbix 6.4
* [pflogsum](http://jimsun.linxnet.com/postfix_contrib.html)

## Installation

    apt install pflogsumm               # for Ubuntu / Debian
    yum install postfix-perl-scripts    # for CentOS
    
    cp zabbix-postfix-stats.sh /usr/bin/
    chmod +x /usr/bin/zabbix-postfix-stats.sh

    cp mailcow_postfix.conf /etc/zabbix/zabbix_agentd.d/
    
    systemctl restart zabbix-agent

Finally import `mailcow_postfix.xml` and attach it to your host.
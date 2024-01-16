# Zabbix Postfix Template for Mailcow (dockerized)

Zabbix template for Postfix SMTP server in a [Mailcow-Dockerized](https://docs.mailcow.email/) environment.

Because of the `docker logs --since=XXX` feature something like `logtail` is not required anymore.

Postfix log stats are rewritten on every request. Be careful: The checkintervall setting in the templates must match (or should not be longer than) the interval setting in the agent config for this service. Otherwise loglines will be skipped.

### Includes the following metrics:

| Key           | Type          |  Description   |
| ------------- | ------------- |  ------------- |
| received      |  mails  |  Mails incomming  |
| delivered     |  mails  |  Mails outgoing (send successfully)  |
| forwarded     |  mails  |  Mails outgoing (forwarded successfully)  |
| deferred      |  mails  |  Queued mails which could not be delivered on first attemp  |
| bounced       |  mails  |  Outgoing Mails that get rejected at the receiving site  |
| rejected      |  mails  |  Mails your server refused to send (sender got bounced) |
| held          |  mails  |  Mails in transit e.g. waiting for scanning  |
| discarded     |  mails  |  Your server dropped this email (without bouncing)  |
| reject_warnings  |  mails  |  Your server logs a warning but received this emails  |
| bytes_received  |  bytes  |  Size of all received mails  |
| bytes_delivered  |  bytes  |  Size of all sent mails  |
| senders       |  addresses  |  Number of diffrent senders (in- or outgoing)  |
| recipients    |  addresses  |  Number of diffrent receivers (in- or outgoing)  |
| bounced_domains  |  domains  |  List of domains that rejected mails from your server  |


## Requirements

* Works for Zabbix 6.4
* [pflogsum](http://jimsun.linxnet.com/postfix_contrib.html)

## Installation

    # for Ubuntu / Debian
    apt-get install pflogsumm
    
    # for CentOS
    yum install postfix-perl-scripts
    
    # ! check MAILLOG path in zabbix-postfix-stats.sh
    cp zabbix-postfix-stats.sh /usr/bin/
    chmod +x /usr/bin/zabbix-postfix-stats.sh

    cp userparameter_postfix.conf /etc/zabbix/zabbix_agentd.d/
    
    systemctl restart zabbix-agent

Finally import template_app_zabbix.xml and attach it to your host.
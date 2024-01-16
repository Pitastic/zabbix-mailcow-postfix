# zabbix-postfix-template
Zabbix template for Postfix SMTP server in a [Mailcow-Dockerized](https://docs.mailcow.email/) environment.

Because of the `docker logs --since=XXX` feature something like `logtail` is not required anymore. Be careful: The checkintervall setting in the templates must match (or should not be longer than) the interval setting in the agent config for this service. Otherwise loglines will be skipped.

Works for Zabbix 6.x

# Requirements
* [pflogsum](http://jimsun.linxnet.com/postfix_contrib.html)

# Installation

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
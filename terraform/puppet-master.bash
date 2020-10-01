    #!/bin/bash
    sudo timedatectl set-timezone ASIA/TOKYO
    sudo yum -y install ntp
    sudo ntpdate pool.ntp.org
    sudo sh -c "echo 
    'server 0.jp.pool.ntp.org
    server 1.jp.pool.ntp.org
    server 2.jp.pool.ntp.org
    server 3.jp.pool.ntp.org' >> /etc/ntp.conf"
    sudo systemctl restart ntpd
    sudo systemctl enable ntpd
    sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
    sudo yum -y install puppetserver
    sudo sed -i -e "/JAVA_ARGS/d" /etc/sysconfig/puppetserver
    sudo sh -c "echo 'JAVA_ARGS=\"-Xms250m -Xmx250m -XX:MaxPermSize=256m\"' >>  /etc/sysconfig/puppetserver"
    sudo systemctl start puppetserver
    sudo systemctl enable puppetserver
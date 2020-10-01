#!/bin/bash
sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
sudo yum -y install puppet-agent
sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
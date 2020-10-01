#!/bin/bash
sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
sudo yum -y install puppet-agent
sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
# puppet module install puppetlabs-kubernetes --version 5.3.0
# sudo yum -y install docker
# sudo service docker start
# docker run --rm -v $(pwd):/mnt --env-file env puppet/kubetool:5.3.0
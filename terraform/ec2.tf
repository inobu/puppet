/**
 * require
 **/
terraform {
  required_version = ">= 0.11.0"
}

/**
 * variable
 **/
variable "key_name" {
  type        = "string"
  description = "keypair name"
  #default    = "example" # キー名を固定したかったらdefault指定。指定なしならインタラクティブにキー入力して決定。
}

# キーファイル
## 生成場所のPATH指定をしたければ、ここを変更するとよい。
locals {
  public_key_file  = "./${var.key_name}.id_rsa.pub"
  private_key_file = "./${var.key_name}.id_rsa"
}

/**
 * resource
 **/
# キーペアを作る
resource "tls_private_key" "keygen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

/**
 * file
 **/
# 秘密鍵ファイルを作る
resource "local_file" "private_key_pem" {
  filename = "${local.private_key_file}"
  content  = "${tls_private_key.keygen.private_key_pem}"

  # local_fileでファイルを作ると実行権限が付与されてしまうので、local-execでchmodしておく。
  provisioner "local-exec" {
    command = "chmod 600 ${local.private_key_file}"
  }
}

resource "local_file" "public_key_openssh" {
  filename = "${local.public_key_file}"
  content  = "${tls_private_key.keygen.public_key_openssh}"

  # local_fileでファイルを作ると実行権限が付与されてしまうので、local-execでchmodしておく。
  provisioner "local-exec" {
    command = "chmod 600 ${local.public_key_file}"
  }
}

/**
 * output
 **/
# キー名
output "key_name" {
  value = "${var.key_name}"
}

# 秘密鍵ファイルPATH（このファイルを利用してサーバへアクセスする。）
output "private_key_file" {
  value = "${local.private_key_file}"
}

# 秘密鍵内容
output "private_key_pem" {
  value = "${tls_private_key.keygen.private_key_pem}"
}

# 公開鍵ファイルPATH
output "public_key_file" {
  value = "${local.public_key_file}"
}

# 公開鍵内容（サーバの~/.ssh/authorized_keysに登録して利用する。）
output "public_key_openssh" {
  value = "${tls_private_key.keygen.public_key_openssh}"
}


resource "aws_key_pair" "key_pair" {
  key_name   = "${var.key_name}"
  public_key = "${tls_private_key.keygen.public_key_openssh}"
}

resource "aws_instance" "puppet_master" {
  ami           = "ami-0f9ae750e8274075b"
  instance_type = "t3.micro"
  key_name      = "${var.key_name}"

  user_data = <<EOF
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
    EOF

  tags = {
    Name = "example"
  }
}

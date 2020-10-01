/**
 * require
 **/
terraform {
  required_version = ">= 0.11.0"
}

/**
 * variable
 **/
variable "key_name_master" {
  type        = "string"
  description = "keypair name"
  #default    = "example" # キー名を固定したかったらdefault指定。指定なしならインタラクティブにキー入力して決定。
}

# キーファイル
## 生成場所のPATH指定をしたければ、ここを変更するとよい。
locals {
  public_key_file_master  = "../key/${var.key_name_master}.id_rsa.pub"
  private_key_file_master = "../key/${var.key_name_master}.id_rsa"
}

/**
 * resource
 **/
# キーペアを作る
resource "tls_private_key" "keygen_master" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

/**
 * file
 **/
# 秘密鍵ファイルを作る
resource "local_file" "private_key_pem_master" {
  filename = "${local.private_key_file}"
  content  = "${tls_private_key.keygen_master.private_key_pem}"

  # local_fileでファイルを作ると実行権限が付与されてしまうので、local-execでchmodしておく。
  provisioner "local-exec" {
    command = "chmod 600 ${local.private_key_file}"
  }
}

resource "local_file" "public_key_openssh_master" {
  filename = "${local.public_key_file_master}"
  content  = "${tls_private_key.keygen_master.public_key_openssh}"

  # local_fileでファイルを作ると実行権限が付与されてしまうので、local-execでchmodしておく。
  provisioner "local-exec" {
    command = "chmod 600 ${local.public_key_file_master}"
  }
}

/**
 * output
 **/
# キー名
output "key_name_master" {
  value = "${var.key_name_master}"
}

# 秘密鍵ファイルPATH（このファイルを利用してサーバへアクセスする。）
output "private_key_file_master" {
  value = "${local.private_key_file_master}"
}

# 秘密鍵内容
output "private_key_pem_master" {
  value = "${tls_private_key.keygen_master.private_key_pem}"
}

# 公開鍵ファイルPATH
output "public_key_file_master" {
  value = "${local.public_key_file_master}"
}

# 公開鍵内容（サーバの~/.ssh/authorized_keysに登録して利用する。）
output "public_key_openssh_master" {
  value = "${tls_private_key.keygen_master.public_key_openssh}"
}


resource "aws_key_pair" "key_pair_master" {
  key_name   = "${var.key_name_master}"
  public_key = "${tls_private_key.keygen_master.public_key_openssh}"
}

resource "aws_instance" "kube-master" {
  ami           = "ami-0f9ae750e8274075b"
  instance_type = "t3.micro"
  key_name      = "${var.key_name_master}"

  user_data = <<EOF
  sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
  sudo yum -y install puppet-agent
  sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
  
  EOF

  tags = {
    Name = "kube-master"
  }
}

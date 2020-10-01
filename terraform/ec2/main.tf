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

variable "init_sh" {}

# キーファイル
## 生成場所のPATH指定をしたければ、ここを変更するとよい。
locals {
  public_key_file  = "../key/${var.key_name}.id_rsa.pub"
  private_key_file = "../key/${var.key_name}.id_rsa"
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

resource "aws_instance" "example" {
  ami           = "ami-0f9ae750e8274075b"
  instance_type = "t3.micro"
  key_name      = "${var.key_name}"

  user_data = file("${var.init_sh}")

  tags = {
    Name = "${var.key_name}"
  }
}

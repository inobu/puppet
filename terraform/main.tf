variable "puppet_master" {}
variable "kube_master" {}

module "puppet_master" {
  source = "./ec2"
  init_sh = "./puppet-master.bash"
  key_name = "${var.puppet_master}"
}

module "kube_master" {
  source = "./ec2"
  init_sh = "./kube-master.bash"
  key_name = "${var.kube_master}"
}
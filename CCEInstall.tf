provider "huaweicloud" {
  region     = "ap-southeast-3"  # 替换为你的区域
  access_key = ""
  secret_key = ""
}

terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.71.2"
    }
    random = {
      version = "~> 3.6.3"
    }
  }
}

resource "huaweicloud_vpc" "myvpc" {
  name = "myvpc"
  cidr = "192.168.0.0/16"
}

resource "huaweicloud_vpc_subnet" "mysubnet" {
  name          = "mysubnet"
  cidr          = "192.168.0.0/16"
  gateway_ip    = "192.168.0.1"

  //dns is required for cce node installing
  primary_dns   = "100.125.1.250"
  secondary_dns = "100.125.21.250"
  vpc_id        = huaweicloud_vpc.myvpc.id
}

resource "huaweicloud_vpc_eip" "myeip" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "mybandwidth"
    size        = 100
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "random_password" "password" {
  length           = 24
  special          = true
  override_special = "!@#$%*"
}

locals {
   admin_pwd  = random_password.password.result
   instance_public_ip = huaweicloud_vpc_eip.myeip.address
}

resource "huaweicloud_cce_cluster" "mycce" {
  name                   = "mycce"
  flavor_id              = "cce.s1.small"
  vpc_id                 = huaweicloud_vpc.myvpc.id
  subnet_id              = huaweicloud_vpc_subnet.mysubnet.id
  container_network_type = "overlay_l2"
  eip                    = huaweicloud_vpc_eip.myeip.address // 若不使用弹性公网ip，忽略此行
}

data "huaweicloud_availability_zones" "myaz" {}

#resource "huaweicloud_compute_keypair" "mykeypair" {
#  name = "mykeypair"
#}

resource "huaweicloud_cce_node" "mynode" {
  cluster_id        = huaweicloud_cce_cluster.mycce.id
  name              = "mynode"
  flavor_id         = "c7t.3xlarge.4"
  availability_zone = data.huaweicloud_availability_zones.myaz.names[0]
  #key_pair          = huaweicloud_compute_keypair.mykeypair.name
  password = local.admin_pwd

  root_volume {
    size       = 40
    volumetype = "SSD"

  }
  data_volumes {
    size       = 100
    volumetype = "SSD"
  }

  extend_params {
     postinstall = <<-EOF
                      #!/bin/sh
                      echo 'shellnihao' >> /tmp/a.txt
                    EOF
  }

}

output "passwd" {
  value = nonsensitive(local.admin_pwd)
}

output "public-ip" {
  value = huaweicloud_vpc_eip.myeip.address
}

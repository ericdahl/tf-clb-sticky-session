provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source        = "github.com/ericdahl/tf-vpc"
  admin_ip_cidr = "${var.admin_cidr}"
}

module "ecs" {
  source = "ecs_cluster"

  cluster_name = "${var.name}"
}


module "ecs_asg_launch_template" {
  source = "ecs_asg_launch_template"
  name   = "ecs-asg-launch-template"

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_vpc}",
    "${module.vpc.sg_allow_22}",
    "${module.vpc.sg_allow_80}",
  ]

  key_name = "${var.key_name}"

  subnets = [
    "${module.vpc.subnet_private1}",
    "${module.vpc.subnet_private2}",
    "${module.vpc.subnet_private3}",
  ]

  instance_type = "m5.large"

  overrides = [
    {
      instance_type = "m5.large"
    },
    {
      instance_type = "m5.xlarge"
    },
  ]

  min_size     = 1
  desired_size = 1
  max_size     = 1

  ami_id                = "${module.ecs.ami_id}"
  instance_profile_name = "${module.ecs.iam_instance_profile_name}"
  user_data             = "${module.ecs.user-data}"
}

data "aws_iam_role" "autoscaling" {
  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}


data "aws_ami" "amazon_linux_2" {
  most_recent = true

  owners = ["137112412989"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "jumphost" {
  ami                    = "${data.aws_ami.amazon_linux_2.image_id}"
  instance_type          = "t2.small"
  subnet_id              = "${module.vpc.subnet_public1}"
  vpc_security_group_ids = ["${module.vpc.sg_allow_22}", "${module.vpc.sg_allow_egress}"]
  key_name               = "${var.key_name}"

  tags {
    Name = "${var.name}-jumphost"
  }
}

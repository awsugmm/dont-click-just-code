locals {
  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo yum install httpd git -y
sudo git clone https://github.com/DTherHtun/static-gitrepo.git /var/www/html/
sudo service httpd start
sudo chkconfig httpd on
EOF
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.57.0"

  name = "awsugmm"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  enable_vpn_gateway     = false
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


module "sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "3.16.0"

  name        = "http-sg"
  description = "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
  description      = "A service linked role for autoscaling"
  custom_suffix    = "something"

  # Sometimes good sleep is required to have some IAM resources created before they can be used
  provisioner "local-exec" {
    command = "sleep 10"
  }
}


module "autoscale" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "3.7.0"

  name    = "awsugmm-with-ec2"
  lc_name = "awsugmm-lc"

  image_id                     = data.aws_ami.amazon_linux.id
  instance_type                = "t2.micro"
  security_groups              = [module.sg.this_security_group_id]
  associate_public_ip_address  = true
  recreate_asg_when_lc_changes = true
  load_balancers               = [module.elb.this_elb_id]

  user_data_base64 = base64encode(local.user_data)
  key_name         = "dther"
  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "50"
      delete_on_termination = true
    },
  ]

  root_block_device = [
    {
      volume_size           = "50"
      volume_type           = "gp2"
      delete_on_termination = true
    },
  ]

  # Auto scaling group
  asg_name                  = "awsugmm-asg"
  vpc_zone_identifier       = module.vpc.public_subnets
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 6
  desired_capacity          = 3
  wait_for_capacity_timeout = 0
  service_linked_role_arn   = aws_iam_service_linked_role.autoscaling.arn

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "megasecret"
      propagate_at_launch = true
    }
  ]

  tags_as_map = {
    extra_tag1 = "extra_value1"
    extra_tag2 = "extra_value2"
  }
}


module "elb" {
  source  = "terraform-aws-modules/elb/aws"
  version = "2.4.0"

  name = "elb-awsugmm"

  subnets                   = module.vpc.public_subnets
  security_groups           = [module.sg.this_security_group_id]
  internal                  = false
  cross_zone_load_balancing = true

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}


module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "1.2.0"

  zone_name = data.aws_route53_zone.selected.name

  records = [
    {
      name    = "terraform"
      type    = "CNAME"
      ttl     = 60
      records = [module.elb.this_elb_dns_name]
    }
  ]
}

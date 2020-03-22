data "template_file" "httpbin" {
  count = "${var.enable_ec2_httpbin == "true" ? 1 : 0}"

  template = "${file("templates/tasks/httpbin.json")}"

  vars {
    delay_start_connect = "30"
  }
}

resource "aws_ecs_task_definition" "httpbin" {
  count = "${var.enable_ec2_httpbin == "true" ? 1 : 0}"

  container_definitions = "${data.template_file.httpbin.rendered}"
  family                = "httpbin"
}

resource "aws_ecs_service" "httpbin" {
  count = "${var.enable_ec2_httpbin == "true" ? 1 : 0}"

  cluster         = "${module.ecs.cluster_name}"
  name            = "${var.name}-httpbin"
  task_definition = "${aws_ecs_task_definition.httpbin.arn}"
  desired_count   = "1"

//  iam_role = "${module.ecs.iam_role_ecs_service_name}"

//  load_balancer {
//    target_group_arn = "${aws_alb_target_group.default.arn}"
//    container_name   = "httpbin"
//    container_port   = 8080
//  }


  load_balancer {
    elb_name = "${aws_elb.httpbin.name}"
    container_name = "httpbin"
    container_port = 8080
  }

}


resource "aws_elb" "httpbin" {

  name = "${var.name}-httpbin"

  subnets = [
    "${module.vpc.subnet_private1}",
    "${module.vpc.subnet_private2}",
    "${module.vpc.subnet_private3}",
  ]


  "listener" {
    instance_port = 8080
    instance_protocol = "HTTP"
    lb_port = 80
    lb_protocol = "HTTP"
  }

  tags {
    Name = "${var.name}-httpbin"
  }
}

# create a auto-scaling for workers
resource "aws_iam_instance_profile" "eks-node" {
  name = "${var.CLUSTER_NAME}"
  role = "${var.ROLE_NAME}"
}

resource "aws_launch_configuration" "cluster-config" {
  iam_instance_profile = "${aws_iam_instance_profile.eks-node.name}"
  image_id             = "${var.IMAGE_ID}"
  instance_type        = "${var.WORKER_FLAVOR}"
  key_name             = "${var.AWS_KEYPAIR}"
  security_groups      = ["${var.SECURITY_GROUPS}"]
  user_data_base64     = "${var.WORKER_USER_DATA}"

  lifecycle {
    create_before_destroy = true
  }
}

# define the auto-scaling-group for docker workers
resource "aws_autoscaling_group" "cluster-asg" {
  name                 = "${var.CLUSTER_NAME}-asg"
  max_size             = "${var.MAX_NUMBER_NODES}"
  min_size             = "${var.MIN_NUMBER_NODES}"
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.cluster-config.name}"
  vpc_zone_identifier  = ["${var.SUBNET_IDS}"]                             # could be multiple subnet in different availability zone

  tag {
    key                 = "Name"
    value               = "${var.CLUSTER_NAME}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.CLUSTER_NAME}"
    value               = "owned"
    propagate_at_launch = true
  }
}

# define the scaling out policy
resource "aws_autoscaling_policy" "asg-scaleout" {
  name                   = "${var.CLUSTER_NAME}-asg-scaleout"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.cluster-asg.name}"
}

# define the scaling in policy
resource "aws_autoscaling_policy" "asg-scalein" {
  name                   = "${var.CLUSTER_NAME}-asg-scalein"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.cluster-asg.name}"
}

# define the cloud watch for scaleout policy
resource "aws_cloudwatch_metric_alarm" "high-alarm" {
  alarm_name          = "${var.CLUSTER_NAME}-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.cluster-asg.name}"
  }

  alarm_description = "This is monitors the EC2 instance high CPU alarm"
  alarm_actions     = ["${aws_autoscaling_policy.asg-scaleout.arn}"]
}

# define the cloud watch for scalein policy
resource "aws_cloudwatch_metric_alarm" "low-alarm" {
  alarm_name          = "${var.CLUSTER_NAME}-low-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.cluster-asg.name}"
  }

  alarm_description = "This is monitors the EC2 instance low CPU alarm"
  alarm_actions     = ["${aws_autoscaling_policy.asg-scalein.arn}"]
}

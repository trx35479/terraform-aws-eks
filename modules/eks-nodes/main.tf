# create a auto-scaling for workers
resource "aws_iam_instance_profile" "eks-node" {
  name = var.cluster_name
  role = var.role_name
}

resource "aws_launch_configuration" "cluster-config" {
  name                 = "${var.cluster_name}-launch-configuration"
  iam_instance_profile = aws_iam_instance_profile.eks-node.name
  image_id             = var.image_id
  instance_type        = var.worker_flavor
  key_name             = var.aws_keypair
  security_groups      = [var.security_groups]
  user_data_base64     = var.worker_user_data

  lifecycle {
    create_before_destroy = true
  }
}

# define the auto-scaling-group for docker workers
resource "aws_autoscaling_group" "cluster-asg" {
  name                 = "${var.cluster_name}-asg"
  max_size             = var.max_number_nodes
  min_size             = var.min_number_nodes
  force_delete         = true
  launch_configuration = aws_launch_configuration.cluster-config.name
  vpc_zone_identifier  = [var.subnet_ids]                             # could be multiple subnet in different availability zone

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

# define the scaling out policy
resource "aws_autoscaling_policy" "asg-scaleout" {
  name                   = "${var.cluster_name}-asg-scaleout"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.cluster-asg.name
}

# define the scaling in policy
resource "aws_autoscaling_policy" "asg-scalein" {
  name                   = "${var.cluster_name}-asg-scalein"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.cluster-asg.name
}

# define the cloud watch for scaleout policy
resource "aws_cloudwatch_metric_alarm" "high-alarm" {
  alarm_name          = "${var.cluster_name}-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions {
    AutoScalingGroupName = aws_autoscaling_group.cluster-asg.name
  }

  alarm_description = "This is monitors the EC2 instance high CPU alarm"
  alarm_actions     = [aws_autoscaling_policy.asg-scaleout.arn]
}

# define the cloud watch for scalein policy
resource "aws_cloudwatch_metric_alarm" "low-alarm" {
  alarm_name          = "${var.cluster_name}-low-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"

  dimensions {
    AutoScalingGroupName = aws_autoscaling_group.cluster-asg.name
  }

  alarm_description = "This is monitors the EC2 instance low CPU alarm"
  alarm_actions     = [aws_autoscaling_policy.asg-scalein.arn]
}

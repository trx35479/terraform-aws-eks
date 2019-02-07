{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "${service_role}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

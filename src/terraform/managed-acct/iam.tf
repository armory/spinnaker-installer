resource "aws_iam_policy" "SpinnakerManagedPolicy" {
    name = "SpinnakerManagedPolicy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.SpinnakerInstanceProfile.arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

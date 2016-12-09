/*
resource "aws_iam_role" "BaseIAMRole" {
    name = "test-role"
}

resource "aws_iam_role_policy" "armory_spinnaker_policy" {
    name = "armory_spinnaker_policy"
    role = "${aws_iam_role.test_role.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
    role = "${aws_iam_role.role.name}"
    policy_arn = "${aws_iam_policy.policy.arn}"
}

*/
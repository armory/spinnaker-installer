
#
# Spinnaker Managed and Managing Accounts:
#

resource "aws_iam_role" "SpinnakerManagedProfile" {
    name = "SpinnakerManagedProfile"   
}

resource "aws_iam_role" "SpinnakerInstanceProfile" {
    name = "SpinnakerInstanceProfile"
}

resource "aws_iam_instance_profile" "SpinnakerInstanceProfile" {
    name = "SpinnakerInstanceProfile"
    roles = ["${aws_iam_role.SpinnakerInstanceProfile.name}"]
}

#
# Spinnaker Managed Account:
#

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

resource "aws_iam_policy" "SpinnakerAccessPolicy" {
    name = "SpinnakerAccessPolicy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "NotAction": ["iam:*", "organizations:*"],
      "Resource": "*"
    },{
      "Effect": "Allow",
      "Action": "organizations:DescribeOrganization",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "SpinnakerManagedAttachment" {
    role = "${aws_iam_role.SpinnakerManagedProfile.name}"
    policy_arn = "${aws_iam_policy.SpinnakerManagedPolicy.arn}"
}

resource "aws_iam_policy_attachment" "SpinnakerAccessAttachment" {
    role = "${aws_iam_role.SpinnakerAccessPolicy.name}"
    policy_arn = "${aws_iam_policy.SpinnakerAccessPolicy.arn}"
}


#
# Spinnaker Managing Account:
#

resource "aws_iam_policy" "SpinnakerAssumeRolePolicy" {
    name = "SpinnakerAssumeRolePolicy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Resource": [
        "${aws_iam_role.SpinnakerManagedProfile.arn}"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "SpinnakerAssumeRoleAttachment" {
    role = "${aws_iam_role.SpinnakerInstanceProfile.name}"
    policy_arn = "${aws_iam_policy.SpinnakerAssumeRolePolicy.arn}"
}

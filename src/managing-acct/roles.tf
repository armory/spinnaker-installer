
#
# Spinnaker Managed and Managing Accounts:
#

resource "aws_iam_role" "SpinnakerInstanceProfile" {
    name = "SpinnakerInstanceProfile"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "SpinnakerInstanceProfile" {
    name = "SpinnakerInstanceProfile"
    roles = ["${aws_iam_role.SpinnakerInstanceProfile.name}"]
}

resource "aws_iam_role" "SpinnakerManagedProfile" {
    name = "SpinnakerManagedProfile"
    assume_role_policy = <<EOF
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

#
# Spinnaker Managed Account:
#

/*
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
*/

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

/*
resource "aws_iam_role_policy_attachment" "SpinnakerManagedAttachment" {
    role = "${aws_iam_role.SpinnakerManagedProfile.name}"
    policy_arn = "${aws_iam_policy.SpinnakerManagedPolicy.arn}"
}
*/

resource "aws_iam_role_policy_attachment" "SpinnakerAccessAttachment" {
    role = "${aws_iam_role.SpinnakerManagedProfile.name}"
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

resource "aws_iam_role_policy_attachment" "SpinnakerAssumeRoleAttachment" {
    role = "${aws_iam_role.SpinnakerInstanceProfile.name}"
    policy_arn = "${aws_iam_policy.SpinnakerAssumeRolePolicy.arn}"
}

resource "aws_iam_policy" "SpinnakerS3AccessPolicy" {
  name = "SpinnakerS3AccessPolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.armory_s3_bucket}*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "SpinnakerS3AccessAttachment" {
    role = "${aws_iam_role.SpinnakerInstanceProfile.name}"
    policy_arn = "${aws_iam_policy.SpinnakerS3AccessPolicy.arn}"
}
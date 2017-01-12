
#
# Spinnaker Managed and Managing Accounts:
#

resource "aws_iam_role" "SpinnakerInstanceProfile" {
    name = "${var.instance_profile_name}"
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

/*resource "aws_iam_role" "SpinnakerPackerProfile" {
    name = "${var.packer_profile_namee}"
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

*/

resource "aws_iam_instance_profile" "SpinnakerInstanceProfile" {
    name = "${var.instance_profile_name}"
    roles = ["${aws_iam_role.SpinnakerInstanceProfile.name}"]
}

resource "aws_iam_role" "SpinnakerManagedProfile" {
    name = "${var.managed_profile_name}"
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

resource "aws_iam_policy" "SpinnakerAccessPolicy" {
    name = "${var.access_policy_name}"
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

resource "aws_iam_role_policy_attachment" "SpinnakerAccessAttachment" {
    role = "${aws_iam_role.SpinnakerInstanceProfile.name}"
    policy_arn = "${aws_iam_policy.SpinnakerAccessPolicy.arn}"
}

resource "aws_iam_policy" "SpinnakerAssumeRolePolicy" {
    name = "${var.assume_policy_name}"
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

resource "aws_iam_policy" "SpinnakerECRAccessPolicy" {
  name = "${var.ecr_access_policy_name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPull",
      "Effect": "Allow",
      "Action": [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "SpinnakerECRAccessAttachment" {
    role = "${aws_iam_role.SpinnakerInstanceProfile.name}"
    policy_arn = "${aws_iam_policy.SpinnakerECRAccessPolicy.arn}"
}

resource "aws_iam_policy" "SpinnakerS3AccessPolicy" {
  name = "${var.s3_access_policy_name}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.s3_bucket}*"
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

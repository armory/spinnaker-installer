/*resource "aws_iam_role" "SpinnakerManagedProfile" {
    name = "${var.spinnaker_managed_profile_name}"
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
}*/

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
/*
resource "aws_iam_role_policy_attachment" "SpinnakerManagedAttachment" {
    role = "${aws_iam_role.SpinnakerManagedProfile.name}"
    policy_arn = "${aws_iam_policy.SpinnakerManagedPolicy.arn}"
}
*/


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

/*
resource "aws_iam_role_policy_attachment" "SpinnakerManagedAttachment" {
    role = "${aws_iam_role.SpinnakerManagedProfile.name}"
    policy_arn = "${aws_iam_policy.SpinnakerManagedPolicy.arn}"
}
*/

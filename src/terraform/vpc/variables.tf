
variable "aws_region" {
  description = "The region in which you want Spinnaker to live."
  default = "us-west-2"
}

variable "key_name" {
  description = "the key pair name to use as a default"
  default = "default-key-name"
}

variable "public_key" {
  description = "the public key in OpenSSH format to use as the default key"
}

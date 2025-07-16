# Generate an SSH key pair
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save the private key locally
resource "local_file" "private_key" {
  filename = "${path.module}/keys/terraform-ec2-key.pem" #
  content  = tls_private_key.ec2_key.private_key_pem

  # Set permissions
  provisioner "local-exec" {
    command = "chmod 600 ${path.module}/keys/terraform-ec2-key.pem"
  }
}

# Save the public key locally 
resource "local_file" "public_key" {
  filename = "${path.module}/keys/ec2_key.pub"
  content  = tls_private_key.ec2_key.public_key_openssh
}

# Upload the public key to AWS as an EC2 key pair
resource "aws_key_pair" "ec2_key" {
  key_name   = "terraform-ec2-key.pem" # Name of the key pair in AWS
  public_key = tls_private_key.ec2_key.public_key_openssh

}

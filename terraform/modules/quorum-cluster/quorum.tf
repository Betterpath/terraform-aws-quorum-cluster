# ---------------------------------------------------------------------------------------------------------------------
# QUORUM MAKER NODES
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "quorum_maker_node" {
  connection {
    # The default username for our AMI
    user = "ubuntu"

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "${var.quorum_node_instance_type}"
  count         = "${var.num_maker_nodes}"

  ami       = "${lookup(var.quorum_amis, var.aws_region)}"
  user_data = "${data.template_file.user_data_quorum.rendered}"

  key_name = "${aws_key_pair.auth.id}"

  iam_instance_profile = "${aws_iam_instance_profile.quorum_node.name}"

  vpc_security_group_ids = ["${aws_security_group.quorum.id}"]
  subnet_id              = "${element(aws_subnet.quorum_cluster.*.id, count.index)}"

  tags {
    Name = "quorum-maker-node-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "echo '${aws_s3_bucket.quorum_constellation.id} /opt/quorum/constellation/private/s3fs fuse.s3fs _netdev,allow_other,iam_role 0 0' | sudo tee /etc/fstab",
      "sudo mount -a",
      "echo '${count.index}' | sudo tee /opt/quorum/info/role-index.txt",
      "echo '${count.index}' | sudo tee /opt/quorum/info/overall-index.txt",
      "echo '${var.num_maker_nodes + var.num_validator_nodes + var.num_observer_nodes}' | sudo tee /opt/quorum/info/network-size.txt",
      "echo '${var.num_maker_nodes}' | sudo tee /opt/quorum/info/num-makers.txt",
      "echo '${var.num_validator_nodes}' | sudo tee /opt/quorum/info/num-validators.txt",
      "echo '${var.num_observer_nodes}' | sudo tee /opt/quorum/info/num-observers.txt",
      "echo 'maker' | sudo tee /opt/quorum/info/role.txt",
      "echo '${var.vote_threshold}' | sudo tee /opt/quorum/info/vote-threshold.txt",
      "echo '${var.bootnode_cluster_size}' | sudo tee /opt/quorum/info/num-bootnodes.txt",
      # This should be last because init scripts wait for this file to determine terraform is done provisioning
      "echo '${var.network_id}' | sudo tee /opt/quorum/info/network-id.txt",
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# QUORUM VALIDATOR NODES
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "quorum_validator_node" {
  connection {
    # The default username for our AMI
    user = "ubuntu"

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "${var.quorum_node_instance_type}"
  count         = "${var.num_validator_nodes}"

  ami       = "${lookup(var.quorum_amis, var.aws_region)}"
  user_data = "${data.template_file.user_data_quorum.rendered}"

  key_name = "${aws_key_pair.auth.id}"

  iam_instance_profile = "${aws_iam_instance_profile.quorum_node.name}"

  vpc_security_group_ids = ["${aws_security_group.quorum.id}"]
  subnet_id              = "${element(aws_subnet.quorum_cluster.*.id, count.index + var.num_maker_nodes)}"

  tags {
    Name = "quorum-validator-node-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "echo '${aws_s3_bucket.quorum_constellation.id} /opt/quorum/constellation/private/s3fs fuse.s3fs _netdev,allow_other,iam_role 0 0' | sudo tee /etc/fstab",
      "sudo mount -a",
      "echo '${count.index}' | sudo tee /opt/quorum/info/role-index.txt",
      "echo '${var.num_maker_nodes + count.index}' | sudo tee /opt/quorum/info/overall-index.txt",
      "echo '${var.num_maker_nodes + var.num_validator_nodes + var.num_observer_nodes}' | sudo tee /opt/quorum/info/network-size.txt",
      "echo '${var.num_maker_nodes}' | sudo tee /opt/quorum/info/num-makers.txt",
      "echo '${var.num_validator_nodes}' | sudo tee /opt/quorum/info/num-validators.txt",
      "echo '${var.num_observer_nodes}' | sudo tee /opt/quorum/info/num-observers.txt",
      "echo 'validator' | sudo tee /opt/quorum/info/role.txt",
      "echo '${var.vote_threshold}' | sudo tee /opt/quorum/info/vote-threshold.txt",
      "echo '${var.bootnode_cluster_size}' | sudo tee /opt/quorum/info/num-bootnodes.txt",
      # This should be last because init scripts wait for this file to determine terraform is done provisioning
      "echo '${var.network_id}' | sudo tee /opt/quorum/info/network-id.txt",
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# QUORUM OBSERVER NODES
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "quorum_observer_node" {
  connection {
    # The default username for our AMI
    user = "ubuntu"

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "${var.quorum_node_instance_type}"
  count         = "${var.num_observer_nodes}"

  ami       = "${lookup(var.quorum_amis, var.aws_region)}"
  user_data = "${data.template_file.user_data_quorum.rendered}"

  key_name = "${aws_key_pair.auth.id}"

  iam_instance_profile = "${aws_iam_instance_profile.quorum_node.name}"

  vpc_security_group_ids = ["${aws_security_group.quorum.id}"]
  subnet_id              = "${element(aws_subnet.quorum_cluster.*.id, count.index + var.num_maker_nodes + var.num_validator_nodes)}"

  tags {
    Name = "quorum-observer-node-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "echo '${aws_s3_bucket.quorum_constellation.id} /opt/quorum/constellation/private/s3fs fuse.s3fs _netdev,allow_other,iam_role 0 0' | sudo tee /etc/fstab",
      "sudo mount -a",
      "echo '${count.index}' | sudo tee /opt/quorum/info/role-index.txt",
      "echo '${var.num_maker_nodes + var.num_validator_nodes + count.index}' | sudo tee /opt/quorum/info/overall-index.txt",
      "echo '${var.num_maker_nodes + var.num_validator_nodes + var.num_observer_nodes}' | sudo tee /opt/quorum/info/network-size.txt",
      "echo '${var.num_maker_nodes}' | sudo tee /opt/quorum/info/num-makers.txt",
      "echo '${var.num_validator_nodes}' | sudo tee /opt/quorum/info/num-validators.txt",
      "echo '${var.num_observer_nodes}' | sudo tee /opt/quorum/info/num-observers.txt",
      "echo 'observer' | sudo tee /opt/quorum/info/role.txt",
      "echo '${var.vote_threshold}' | sudo tee /opt/quorum/info/vote-threshold.txt",
      "echo '${var.bootnode_cluster_size}' | sudo tee /opt/quorum/info/num-bootnodes.txt",
      # This should be last because init scripts wait for this file to determine terraform is done provisioning
      "echo '${var.network_id}' | sudo tee /opt/quorum/info/network-id.txt",
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH QUORUM NODE WHEN IT'S BOOTING
# This script will configure and start the Consul Agent
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_quorum" {
  template = "${file("${path.module}/user-data/user-data-quorum.sh")}"

  vars {
    vault_dns  = "${aws_lb.quorum_vault.dns_name}"
    vault_port = 8200

    consul_cluster_tag_key   = "${module.consul_cluster.cluster_tag_key}"
    consul_cluster_tag_value = "${module.consul_cluster.cluster_tag_value}"

    vault_cert_bucket = "${aws_s3_bucket.vault_certs.bucket}"
  }

  # user-data needs to download these objects
  depends_on = ["aws_s3_bucket_object.vault_ca_public_key", "aws_s3_bucket_object.vault_public_key", "aws_s3_bucket_object.vault_private_key"]
}

# ---------------------------------------------------------------------------------------------------------------------
# BOOTNODES
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "bootnode" {
  connection {
    # The default username for our AMI
    user = "ubuntu"

    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "${var.bootnode_instance_type}"
  count         = "${var.bootnode_cluster_size}"

  ami       = "${lookup(var.bootnode_amis, var.aws_region)}"
  user_data = "${data.template_file.user_data_bootnode.rendered}"

  key_name = "${aws_key_pair.auth.id}"

  iam_instance_profile = "${aws_iam_instance_profile.quorum_node.name}"

  vpc_security_group_ids = ["${aws_security_group.quorum.id}"]
  subnet_id              = "${element(aws_subnet.quorum_cluster.*.id, count.index)}"

  tags {
    Name = "bootnode-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "echo '${aws_s3_bucket.quorum_constellation.id} /opt/quorum/constellation/private/s3fs fuse.s3fs _netdev,allow_other,iam_role 0 0' | sudo tee /etc/fstab",
      "sudo mount -a",
      "echo '${count.index}' | sudo tee /opt/quorum/info/index.txt",
      "echo '${var.num_maker_nodes + var.num_validator_nodes + var.num_observer_nodes}' | sudo tee /opt/quorum/info/network-size.txt",
      "echo '${var.bootnode_cluster_size}' | sudo tee /opt/quorum/info/num-bootnodes.txt",
      # This should be last because init scripts wait for this file to determine terraform is done provisioning
      "echo '${var.network_id}' | sudo tee /opt/quorum/info/network-id.txt",
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH BOOTNODE WHEN IT'S BOOTING
# This script will configure and start the Consul Agent
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_bootnode" {
  template = "${file("${path.module}/user-data/user-data-bootnode.sh")}"

  vars {
    vault_dns  = "${aws_lb.quorum_vault.dns_name}"
    vault_port = 8200

    consul_cluster_tag_key   = "${module.consul_cluster.cluster_tag_key}"
    consul_cluster_tag_value = "${module.consul_cluster.cluster_tag_value}"

    vault_cert_bucket = "${aws_s3_bucket.vault_certs.bucket}"
  }

  # user-data needs to download these objects
  depends_on = ["aws_s3_bucket_object.vault_ca_public_key", "aws_s3_bucket_object.vault_public_key", "aws_s3_bucket_object.vault_private_key"]
}

# ---------------------------------------------------------------------------------------------------------------------
# QUORUM NODE SECURITY GROUP
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "quorum" {
  name        = "quorum_nodes"
  description = "Used for quorum nodes"
  vpc_id      = "${aws_vpc.quorum_cluster.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Constellation access from self
  ingress {
    from_port = 9000
    to_port   = 9000
    protocol  = "tcp"
    self      = true
  }

  # Quorum access from self
  ingress {
    from_port = 21000
    to_port   = 21000
    protocol  = "tcp"
    self      = true
  }

  # Quorum access from self to rpc port
  ingress {
    from_port = 22000
    to_port   = 22000
    protocol  = "tcp"
    self      = true
  }

  # Bootnode udp access from self
  ingress {
    from_port = 30301
    to_port   = 30301
    protocol  = "udp"
    self      = true
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# QUORUM NODE IAM ROLE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "quorum_node" {
  name = "quorum-node-network-${var.network_id}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
  }]
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# QUORUM NODE IAM POLICY
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "quorum_node" {
  name        = "quorum-node-policy-network-${var.network_id}"
  description = "A policy for quorum nodes"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "ec2:DescribeInstances",
      "ec2:DescribeImages",
      "ec2:DescribeTags",
      "ec2:DescribeSnapshots"
    ],
    "Resource": "*"
  },{
    "Effect": "Allow",
    "Action": ["s3:*"],
    "Resource": [
      "${aws_s3_bucket.quorum_constellation.arn}",
      "${aws_s3_bucket.quorum_constellation.arn}/*"
    ]
  },{
    "Effect": "Allow",
    "Action": ["s3:ListBucket"],
    "Resource": ["${aws_s3_bucket.vault_certs.arn}"]
  },{
    "Effect": "Allow",
    "Action": ["s3:GetObject"],
    "Resource": [
      "${aws_s3_bucket.vault_certs.arn}/ca.crt.pem",
      "${aws_s3_bucket.vault_certs.arn}/vault.crt.pem"
    ]
  }]
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# QUORUM NODE IAM POLICY ATTACHMENT AND INSTANCE PROFILE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "quorum_node" {
  role       = "${aws_iam_role.quorum_node.name}"
  policy_arn = "${aws_iam_policy.quorum_node.arn}"
}

resource "aws_iam_instance_profile" "quorum_node" {
  name = "quorum-node-network-${var.network_id}"
  role = "${aws_iam_role.quorum_node.name}"
}

# ---------------------------------------------------------------------------------------------------------------------
# S3FS BUCKET FOR CONSTELLATION
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "quorum_constellation" {
  bucket_prefix = "quorum-constellation-network-${var.network_id}-"
  force_destroy = "${var.force_destroy_s3_buckets}"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.27.0"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  # ✅ NEW WAY: EKS Access Entries (this gives system:masters)
  access_entries = {
    bms_user_admin = {
      principal_arn = "arn:aws:iam::697227440008:user/bms-user"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_group_defaults = {
    ami_type                              = "AL2023_x86_64_STANDARD"
    instance_types                        = ["t3.small"]
    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    cluster-wg = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t3.small"]
      capacity_type  = "SPOT"
    }
  }

  tags = local.tags
}

include "root" { path = find_in_parent_folders() }
locals { env_config = read_terragrunt_config(find_in_parent_folders("env.hcl")) }

dependency "foundation" { config_path = "../foundation" }

inputs = {
  vpc_cidr = local.env_config.locals.vpc_cidr
}

include "root" { path = find_in_parent_folders() }

dependency "platform" { config_path = "../platform" }

inputs = {
  cluster_name = dependency.platform.outputs.cluster_name
}

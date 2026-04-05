provider "incus" {
  generate_client_certificates = false
  accept_remote_certificate    = false
  default_remote               = "local"

  remote {
    name    = "local"
    address = "unix://"
  }

  # if running tofu from system where incus is not installed
  # https://search.opentofu.org/provider/lxc/incus/latest#specifying-multiple-remotes
}

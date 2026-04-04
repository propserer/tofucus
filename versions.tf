terraform {
  required_version = ">=1.9.1"
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = ">=0.3.1"
    }
  }
}

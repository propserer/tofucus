# OpenTofu Module: Incus Containers

`tofucus` – OpenTofu made for Incus containers.

An OpenTofu configuration that deploys [incus](https://linuxcontainers.org/incus/) containers with
**static IPs, resource limits, and cloud‑init** provisioning.

> [!WARNING]
>
> Only works with incus images that include cloud-init (usually images with `/cloud` in the name)

<!-- TABLE OF CONTENTS -->

## Table Of Contents

<details>
  <summary>Click to expand</summary>

<!-- toc -->

- [Description](#description)
- [Supported Platforms (container images)](#supported-platforms-container-images)
- [Requirements](#requirements)
  - [OpenTofu](#opentofu)
  - [Incus](#incus)
- [Project Structure](#project-structure)
- [Variables](#variables)
- [Usage](#usage)
  - [Quick Start](#quick-start)
- [Outputs](#outputs)
- [How It Works](#how-it-works)
- [Troubleshooting](#troubleshooting)
  - [Container created but cannot SSH](#container-created-but-cannot-ssh)
- [TODO](#todo)
- [License](#license)

<!-- tocstop -->

</details>

<!-- DESCRIPTION -->

## Description

This opentofu configuration will:

- Create multiple containers using a simple map variable
- Assign **static IPv4 addresses** on a bridged network (`incusbr0`)
- Set **CPU and memory** limits per container
- Automatically:
  - Creates a non‑root user
  - Adds SSH key
  - Installs common packages (`curl`, `git`, `openssh-server`, `python3`)
  - Enables and starts SSH
  - Works across **debian/ubuntu, redhat/fedora, and arch linux** if they have an incus cloud image.

<!-- SUPPORTED PLATFORMS -->

## Supported Platforms (container images)

- Supported for **debian/ubuntu, redhat family, and arch linux** using incus cloud images (images
  ending with /cloud). Use incus command `incus image list images:` to search available images.

<!-- REQUIREMENTS -->

## Requirements

### OpenTofu

- OpenTofu >= 1.9.1
- Provider [`lxc/incus`](https://registry.terraform.io/providers/lxc/incus/latest) >= 0.3.1
  (automatically downloaded on `tofu init`)

### Incus

- Incus installed and initialised (`incus admin init`)
- A **bridged network** (default: `incusbr0`) with an available IP range. (`incus network list`)
- A **storage pool** (default: `default`)
- User must have permission to access the incus socket (usually member of the `incus-admin` group)

Cloud images available (example: **debian/12/cloud**)

<!-- Project Structure -->

## Project Structure

```shell
: tree
.
├── main.tf
├── modules
│   └── instances
│       ├── main.tf
│       ├── outputs.tf
│       ├── template
│       │   └── cloud-init.yaml.tftpl
│       ├── variables.tf
│       └── versions.tf
├── outputs.tf
├── provider.tf
├── terraform.tfvars
├── terraform.tfvars.example
├── variables.tf
└── versions.tf
```

<!-- VARIABLES -->

## Variables

Variables are defined in `variables.tf` and can be overridden in `terraform.tfvars`.

| Variable             | Type                             | Required | Description                                                 |
| -------------------- | -------------------------------- | :------: | ----------------------------------------------------------- |
| `incus_instances`    | `map(object({ip, cpu, memory}))` |   yes    | List of container names with IP, CPU cores, memory.         |
| `incus_image`        | `string`                         |   yes    | Image name. (cloud image required. E.G. `debian/12/cloud`). |
| `incus_storage_pool` | `string`                         |   yes    | Storage pool name (e.g. `default`).                         |
| `incus_network`      | `string`                         |   yes    | Network interface (e.g. `incusbr0`).                        |
| `ssh_public_key`     | `string`                         |   yes    | Content of your SSH public key.                             |
| `username`           | `string`                         |   yes    | Non‑root user name inside containers. (default: `incus`)    |
| `timezone`           | `string`                         |    no    | Timezone (default: `UTC`).                                  |

<!-- EXAMPLE -->

**Example** `terraform.tfvars`

```hcl
# terraform.tfvars
incus_instances = {
  "web"  = { ip = "10.150.19.50", cpu = 2, memory = "2GiB" },
  "db"   = { ip = "10.150.19.51", cpu = 1, memory = "1GiB" }
}

incus_image          = "debian/12/cloud"
incus_network        = "incusbr0"
incus_storage_pool   = "default"
ssh_public_key       = "ssh-ed25519 AAAAC3... user@host"
username             = "incus"
timezone             = "Asia/Kuala_Lumpur"
```

<!-- USAGE -->

## Usage

- Clone the project

  Copy the example variables into `terraform.tfvars` and update our SSH key and desired containers

- Initialize opentofu

  ```shell
  tofu init
  ```

- Review the plan

  ```shell
  tofu plan
  ```

- Apply the configuration

  ```shell
  tofu apply -auto-approve
  # or
  tofu apply -var="ssh_public_key=$(cat ~/.ssh/id_ed25519.pub)" -auto-approve
  ```

  After creation, opentofu outputs the container names and ip addresses.

- Wait for cloud‑init to finish (approx. 30 seconds)

- SSH into a container

  ```shell
  ssh incus@10.150.19.50
  ```

- Destroy everything

  ```shell
  tofu destroy -auto-approve
  ```

<!-- QUICK START -->

### Quick Start

```shell
git clone <repo>
cd <repo>
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu apply -auto-approve
```

<!-- OUTPUTS -->

## Outputs

Example output after apply:

```shell
instance_report = [
  "web              -> 10.150.19.50",
  "db               -> 10.150.19.51",
]
reminder = "Container is up! Please wait ~30 seconds for the setup script to finish before SSHing."
```

SSH into container:

```shell
ssh incus@10.150.19.50
```

<!-- HOW IT WORKS -->

## How It Works

- The root [main.tf](main.tf) calls the instances module once per entry in `var.incus_instances`.
- The module `modules/instances/main.tf`:
  - Creates an `incus_instance` resource with the specified **name, image, CPU, memory**.
  - Attaches a root disk device (storage pool) and an **eth0** network device (bridged with static
    IP).
  - Apply a cloud‑init user‑data template (cloud-init.yaml.tftpl).

- Cloud‑init on the container:
  - Creates the user and adds the SSH key.
  - Writes a helper script (/usr/local/bin/setup-lab.sh) that detects the distribution and installs
    packages using apt, dnf, or pacman.
  - Runs the script via `runcmd`.

- The module output shows container names and their assigned IP addresses.

<!-- TROUBLESHOOT -->

## Troubleshooting

### Container created but cannot SSH

- Wait ~30 seconds (cloud-init may still be running)
- Check cloud-init status:

  ```shell
  incus exec <container> -- cloud-init status
  ```

- SSH service not running

  ```shell
  incus exec <container> -- systemctl status ssh
  # or
  incus exec <container> -- systemctl status sshd
  ```

- Check setup logs

  ```shell
  incus exec <container> -- cat /var/log/lab-setup.log
  ```

<!-- TODO -->

## TODO

- [x] Static IP assignment
- [x] Cross‑distribution cloud‑init script
- [x] CPU and memory limits
- [x] Outputs
- [ ] Support for attaching additional volumes
- [ ] Multiple networks

<!-- LICENSE -->

## License

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This is an open source project under the MIT license.

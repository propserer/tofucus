output "instance_report" {
  description = "A clean lists"
  // '%-15s': Text pushed to the left (15 spaces wide). '%' will hold 'name' variable. 's' make it a string.
  // '->': separator
  // '%s': '%' will hold 'ip' variable. 's' make it a string.
  value = [
    for name, ip in local.instance_data : format("%-15s -> %s", name, ip)
  ]
}

// clean up the data
locals {
  instance_data = {
    for name, instance in module.incus_instances : name => instance.container_ip
  }
}

output "reminder" {
  value = "Container is up! Please wait ~30 seconds for the setup script to finish before SSHing."
}

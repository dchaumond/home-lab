locals {
  secrets = jsondecode(file("${path.module}/../../../.env.json"))
}

variable hostname_base {
  type = string
  default = "base"
}

variable "instance_count" {
  type = number
  default = 1
}

variable inventoryFile {
  type = string
}

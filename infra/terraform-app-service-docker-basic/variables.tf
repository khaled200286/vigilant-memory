variable "prefix" {
  type        = string
  description = "The prefix used for all resources in this example"
}

variable "location" {
  type        = string
  description = "The Azure location where all resources in this example should be created"
}

variable "docker_image" {
  type        = string
  description = "The docker image to use for this app, eg.: ghcr.io/atrakic/foo-image"
}

variable "docker_image_tag" {
  type        = string
  description = "The docker image tag to use, eg.: latest"
}

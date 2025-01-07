###################
### Variables
###################

variable REGISTRY {
  default = ""
}

# Comma delimited list of tags
variable TAGS {
  default = "latest"
}

variable CI {
  default = false
}

variable PUSH {
  default = false
}

###################
### Functions
###################

function "get_tags" {
  params = [image]
  result = [for tag in split(",", TAGS) : join("/", compact([REGISTRY, "${image}:${tag}"]))]
}

function "get_platforms_multiarch" {
  params = []
  result = (CI || PUSH) ? ["linux/amd64"] : []
}

function "get_output" {
  params = []
  result = (CI || PUSH) ? ["type=registry"] : ["type=docker"]
}

###################
### Groups
###################

group "default" {
  targets = [
    "jetstream-controller"
  ]
}

###################
### Targets
###################

target "goreleaser" {
  contexts = {
    src = "."
  }
  args = {
    CI = CI
    PUSH = PUSH
    GITHUB_TOKEN = ""
  }
  dockerfile = "cicd/Dockerfile_goreleaser"
}

target "jetstream-controller" {
  contexts = {
    build   = "target:goreleaser"
    assets  = "cicd/assets"
  }
  args = {
    GO_APP = "jetstream-controller"
  }
  dockerfile  = "cicd/Dockerfile"
  platforms   = get_platforms_multiarch()
  tags        = get_tags("nack")
  output      = get_output()
}

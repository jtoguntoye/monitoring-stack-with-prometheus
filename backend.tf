terraform {
  cloud {
    organization = "city-allies"

    workspaces {
      name = "PROMETHEUS-PROJECT"
    }
  }
}
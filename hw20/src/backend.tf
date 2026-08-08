terraform {
  backend "s3" {
    bucket       = "danit-hw20-896680309229-eu-central-1-an"
    key          = "user-a/hw20/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

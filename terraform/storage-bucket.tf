provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region = "${var.region}"
}
module "tested-bucket" {
  source = "SweetOps/storage-bucket/google"
  version = "0.1.1"
  name = ["tested-bucket-1", "tested-bucket-2"]
}
output storage-bucket_url {
  value = "${module.tested-bucket.url}"
}

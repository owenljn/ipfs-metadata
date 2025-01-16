resource "aws_cloudwatch_log_group" "ipfs_app" {
  name              = "/ecs/ipfs-app"
  retention_in_days = 7
}

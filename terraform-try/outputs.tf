output "nginx_public_ip" {
  description = "Getting the elastic ip of the nginx instance"
  value       = aws_eip.nginx_eip.public_ip
}
output "app_private_ip" {
  description = "Getting the private ip of the node.js app"
  value       = aws_instance.app_server.private_ip
}
output "mysql_private_ip" {
  description = "Getting the private ip od the mysql DB"
  value       = aws_instance.nodejs_server.private_ip
}


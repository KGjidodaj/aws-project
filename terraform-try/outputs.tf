output "nginx_public_ip" {
  description = "Getting the dynamixally generated public ip of the nginx instance"
  value       = aws_instance.nginx_server.public_ip
}
output "app_private_ip" {
  description = "Getting the private ip of the node.js app"
  value       = aws_instance.app_server.private_ip
}
output "mysql_private_ip" {
  description = "Getting the private ip od the mysql DB"
  value       = aws_instance.nodejs_server.private_ip
}


#Outputting the nginx bastion public ip alongside the two EC2 private ips that are used in the inventory/groups_var/all.yml file for ansible
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
  value       = aws_instance.mysql_server.private_ip
}


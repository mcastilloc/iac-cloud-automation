output "ec2_instance_id" {
  description = "ID de la instancia EC2 simulada"
  value       = aws_instance.sre_web_server.id
}

output "ec2_private_ip" {
  description = "Dirección IP privada de la instancia EC2"
  value       = aws_instance.sre_web_server.private_ip
}

output "vpc_id" {
  description = "ID de la VPC principal"
  value       = aws_vpc.sre_vpc.id
}

output "subnet_id" {
  description = "ID de la Subred pública"
  value       = aws_subnet.sre_subnet.id
}

output "s3_bucket_name" {
  description = "Nombre del Bucket S3 de respaldos"
  value       = aws_s3_bucket.sre_backups.bucket
}
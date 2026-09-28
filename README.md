# ☁️ IaC Automation Stack (Terraform + LocalStack + GitHub Actions)

Repositorio de Infraestructura como Código (IaC) para la automatización, aprovisionamiento y validación continua de recursos en la nube. Diseñado bajo estándares SRE / DevOps para ejecutarse de forma $100\%$ local en Rocky Linux 10 (WSL2) emulando los servicios de AWS con LocalStack y validado automáticamente con GitHub Actions.

# 🏗️ Arquitectura del Proyecto
```text
  +-----------------------+         +-------------------------------+
  |    GitHub Actions     | <------ |  Código Terraform (main.tf)   |
  | (fmt, init, validate) |         |  VPC, Subnet, Bucket S3       |
  +-----------------------+         +---------------+---------------+
                                                    |
                                                    v
                                   +--------------------------------+
                                   |       LocalStack Docker        |
                                   |   (http://localhost:4566)      |
                                   +--------------------------------+

```

# Configuración WSL

```cmd
wsl --install --from-file Rocky-10-WSL-Base.latest.x86_64.wsl --name RockyIAC
```

```bash
sudo dnf update
sudo dnf install dnf-utils dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin terraform awscli
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker
```

# 🧩 Recursos Aprovisionados

- AWS VPC: Red virtual (10.0.0.0/16) etiquetada como sre-lab-vpc.
- AWS Subnet: Subred pública (10.0.1.0/24) en la zona us-east-1a.
- AWS S3 Bucket: Almacenamiento local de objetos (sre-system-backups-local).

# 🛠️ Requisitos del Entorno Local

- OS: Rocky Linux 10 sobre WSL2.
- Docker Engine: v29.x + Docker Compose Plugin.
- Terraform: v1.16+ (compatibilidad verificada desde v1.8.5).
- AWS CLI: Para verificación y consulta de la infraestructura local.

# 🚀 Guía de Despliegue Local Paso a Paso

1. Clonar el Repositorio
```bash
git clone https://github.com/mcastilloc/iac-cloud-automation.git
cd iac-cloud-automation
```

2. Configurar Secretos Localmente

Crea un archivo `.env` en la raíz del proyecto para definir tu token de LocalStack sin exponerlo en Git:
```bash
echo "LOCALSTACK_AUTH_TOKEN=tu_token_aqui" > .env
```
> Nota: El archivo `.env` está incluido en `.gitignore` para prevenir fugas de secretos (secrets leak).

3. Iniciar la Nube Emulada (LocalStack)
```bash
# Levantar el contenedor de LocalStack
docker compose up -d

# Verificar el estado de salud de los servicios S3 y EC2
curl http://localhost:4566/_localstack/health
```

4. Aprovisionar Infraestructura con Terraform
```bash
cd terraform

# Inicializar proveedores y módulos
terraform init

# Generar y revisar el plan de ejecución
terraform plan

# Aplicar los cambios
terraform apply -auto-approve
```

# 🔍 Verificación de Recursos con AWS CLI

Exporta credenciales ficticias en la sesión de terminal para consultar los endpoints de LocalStack:
```bash
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"
```

Consultar Bucket S3
```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

Consultar VPCs Creadas
```bash
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs --output table
```

Consultar Subredes Creadas
```bash
aws --endpoint-url=http://localhost:4566 ec2 describe-subnets --output table
```

# 🤖 Integration Continua (CI/CD Pipeline)

Cada push o pull_request a la rama main dispara automáticamente el flujo de trabajo en .github/workflows/iac-ci.yml, asegurando los siguientes controles de calidad:

- `terraform fmt -check`: Garantiza que el código cumpla con las convenciones de formato estándar.
- `terraform init -backend=false`: Inicializa los binarios del proveedor sin requerir un estado remoto.
- `terraform validate`: Comprueba la validez sintáctica y la coherencia lógica de las definiciones HCL.

🧹 Limpieza del Entorno

Para destruir la infraestructura y detener los servicios emulados:
```bash
# Destruir recursos gestionados por Terraform
cd terraform
terraform destroy -auto-approve

# Detener LocalStack
cd ..
docker compose down -v
```
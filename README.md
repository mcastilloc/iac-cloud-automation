# ☁️ IaC Automation Stack (Terraform + LocalStack + GitHub Actions)

Repositorio de **Infraestructura como Código (IaC)** para la automatización, aprovisionamiento y validación continua de recursos en la nube. Diseñado bajo estándares **SRE / DevOps** para ejecutarse de forma $100\%$ local en **Rocky Linux 10 (WSL2)** emulando los servicios de AWS con **LocalStack** y validado automáticamente con **GitHub Actions**.

## 🏗️ Arquitectura del Proyecto

```
  +-----------------------+         +---------------------------------------+
  |    GitHub Actions     | <------ |        Código Terraform (HCL)         |
  | (fmt, init, validate) |         | VPC, Subnet, SG, EC2, S3, outputs.tf  |
  +-----------------------+         +-------------------+-------------------+
                                                        |
                                                        v
                                   +----------------------------------------+
                                   |           LocalStack Docker            |
                                   |       (http://localhost:4566)          |
                                   |  +----------------------------------+  |
                                   |  | VPC (10.0.0.0/16)                |  |
                                   |  |  └── Subnet (10.0.1.0/24)        |  |
                                   |  |       └── SG (22, 80)           |  |
                                   |  |            └── EC2 (Nginx)       |  |
                                   |  | S3 Bucket (Backups)            |  |
                                   |  +----------------------------------+  |
                                   +----------------------------------------+
```

### Configuración WSL

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

### 🧩 Recursos Aprovisionados

* **AWS VPC**: Red virtual (`10.0.0.0/16`) etiquetada como `sre-lab-vpc`.
* **AWS Subnet**: Subred pública (`10.0.1.0/24`) en `us-east-1a`.
* **AWS Security Group**: Firewall de red que permite entrada en puertos 22 (SSH) y 80 (HTTP).
* **AWS EC2 Instance**: Servidor web simulado (`t2.micro`) provisionado automáticamente mediante `user_data_base64` (instalación y arranque de Nginx).
* **AWS S3 Bucket**: Almacenamiento local de objetos (`sre-system-backups-local`).
* **Outputs terraform**: Exposición de métricas e identificadores clave (`ec2_instance_id`, `ec2_private_ip`, `vpc_id`, `subnet_id`, `s3_bucket_name`).

---

## 🛠️ Requisitos del Entorno Local

* **OS**: Rocky Linux 10 sobre WSL2.
* **Docker Engine**: v29.x + Docker Compose Plugin.
* **Terraform**: v1.8+ (soporte verificado con v1.8.5 / v1.16+).
* **AWS CLI**: v2.x para consulta e inspección del entorno local.

---

## 🚀 Guía de Despliegue Local Paso a Paso

### 1. Clonar el Repositorio

```bash
git clone https://github.com/mcastilloc/iac-cloud-automation.git
cd iac-cloud-automation
```

### 2. Configurar Secretos Localmente

Crea un archivo `.env` en la raíz del proyecto para definir tu token de LocalStack sin exponerlo en Git:

```bash
echo "LOCALSTACK_AUTH_TOKEN=tu_token_aqui" > .env
```

> **Nota:** El archivo `.env` está incluido en `.gitignore` para prevenir fugas de secretos (*secrets leak*).

### 3. Iniciar la Nube Emulada (LocalStack)

```bash
# Levantar el contenedor de LocalStack
docker compose up -d

# Verificar el estado de salud de los servicios S3 y EC2
curl http://localhost:4566/_localstack/health
```

### 4. Aprovisionar Infraestructura con Terraform

```bash
cd terraform

# Inicializar proveedores y módulos
terraform init

# Validar formato y sintaxis
terraform fmt
terraform validate

# Generar y aplicar la infraestructura
terraform apply -auto-approve
```

Al finalizar el `apply`, Terraform mostrará las salidas configuradas en `outputs.tf`:

```text
Outputs:

ec2_instance_id = "i-aebc73c97a9215c56"
ec2_private_ip = "10.0.1.5"
s3_bucket_name = "sre-system-backups-local"
subnet_id = "subnet-96da9d9ab9687a15f"
vpc_id = "vpc-b4cd8b09c9e9d0da5"
```

---

## 🔍 Verificación de Recursos con AWS CLI

Exporta credenciales ficticias en tu sesión de terminal para consultar los endpoints de LocalStack:

```bash
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"
```

### 1. Consultar Bucket S3

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

### 2. Consultar VPCs y Subredes

```bash
# Lista de VPCs
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs --output table

# Lista de Subredes
aws --endpoint-url=http://localhost:4566 ec2 describe-subnets --output table
```

### 3. Consultar Security Groups

```bash
aws --endpoint-url=http://localhost:4566 ec2 describe-security-groups --group-names sre-web-sg --output table
```

### 4. Consultar Instancias EC2 y Atributos de UserData

```bash
# Estado general de las instancias EC2
aws --endpoint-url=http://localhost:4566 ec2 describe-instances \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress,SubnetId]" \
  --output table

# Inspeccionar el UserData codificado en Base64
aws --endpoint-url=http://localhost:4566 ec2 describe-instance-attribute \
  --instance-id <TU_INSTANCE_ID> \
  --attribute userData
```

---

## 🤖 Integración Continua (CI/CD Pipeline)

Cada `push` o `pull_request` a la rama `main` dispara automáticamente el flujo de trabajo en `.github/workflows/iac-ci.yml`, asegurando los siguientes controles de calidad:

1. **`terraform fmt -check`**: Garantiza que el código cumpla con las convenciones de formato estándar.
2. **`terraform init -backend=false`**: Inicializa los binarios del proveedor sin requerir un estado remoto.
3. **`terraform validate`**: Comprueba la validez sintáctica y la coherencia lógica de las definiciones HCL.

---

## 🧹 Limpieza del Entorno

Para destruir la infraestructura y detener los servicios emulados:

```bash
# Destruir recursos gestionados por Terraform
cd terraform
terraform destroy -auto-approve

# Detener LocalStack y limpiar volúmenes
cd ..
docker compose down -v
```
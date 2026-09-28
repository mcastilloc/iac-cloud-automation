# ☁️ IaC Cloud Automation (Terraform + LocalStack)

Proyecto de **Infraestructura como Código (IaC)** orientado a SRE/DevOps para el aprovisionamiento automatizado de recursos de red y almacenamiento en **AWS (emulado con LocalStack)** mediante **Terraform** y validación continua en **GitHub Actions**.

---

## 🏗️ Arquitectura de Trabajo

```
   +------------------+         +------------------+
   |  GitHub Actions  | <------ | Código Terraform |
   |  (Linter & CI)   |         |    (main.tf)     |
   +------------------+         +--------+---------+
                                         |
                                         v
                                +------------------+
                                |    LocalStack    |
                                |  (VPC, S3, EC2)  |
                                +------------------+
```

---

## 🛠️ Despliegue en Entorno Local (Rocky Linux / WSL)

### 1. Requisitos
- Docker y Docker Compose
- Terraform >= 1.5.0

### 2. Iniciar Servicios
```bash
# Levantar la nube emulada
docker compose up -d

# Inicializar y aplicar infraestructura
cd terraform
terraform init
terraform apply -auto-approve
```
#!/bin/bash
set -e

# Configuración
REPO_NAME="microservicio-pagos"
GITHUB_REPO="https://github.com/keaguirre/disenoInfra-EA3-POC.git"
TAG="latest"
REGION="us-east-1"  # Cambia si estás en otra región

# Eliminar clon anterior si existe
rm -rf disenoInfra-EA3-POC

# Clonar repositorio
git clone $GITHUB_REPO

# Obtener cuenta AWS y URL del repositorio ECR
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"

# Login en ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

# Build y push
docker build -t $REPO_NAME:$TAG ./disenoInfra-EA3-POC
docker tag $REPO_NAME:$TAG $ECR_URL:$TAG
docker push $ECR_URL:$TAG
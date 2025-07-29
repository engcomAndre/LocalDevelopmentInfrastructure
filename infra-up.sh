#!/bin/bash

set -e

echo "🚀 Iniciando implantação da infraestrutura..."

echo "📦 Implantando MongoDB..."
./k8s/init/mongo-init/mongo-infra-up.sh

echo "☁️  Implantando LocalStack..."
./k8s/init/localstack-init/localstack-infra-up.sh

echo "🔐 Implantando Keycloak..."
./k8s/init/keycloak-init/keycloak-infra-up.sh

echo "🔍 Implantando SonarQube..."
./k8s/init/sonarqube-init/sonarqube-infra-up.sh

echo "✅ Infraestrutura implantada com sucesso!"

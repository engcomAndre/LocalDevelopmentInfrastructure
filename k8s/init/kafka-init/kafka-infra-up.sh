#!/bin/bash

set -e

echo "🚀 Iniciando implantação do Kafka com KRaft..."

# Obter o diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"

# Aplicar ConfigMap
echo "📋 Aplicando ConfigMap do Kafka..."
kubectl apply -f "$PROJECT_ROOT/k8s/kafka/configmap.yaml"

# Aplicar Service
echo "🔌 Aplicando Service do Kafka..."
kubectl apply -f "$PROJECT_ROOT/k8s/kafka/service.yaml"

# Aplicar Deployment
echo "📦 Aplicando Deployment do Kafka..."
kubectl apply -f "$PROJECT_ROOT/k8s/kafka/deployment.yaml"

# Aguardar o Kafka estar pronto
echo "⏳ Aguardando o Kafka estar pronto..."
kubectl wait --for=condition=available --timeout=300s deployment/kafka

echo "✅ Kafka com KRaft implantado com sucesso!" 
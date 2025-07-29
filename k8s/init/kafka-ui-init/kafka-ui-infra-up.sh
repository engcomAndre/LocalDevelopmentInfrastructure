#!/bin/bash

set -e

echo "🚀 Iniciando implantação do Kafka UI..."

# Obter o diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"

# Aplicar Service
echo "🔌 Aplicando Service do Kafka UI..."
kubectl apply -f "$PROJECT_ROOT/k8s/kafka/kafka-ui-service.yaml"

# Aplicar Deployment
echo "📦 Aplicando Deployment do Kafka UI..."
kubectl apply -f "$PROJECT_ROOT/k8s/kafka/kafka-ui-deployment.yaml"

# Aguardar o Kafka UI estar pronto
echo "⏳ Aguardando o Kafka UI estar pronto..."
kubectl wait --for=condition=available --timeout=300s deployment/kafka-ui

echo "✅ Kafka UI implantado com sucesso!"
echo "🌐 Kafka UI disponível em: http://localhost:8081 (após port-forward)" 
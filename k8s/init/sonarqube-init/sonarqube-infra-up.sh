#!/bin/bash

set -e

# Carregar variáveis de ambiente do arquivo local.env
echo "📋 Carregando variáveis de ambiente..."
if [ -f "k8s/config/local.env" ]; then
  export $(cat k8s/config/local.env | grep -v '^#' | xargs)
  echo "✅ Variáveis de ambiente carregadas de k8s/config/local.env"
else
  echo "⚠️  Arquivo k8s/config/local.env não encontrado. Usando valores padrão."
  # Valores padrão caso o arquivo não exista
  export SONAR_TOKEN="sqa_cf49a374b2da1592ca43f7672a3d3a5b9010fa76"
fi

# Remover recursos antigos do SonarQube
echo "🔁 Removendo recursos antigos do SonarQube (forçado)..."
kubectl delete pod -l app=sonarqube --ignore-not-found --force --grace-period=0
kubectl delete pod -l app=sonarqube-postgres --ignore-not-found --force --grace-period=0

# Verificação: recursos removidos
sleep 2
echo "🔎 Verificando se pods antigos foram removidos..."
kubectl get pods -l app=sonarqube
kubectl get pods -l app=sonarqube-postgres

# Subir PostgreSQL do SonarQube
echo "📦 Subindo PostgreSQL do SonarQube..."
kubectl apply -f k8s/sonarqube/postgres-deployment.yaml
kubectl apply -f k8s/sonarqube/postgres-service.yaml

# Verificação: PostgreSQL
sleep 3
echo "🔎 Verificando PostgreSQL do SonarQube..."
kubectl get deployment sonarqube-postgres
kubectl get pods -l app=sonarqube-postgres
kubectl get svc sonarqube-postgres

# Aguardar PostgreSQL estar pronto
echo "⏳ Aguardando PostgreSQL estar pronto..."
sleep 10

# Subir Deployment do SonarQube
echo "📦 Subindo Deployment do SonarQube..."
kubectl apply -f k8s/sonarqube/deployment.yaml

# Verificação: Deployment e Pod
sleep 3
echo "🔎 Verificando Deployment e Pod do SonarQube..."
kubectl get deployment sonarqube
kubectl get pods -l app=sonarqube

# Criar Service do SonarQube
echo "🌐 Criando Service do SonarQube..."
kubectl apply -f k8s/sonarqube/service.yaml

# Verificação: Service
sleep 1
echo "🔎 Verificando Service do SonarQube..."
kubectl get svc sonarqube

# Redirecionar porta local 9000 para o SonarQube no cluster
echo "🔁 Redirecionando porta local 9000 para o SonarQube no cluster..."
# Mata port-forward antigo se existir
lsof -ti:9000 | xargs -r kill
sleep 1
# Mata processos kubectl port-forward presos
pkill -f "kubectl port-forward service/sonarqube 9000:9000" 2>/dev/null || true
sleep 1
kubectl port-forward service/sonarqube 9000:9000 > /dev/null 2>&1 &
sleep 2
echo "✅ Porta 9000 do SonarQube exposta localmente."

# Verificação: port-forward ativo
echo "🔎 Verificando se a porta 9000 está escutando localmente..."
lsof -i :9000

# Aguardar SonarQube iniciar e exibir logs
echo "⏳ Aguardando SonarQube iniciar..."
sleep 60
kubectl logs deployment/sonarqube --tail=20

# Verificação: conexão via curl
echo "🔎 Testando conexão local via curl..."
if command -v curl > /dev/null; then
  curl -s http://localhost:9000/api/system/status || { echo "❌ Falha ao conectar ao SonarQube via curl."; exit 1; }
else
  echo "⚠️  curl não está instalado. Pule o teste de conexão."
fi

echo "✅ SonarQube implantado e verificado."

# Exibir informações de conexão
echo "\n🔗 Informações de conexão SonarQube:"
echo "Web Interface: http://localhost:9000"
echo "Default Credentials: admin/admin"
echo "Token: ${SONAR_TOKEN}"
echo "PostgreSQL: sonarqube-postgres:5432" 
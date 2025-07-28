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
  export KEYCLOAK_ADMIN_USERNAME="admin"
  export KEYCLOAK_ADMIN_PASSWORD="admin_password"
  export KEYCLOAK_HOST="localhost"
  export KEYCLOAK_PORT="8888"
  export KEYCLOAK_REALM="ms-auth-core-service-realm"
  export KEYCLOAK_CLIENT_ID="ms-auth-core-service"
  export KEYCLOAK_CLIENT_SECRET="ms-auth-core-service-secret"
fi

# Remover recursos antigos do Keycloak
echo "🔁 Removendo recursos antigos do Keycloak (forçado)..."
kubectl delete pod -l app=keycloak --ignore-not-found --force --grace-period=0
kubectl delete configmap keycloak-init-realm --ignore-not-found

# Verificação: recursos removidos
sleep 2
echo "🔎 Verificando se pods antigos foram removidos..."
kubectl get pods -l app=keycloak

# Gerar e aplicar realm de inicialização do Keycloak
echo "📂 Gerando e aplicando realm de inicialização do Keycloak..."
REALM_FILE="./k8s/init/keycloak-init/realm-export.json"

if [ -f "$REALM_FILE" ]; then
  kubectl create configmap keycloak-init-realm \
    --from-file=realm-export.json=$REALM_FILE
  echo "✅ Realm de inicialização aplicado como ConfigMap."
else
  echo "⚠️  Arquivo realm-export.json não encontrado em k8s/init/keycloak-init/. Pulando criação do ConfigMap."
fi

# Verificação: ConfigMap
sleep 1
echo "🔎 Verificando ConfigMap..."
kubectl get configmap keycloak-init-realm

# Subir Deployment do Keycloak
echo "📦 Subindo Deployment do Keycloak..."
kubectl apply -f k8s/keycloak/deployment.yaml

# Verificação: Deployment e Pod
sleep 3
echo "🔎 Verificando Deployment e Pod do Keycloak..."
kubectl get deployment keycloak
kubectl get pods -l app=keycloak

# Criar Service do Keycloak
echo "🌐 Criando Service do Keycloak..."
kubectl apply -f k8s/keycloak/service.yaml

# Verificação: Service
sleep 1
echo "🔎 Verificando Service do Keycloak..."
kubectl get svc keycloak

# Redirecionar porta local 8888 para o Keycloak no cluster
echo "🔁 Redirecionando porta local ${KEYCLOAK_PORT} para o Keycloak no cluster..."
# Mata port-forward antigo se existir
lsof -ti:${KEYCLOAK_PORT} | xargs -r kill
sleep 1
# Mata processos kubectl port-forward presos
pkill -f "kubectl port-forward service/keycloak ${KEYCLOAK_PORT}:8080" 2>/dev/null || true
sleep 1
kubectl port-forward service/keycloak ${KEYCLOAK_PORT}:8080 > /dev/null 2>&1 &
sleep 2
echo "✅ Porta ${KEYCLOAK_PORT} do Keycloak exposta localmente."

# Verificação: port-forward ativo
echo "🔎 Verificando se a porta ${KEYCLOAK_PORT} está escutando localmente..."
lsof -i :${KEYCLOAK_PORT}

# Aguardar Keycloak iniciar e exibir logs
echo "⏳ Aguardando Keycloak iniciar..."
sleep 30
kubectl logs deployment/keycloak --tail=20

# Verificação: conexão via curl
echo "🔎 Testando conexão local via curl..."
if command -v curl > /dev/null; then
  curl -s http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}/health || { echo "❌ Falha ao conectar ao Keycloak via curl."; exit 1; }
else
  echo "⚠️  curl não está instalado. Pule o teste de conexão."
fi

echo "✅ Keycloak implantado e verificado."

# Exibir informações de conexão
echo "\n🔗 Informações de conexão Keycloak:"
echo "Admin Console: http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}/admin"
echo "Realm: ${KEYCLOAK_REALM}"
echo "Client ID: ${KEYCLOAK_CLIENT_ID}"
echo "Client Secret: ${KEYCLOAK_CLIENT_SECRET}"
echo "Admin Username: ${KEYCLOAK_ADMIN_USERNAME}"
echo "Admin Password: ${KEYCLOAK_ADMIN_PASSWORD}" 
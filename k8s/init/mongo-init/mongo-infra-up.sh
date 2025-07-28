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
  export MONGO_INITDB_ROOT_USERNAME="root_application_user"
  export MONGO_INITDB_ROOT_PASSWORD="root_securepassword123"
  export MONGO_INITDB_DATABASE="raffles_db"
  export MONGO_APPLICATION_USERNAME="application_user"
  export MONGO_APPLICATION_PASSWORD="securepassword123"
  export MONGO_APPLICATION_HOST="localhost"
  export MONGO_APPLICATION_PORT="27017"
  export MONGO_APPLICATION_AUTH_SOURCE="raffles_db"
  export MONGO_APPLICATION_DATABASE="raffles_db"
fi

# Remover recursos antigos do MongoDB
echo "🔁 Removendo recursos antigos do MongoDB (forçado)..."
kubectl delete pod -l app=mongo --ignore-not-found --force --grace-period=0
kubectl delete pvc mongo-pvc --ignore-not-found
kubectl delete configmap mongo-init-scripts --ignore-not-found

# Verificação: recursos removidos
sleep 2
echo "🔎 Verificando se pods antigos foram removidos..."
kubectl get pods -l app=mongo

# Criar Secrets e ConfigMaps
echo "🔐 Criando Secrets e ConfigMaps..."
kubectl apply -f k8s/config/app-secret.yaml
kubectl apply -f k8s/config/app-configmap.yaml

# Verificação: ConfigMaps e Secrets
sleep 1
echo "🔎 Verificando ConfigMaps e Secrets..."
kubectl get configmap app-config
kubectl get secret app-secret

# Gerar e aplicar scripts de inicialização do MongoDB
echo "📂 Gerando e aplicando scripts de inicialização do MongoDB..."
INIT_DIR="./k8s/init/mongo-init"
if [ -d "$INIT_DIR" ] && compgen -G "$INIT_DIR/*.js" > /dev/null; then
  kubectl create configmap mongo-init-scripts \
    --from-file=01-create-app-user.js=$INIT_DIR/01-create-app-user.js \
    --from-file=02-create-raffles-collection.js=$INIT_DIR/02-create-raffles-collection.js
  echo "✅ Scripts de inicialização aplicados como ConfigMap."
else
  echo "⚠️  Nenhum script .js encontrado em $INIT_DIR. Pulando criação do ConfigMap."
fi

# Verificação: ConfigMap de scripts
sleep 1
echo "🔎 Verificando ConfigMap de scripts..."
kubectl get configmap mongo-init-scripts

# Criar PVC do MongoDB
echo "💾 Criando PVC do MongoDB..."
kubectl apply -f k8s/mongo/pvc.yaml

# Verificação: PVC
sleep 1
echo "🔎 Verificando PVC..."
kubectl get pvc mongo-pvc

# Subir Deployment do MongoDB
echo "📦 Subindo Deployment do MongoDB..."
kubectl apply -f k8s/mongo/deployment.yaml

# Verificação: Deployment e Pod
sleep 3
echo "🔎 Verificando Deployment e Pod do MongoDB..."
kubectl get deployment mongo
kubectl get pods -l app=mongo

# Criar Service do MongoDB
echo "🌐 Criando Service do MongoDB..."
kubectl apply -f k8s/mongo/service.yaml

# Verificação: Service
sleep 1
echo "🔎 Verificando Service do MongoDB..."
kubectl get svc mongo

# Redirecionar porta local 27017 para o MongoDB no cluster
echo "🔁 Redirecionando porta local ${MONGO_APPLICATION_PORT} para o MongoDB no cluster..."
# Mata port-forward antigo se existir
lsof -ti:${MONGO_APPLICATION_PORT} | xargs -r kill
sleep 1
# Mata processos kubectl port-forward presos
pkill -f "kubectl port-forward service/mongo ${MONGO_APPLICATION_PORT}:27017" 2>/dev/null || true
sleep 1
kubectl port-forward service/mongo ${MONGO_APPLICATION_PORT}:27017 > /dev/null 2>&1 &
sleep 2
echo "✅ Porta ${MONGO_APPLICATION_PORT} do MongoDB exposta localmente. Use mongodb://${MONGO_APPLICATION_HOST}:${MONGO_APPLICATION_PORT} no Compass."

# Verificação: port-forward ativo
echo "🔎 Verificando se a porta ${MONGO_APPLICATION_PORT} está escutando localmente..."
lsof -i :${MONGO_APPLICATION_PORT}

# Verificação interna: porta 27017 no pod
POD_NAME=$(kubectl get pods -l app=mongo -o jsonpath='{.items[0].metadata.name}')
echo "🔎 Verificando internamente no pod $POD_NAME se a porta 27017 está escutando..."
kubectl exec "$POD_NAME" -- sh -c 'command -v netstat && netstat -tlnp || (command -v ss && ss -tlnp) || echo "netstat/ss não disponível"'

# Aguardar MongoDB iniciar e exibir logs
echo "⏳ Aguardando MongoDB iniciar..."
sleep 10
kubectl logs deployment/mongo

# Verificação: conexão via mongosh
echo "🔎 Testando conexão local via mongosh..."
if command -v mongosh > /dev/null; then
  mongosh --eval "db.adminCommand('ping')" --host ${MONGO_APPLICATION_HOST} --port ${MONGO_APPLICATION_PORT} || { echo "❌ Falha ao conectar ao MongoDB via mongosh."; exit 1; }
else
  echo "⚠️  mongosh não está instalado. Pule o teste de conexão."
fi

echo "✅ MongoDB implantado, verificado e scripts executados."

# Exibir string de conexão usando variáveis de ambiente
CONN_STR="mongodb://${MONGO_APPLICATION_USERNAME}:${MONGO_APPLICATION_PASSWORD}@${MONGO_APPLICATION_HOST}:${MONGO_APPLICATION_PORT}/${MONGO_APPLICATION_DATABASE}?authSource=${MONGO_APPLICATION_AUTH_SOURCE}"
echo "\n🔗 String de conexão MongoDB:"
echo "$CONN_STR" 
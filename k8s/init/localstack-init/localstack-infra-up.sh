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
  export AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="AWS_SECRET_ACCESS_KEY"
  export AWS_ROOT_USER="AWS_ROOT_USER"
  export AWS_ROOT_PASSWORD="AWS_ROOT_PASSWORD"
  export AWS_S3_BUCKET="files"
  export AWS_REGION="us-east-1"
  export AWS_PORT="4566"
  export AWS_CONSOLE_PORT="4566"
  export AWS_S3_ENDPOINT="http://localhost:4566"
fi

# Remover recursos antigos do LocalStack
echo "🔁 Removendo recursos antigos do LocalStack (forçado)..."
kubectl delete pod -l app=localstack --ignore-not-found --force --grace-period=0
kubectl delete configmap localstack-init-scripts --ignore-not-found
kubectl delete configmap localstack-init-files --ignore-not-found

# Verificação: recursos removidos
sleep 2
echo "🔎 Verificando se pods antigos foram removidos..."
kubectl get pods -l app=localstack

# Gerar e aplicar scripts de inicialização do LocalStack
echo "📂 Gerando e aplicando scripts de inicialização do LocalStack..."
INIT_DIR="./k8s/init/localstack-init"
FILES_DIR="./k8s/init/localstack-init/files"

if [ -d "$INIT_DIR" ] && compgen -G "$INIT_DIR/*.sh" > /dev/null; then
  kubectl create configmap localstack-init-scripts \
    --from-file=01-create-s3-bucket.sh=$INIT_DIR/01-create-s3-bucket.sh \
    --from-file=02-create-iam-user.sh=$INIT_DIR/02-create-iam-user.sh
  echo "✅ Scripts de inicialização aplicados como ConfigMap."
else
  echo "⚠️  Nenhum script .sh encontrado em $INIT_DIR. Pulando criação do ConfigMap."
fi

# Gerar e aplicar arquivos de inicialização
if [ -d "$FILES_DIR" ] && compgen -G "$FILES_DIR/*" > /dev/null; then
  kubectl create configmap localstack-init-files \
    --from-file=config.json=$FILES_DIR/config.json \
    --from-file=sample.txt=$FILES_DIR/sample.txt
  echo "✅ Arquivos de inicialização aplicados como ConfigMap."
else
  echo "⚠️  Nenhum arquivo encontrado em $FILES_DIR. Pulando criação do ConfigMap."
fi

# Verificação: ConfigMaps
sleep 1
echo "🔎 Verificando ConfigMaps..."
kubectl get configmap localstack-init-scripts
kubectl get configmap localstack-init-files

# Subir Deployment do LocalStack
echo "📦 Subindo Deployment do LocalStack..."
kubectl apply -f k8s/localstack/deployment.yaml

# Verificação: Deployment e Pod
sleep 3
echo "🔎 Verificando Deployment e Pod do LocalStack..."
kubectl get deployment localstack
kubectl get pods -l app=localstack

# Criar Service do LocalStack
echo "🌐 Criando Service do LocalStack..."
kubectl apply -f k8s/localstack/service.yaml

# Verificação: Service
sleep 1
echo "🔎 Verificando Service do LocalStack..."
kubectl get svc localstack

# Redirecionar porta local 4566 para o LocalStack no cluster
echo "🔁 Redirecionando porta local ${AWS_PORT} para o LocalStack no cluster..."
# Mata port-forward antigo se existir
lsof -ti:${AWS_PORT} | xargs -r kill
sleep 1
# Mata processos kubectl port-forward presos
pkill -f "kubectl port-forward service/localstack ${AWS_PORT}:4566" 2>/dev/null || true
sleep 1
kubectl port-forward service/localstack ${AWS_PORT}:4566 > /dev/null 2>&1 &
sleep 2
echo "✅ Porta ${AWS_PORT} do LocalStack exposta localmente."

# Verificação: port-forward ativo
echo "🔎 Verificando se a porta ${AWS_PORT} está escutando localmente..."
lsof -i :${AWS_PORT}

# Aguardar LocalStack iniciar e exibir logs
echo "⏳ Aguardando LocalStack iniciar..."
sleep 15
kubectl logs deployment/localstack --tail=20

# Verificação: conexão via AWS CLI
echo "🔎 Testando conexão local via AWS CLI..."
if command -v aws > /dev/null; then
  aws --endpoint-url=http://localhost:${AWS_PORT} sts get-caller-identity || { echo "❌ Falha ao conectar ao LocalStack via AWS CLI."; exit 1; }
else
  echo "⚠️  AWS CLI não está instalado. Pule o teste de conexão."
fi

echo "✅ LocalStack implantado e verificado."

# Exibir informações de conexão
echo "\n🔗 Informações de conexão LocalStack:"
echo "Endpoint: http://localhost:${AWS_PORT}"
echo "Region: ${AWS_REGION}"
echo "S3 Bucket: ${AWS_S3_BUCKET}"
echo "AWS CLI: aws --endpoint-url=http://localhost:${AWS_PORT} s3 ls" 
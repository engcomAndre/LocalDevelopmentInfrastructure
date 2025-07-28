#!/bin/bash

set -e

BUCKET_NAME=files
FILES_DIR="/etc/localstack/init/files"

echo "🪣 Criando bucket: $BUCKET_NAME"

awslocal s3api create-bucket --bucket "$BUCKET_NAME" || echo "⚠️  Bucket já existe."

if [ -d "$FILES_DIR" ]; then
  for file in "$FILES_DIR"/*; do
    FILENAME=$(basename "$file")
    echo "📤 Enviando $FILENAME para s3://$BUCKET_NAME"
    awslocal s3 cp "$file" "s3://$BUCKET_NAME/$FILENAME"
  done
else
  echo "📁 Diretório de arquivos iniciais não encontrado: $FILES_DIR"
fi

echo "✅ Upload finalizado." 
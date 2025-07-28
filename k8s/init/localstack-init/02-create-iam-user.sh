#!/bin/bash

echo "=== Criando usuário IAM 'app-user' no LocalStack ==="

# Aguardar LocalStack estar pronto
echo "Aguardando LocalStack estar pronto..."
until aws --endpoint-url=http://localhost:4566 sts get-caller-identity > /dev/null 2>&1; do
    echo "LocalStack ainda não está pronto, aguardando..."
    sleep 2
done

echo "LocalStack está pronto!"

# Criar usuário IAM
aws --endpoint-url=http://localhost:4566 iam create-user --user-name app-user

# Criar política de acesso ao S3
cat > /tmp/s3-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::my-app-bucket",
                "arn:aws:s3:::my-app-bucket/*"
            ]
        }
    ]
}
EOF

# Criar política
aws --endpoint-url=http://localhost:4566 iam create-policy \
    --policy-name S3AccessPolicy \
    --policy-document file:///tmp/s3-policy.json

# Anexar política ao usuário
aws --endpoint-url=http://localhost:4566 iam attach-user-policy \
    --user-name app-user \
    --policy-arn arn:aws:iam::000000000000:policy/S3AccessPolicy

echo "=== Usuário IAM 'app-user' criado com sucesso ==="

echo "=== Listando usuários IAM criados ==="
aws --endpoint-url=http://localhost:4566 iam list-users 
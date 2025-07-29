# Kafka UI - Configuração de Acesso

## Status Atual

**A autenticação foi desabilitada** para facilitar o desenvolvimento local. O Kafka UI pode ser acessado diretamente sem necessidade de usuário e senha.

## Como Acessar

1. Execute o port-forward:
```bash
./k8s/kafka/port-forward-kafka-ui.sh
```

2. Acesse no navegador: http://localhost:8081

3. Acesso direto - sem necessidade de login

## Configuração

A autenticação está desabilitada no arquivo `kafka-ui-deployment.yaml` através da variável de ambiente:

- `AUTH_TYPE`: NONE

## Habilitando Autenticação

Para habilitar a autenticação novamente, edite o arquivo `k8s/kafka/kafka-ui-deployment.yaml` e modifique as variáveis de ambiente:

```yaml
- name: AUTH_TYPE
  value: "LOGIN_FORM"
- name: AUTH_LOGIN_FORM_USERNAME
  value: "seu_usuario"
- name: AUTH_LOGIN_FORM_PASSWORD
  value: "sua_senha"
```

Depois reaplique o deployment:
```bash
kubectl apply -f k8s/kafka/kafka-ui-deployment.yaml
``` 
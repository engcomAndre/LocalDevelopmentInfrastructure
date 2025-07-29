# 🚀 Local Development Infrastructure

Infraestrutura completa para desenvolvimento local com Kubernetes, incluindo MongoDB, LocalStack, Keycloak e SonarQube Developer Edition.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Serviços](#serviços)
- [Configuração](#configuração)
- [Uso](#uso)
- [Desenvolvimento](#desenvolvimento)
- [Troubleshooting](#troubleshooting)
- [Contribuição](#contribuição)
- [Licença](#licença)

## 🌟 Visão Geral

Este projeto fornece uma infraestrutura completa de desenvolvimento local usando Kubernetes (Minikube) com os seguintes serviços:

- **MongoDB**: Banco de dados NoSQL para aplicações
- **LocalStack**: Simulação de serviços AWS localmente
- **Keycloak**: Gerenciamento de identidade e acesso
- **SonarQube Developer**: Análise de qualidade de código
- **Kafka**: Message broker com KRaft
- **Kafka UI**: Interface web para gerenciar o Kafka

## ⚙️ Pré-requisitos

### Software Necessário

- **Docker**: Versão 20.10 ou superior
- **Minikube**: Versão 1.28 ou superior
- **kubectl**: Versão 1.28 ou superior
- **Git**: Para clonar o repositório

### Recursos do Sistema

- **RAM**: Mínimo 8GB (recomendado 16GB)
- **CPU**: Mínimo 4 cores
- **Armazenamento**: Mínimo 20GB livre

### Verificação de Pré-requisitos

```bash
# Verificar Docker
docker --version

# Verificar Minikube
minikube version

# Verificar kubectl
kubectl version --client

# Verificar Git
git --version
```

## 🛠️ Instalação

### 1. Clonar o Repositório

```bash
git clone https://github.com/engcomAndre/LocalDevelopmentInfrastructure.git
cd LocalDevelopmentInfrastructure
```

### 2. Iniciar Minikube

```bash
# Iniciar cluster Kubernetes
minikube start --memory=8192 --cpus=4 --disk-size=20g

# Verificar status
minikube status
```

### 3. Implantar Infraestrutura

```bash
# Executar script de implantação
chmod +x infra-up.sh
./infra-up.sh
```

## 🏗️ Serviços

### 📦 MongoDB

**Versão**: 6.0.25  
**Porta**: 27017  
**URL**: `mongodb://localhost:27017`

#### Configuração
- **Database**: `raffles_db`
- **Collection**: `raffles`
- **Usuário**: `application_user`
- **Senha**: `securepassword123`

#### String de Conexão
```
mongodb://application_user:securepassword123@localhost:27017/raffles_db?authSource=raffles_db
```

### ☁️ LocalStack

**Versão**: Latest  
**Porta**: 4566  
**URL**: `http://localhost:4566`

#### Serviços AWS Simulados
- **S3**: Bucket `files` criado automaticamente
- **IAM**: Usuário configurado
- **Região**: `us-east-1`

#### Configuração AWS CLI
```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
aws --endpoint-url=http://localhost:4566 s3 ls
```

### 🔐 Keycloak

**Versão**: 22.0.5  
**Porta**: 8888  
**URL**: `http://localhost:8888`

#### Configuração
- **Admin Console**: `http://localhost:8888/admin`
- **Realm**: `ms-auth-core-service-realm`
- **Client ID**: `ms-auth-core-service`
- **Client Secret**: `ms-auth-core-service-secret`

#### Credenciais Admin
- **Usuário**: `admin`
- **Senha**: `admin_password`

### 🔍 SonarQube Developer

**Versão**: 2025.3.1.109879  
**Porta**: 9000  
**URL**: `http://localhost:9000`

#### Configuração
- **Web Interface**: `http://localhost:9000`
- **Credenciais**: `admin/admin`
- **Token**: Gerado automaticamente
- **PostgreSQL**: Banco de dados dedicado

#### Recursos Alocados
- **Memória**: 2Gi-4Gi
- **CPU**: 1000m-2000m
- **Java Options**: Otimizadas para performance

### 📊 Kafka

**Versão**: 3.7.0  
**Porta**: 9092  
**URL**: `localhost:9092`

#### Configuração
- **Modo**: KRaft (sem Zookeeper)
- **Node ID**: 1
- **Process Roles**: broker,controller
- **Controller Quorum Voters**: 1@kafka:9093
- **Listeners**: PLAINTEXT:9092, CONTROLLER:9093

#### Recursos Alocados
- **Memória**: 1Gi-2Gi
- **CPU**: 500m-1000m

### 🖥️ Kafka UI

**Versão**: Latest  
**Porta**: 8080  
**URL**: `http://localhost:8080`

#### Configuração
- **Web Interface**: `http://localhost:8080`
- **Cluster Name**: local-kafka
- **Bootstrap Servers**: kafka:9092
- **Security Protocol**: PLAINTEXT

#### Recursos Alocados
- **Memória**: 256Mi-512Mi
- **CPU**: 250m-500m

## ⚙️ Configuração

### Variáveis de Ambiente

O projeto usa o arquivo `k8s/config/local.env` para configurações:

```bash
# Carregar variáveis
source k8s/config/local.env
```

### Portas Utilizadas

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| MongoDB | 27017 | Banco de dados |
| LocalStack | 4566 | Serviços AWS |
| Keycloak | 8888 | Autenticação |
| SonarQube | 9000 | Análise de código |
| Kafka | 9092 | Message broker |
| Kafka UI | 8081 | Interface web Kafka |

### Volumes Persistentes

- **MongoDB**: Dados persistentes
- **PostgreSQL**: Banco SonarQube
- **LocalStack**: Estado dos serviços AWS

## 🚀 Uso

### Scripts Disponíveis

#### `infra-up.sh` - Implantação Paralela
- **Execução em paralelo** de todos os componentes
- **Verificações de estado** automáticas
- **Logs coloridos** e informativos
- **Tratamento de erros** robusto
- **Limpeza automática** de recursos temporários

#### `infra-status.sh` - Verificação de Status
- **Verificação completa** de deployments, pods e services
- **Monitoramento de port-forwards** ativos
- **Teste de conectividade** dos serviços
- **Logs de erro** detalhados
- **Dicas de troubleshooting** automáticas

#### `port-forward-all.sh` - Gerenciamento de Port-Forwards
- **Inicialização automática** de todos os port-forwards
- **Detecção de conflitos** de porta
- **Gerenciamento de processos** (start/stop/restart)
- **Status em tempo real** dos port-forwards
- **Limpeza automática** ao interromper

### Iniciar Todos os Serviços

```bash
# Implantação em paralelo com verificações de estado
./infra-up.sh
```

### Verificar Status da Infraestrutura

```bash
# Verificação completa do status
./k8s/aux/infra-status.sh

# Verificar pods
kubectl get pods

# Verificar serviços
kubectl get services

# Verificar deployments
kubectl get deployments
```

### Gerenciar Port-Forwards

```bash
# Iniciar todos os port-forwards
./k8s/aux/port-forward-all.sh

# Verificar status dos port-forwards
./k8s/aux/port-forward-all.sh status

# Parar todos os port-forwards
./k8s/aux/port-forward-all.sh stop

# Reiniciar todos os port-forwards
./k8s/aux/port-forward-all.sh restart
```

### Acessar Serviços

```bash
# MongoDB
mongosh "mongodb://application_user:securepassword123@localhost:27017/raffles_db?authSource=raffles_db"

# LocalStack
curl http://localhost:4566/_localstack/health

# Keycloak
open http://localhost:8888/admin

# SonarQube
open http://localhost:9000

# Kafka UI
open http://localhost:8081
```

### Port Forwarding

#### Automático (Recomendado)
```bash
# Iniciar todos os port-forwards automaticamente
./k8s/aux/port-forward-all.sh
```

#### Manual
```bash
# MongoDB
kubectl port-forward svc/mongo 27017:27017 &

# LocalStack
kubectl port-forward svc/localstack 4566:4566 &

# Keycloak
kubectl port-forward svc/keycloak 8888:8080 &

# SonarQube
kubectl port-forward svc/sonarqube 9000:9000 &

# Kafka UI
kubectl port-forward svc/kafka-ui 8081:8081 &
```

## 🛠️ Desenvolvimento

### Estrutura do Projeto

```
INFRA/
├── infra-up.sh                 # Script principal de implantação (paralelo)
├── k8s/
│   ├── aux/                    # Scripts auxiliares
│   │   ├── infra-status.sh     # Script de verificação de status
│   │   └── port-forward-all.sh # Script de gerenciamento de port-forwards
│   ├── config/
│   │   ├── app-configmap.yaml  # Configurações da aplicação
│   │   ├── app-secret.yaml     # Secrets
│   │   └── local.env           # Variáveis de ambiente
│   ├── init/                   # Scripts de inicialização
│   │   ├── mongo-init/         # Configuração MongoDB
│   │   ├── localstack-init/    # Configuração LocalStack
│   │   ├── keycloak-init/      # Configuração Keycloak
│   │   ├── sonarqube-init/     # Configuração SonarQube
│   │   ├── kafka-init/         # Configuração Kafka
│   │   └── kafka-ui-init/      # Configuração Kafka UI
│   ├── mongo/                  # Kubernetes manifests MongoDB
│   ├── localstack/             # Kubernetes manifests LocalStack
│   ├── keycloak/               # Kubernetes manifests Keycloak
│   ├── sonarqube/              # Kubernetes manifests SonarQube
│   └── kafka/                  # Kubernetes manifests Kafka + Kafka UI
└── README.md                   # Este arquivo
```

### Adicionar Novo Serviço

1. Criar diretório em `k8s/[servico]/`
2. Adicionar manifests Kubernetes
3. Criar script de inicialização em `k8s/init/[servico]-init/`
4. Atualizar `infra-up.sh`

### Modificar Configurações

1. Editar arquivos em `k8s/config/`
2. Aplicar mudanças: `kubectl apply -f k8s/config/`
3. Reiniciar serviços afetados

## 🔧 Troubleshooting

### Problemas Comuns

#### Porta Já em Uso
```bash
# Verificar processos usando a porta
sudo lsof -i :9000

# Matar processo
sudo kill -9 <PID>
```

#### Pods Não Iniciam
```bash
# Verificar logs
kubectl logs <pod-name>

# Verificar eventos
kubectl describe pod <pod-name>

# Verificar recursos
kubectl top pods
```

#### SonarQube Não Inicia
```bash
# Verificar banco de dados
kubectl exec -it deployment/sonarqube-postgres -- psql -U sonar -d sonar

# Limpar banco se necessário
kubectl exec -it deployment/sonarqube-postgres -- psql -U sonar -d sonar -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
```

#### LocalStack Não Responde
```bash
# Verificar logs
kubectl logs -l app=localstack

# Reiniciar pod
kubectl delete pod -l app=localstack
```

### Logs Úteis

```bash
# Logs de todos os pods
kubectl logs -l app=sonarqube
kubectl logs -l app=mongo
kubectl logs -l app=localstack
kubectl logs -l app=keycloak

# Logs em tempo real
kubectl logs -f deployment/sonarqube
```

### Limpeza Completa

```bash
# Parar Minikube
minikube stop

# Deletar cluster
minikube delete

# Limpar Docker
docker system prune -a

# Reiniciar do zero
minikube start
./infra-up.sh
```

## 📊 Monitoramento

### Métricas do Sistema

```bash
# Status dos pods
kubectl get pods -o wide

# Uso de recursos
kubectl top pods
kubectl top nodes

# Status dos serviços
kubectl get services
```

### Health Checks

```bash
# MongoDB
curl -s http://localhost:27017

# LocalStack
curl -s http://localhost:4566/_localstack/health

# Keycloak
curl -s http://localhost:8888/health

# SonarQube
curl -s http://localhost:9000/api/system/status
```

## 🤝 Contribuição

### Como Contribuir

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

### Padrões de Commit

- `feat:` Nova funcionalidade
- `fix:` Correção de bug
- `docs:` Documentação
- `style:` Formatação
- `refactor:` Refatoração
- `test:` Testes
- `chore:` Manutenção

### Versionamento

Este projeto segue [Semantic Versioning](https://semver.org/):

- **MAJOR**: Mudanças incompatíveis
- **MINOR**: Novas funcionalidades compatíveis
- **PATCH**: Correções compatíveis

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 📞 Suporte

### Contato

- **Autor**: André Vieira
- **Email**: [seu-email@exemplo.com]
- **GitHub**: [@engcomAndre](https://github.com/engcomAndre)

### Recursos Adicionais

- [Documentação Kubernetes](https://kubernetes.io/docs/)
- [Documentação Minikube](https://minikube.sigs.k8s.io/docs/)
- [Documentação SonarQube](https://docs.sonarqube.org/)
- [Documentação Keycloak](https://www.keycloak.org/documentation)
- [Documentação LocalStack](https://docs.localstack.cloud/)

---

**⭐ Se este projeto foi útil, considere dar uma estrela no repositório!** 
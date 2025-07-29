# Kafka com KRaft

Este diretório contém as configurações para implantar o Apache Kafka usando o modo KRaft (sem Zookeeper) no Kubernetes.

## Componentes

- **Kafka**: Broker Kafka configurado com KRaft
- **Kafka UI**: Interface web para gerenciar o cluster Kafka

## Configuração KRaft

O Kafka está configurado para usar o modo KRaft, que elimina a dependência do Zookeeper:

- **Node ID**: 1
- **Process Roles**: broker,controller
- **Controller Quorum Voters**: 1@kafka:9093
- **Listeners**: 
  - PLAINTEXT:9092 (para clientes)
  - CONTROLLER:9093 (para comunicação interna)

## Arquivos

- `deployment.yaml`: Deployment do Kafka com configuração KRaft
- `service.yaml`: Service para expor o Kafka
- `configmap.yaml`: Configurações do Kafka em formato properties
- `kafka-ui-deployment.yaml`: Deployment do Kafka UI
- `kafka-ui-service.yaml`: Service do Kafka UI
- `port-forward-kafka-ui.sh`: Script para port-forward do Kafka UI
- `test-kafka.sh`: Script para testar conectividade do Kafka

## Uso

### Implantar Kafka
```bash
./k8s/init/kafka-init/kafka-infra-up.sh
```

### Implantar Kafka UI
```bash
./k8s/init/kafka-ui-init/kafka-ui-infra-up.sh
```

### Acessar Kafka UI
```bash
./port-forward-kafka-ui.sh
```

Depois acesse: http://localhost:8081

**✅ Acesso direto - sem autenticação!**

**Nota:** A autenticação foi completamente desabilitada para facilitar o desenvolvimento local.

### Testar Kafka
```bash
./test-kafka.sh
```

### Conectar ao Kafka
```bash
kubectl port-forward svc/kafka 9092:9092
```

## Configurações Importantes

- **Replication Factor**: 1 (para desenvolvimento)
- **Auto Create Topics**: Habilitado
- **Delete Topics**: Habilitado
- **Log Retention**: 168 horas (7 dias)
- **Log Segment Size**: 1GB

## Troubleshooting

### Verificar logs do Kafka
```bash
kubectl logs deployment/kafka
```

### Verificar status do pod
```bash
kubectl get pods -l app=kafka
```

### Verificar configuração KRaft
```bash
kubectl exec deployment/kafka -- kafka-metadata-shell --snapshot /tmp/kraft-combined-logs/meta.snapshot
``` 
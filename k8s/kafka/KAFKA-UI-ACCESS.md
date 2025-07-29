# Kafka UI - Acesso

## Status Atual

O Kafka UI está funcionando e acessível em **http://localhost:8081** **sem autenticação**! ✅

## Como Acessar

### 1. Port-Forward
```bash
kubectl port-forward svc/kafka-ui 8081:8081
```

### 2. Acesse no Navegador
http://localhost:8081

### 3. Acesso Direto
**Sem necessidade de usuário e senha!** 🎉

O Kafka UI está configurado para acesso direto sem autenticação.

## Configuração Atual

O deployment está configurado com:
```yaml
- name: AUTH_TYPE
  value: "DISABLED"
- name: MANAGEMENT_SECURITY_ENABLED
  value: "false"
```

Essas configurações desabilitam completamente a autenticação do Kafka UI.

## Troubleshooting

### Se não conseguir acessar:
1. Verifique se o port-forward está ativo:
   ```bash
   ss -tlnp | grep 8081
   ```

2. Verifique se o pod está rodando:
   ```bash
   kubectl get pods -l app=kafka-ui
   ```

3. Verifique os logs:
   ```bash
   kubectl logs deployment/kafka-ui --tail=20
   ```

### Para recriar o port-forward:
```bash
kubectl port-forward svc/kafka-ui 8081:8081 &
```

## Nota Importante

O Kafka UI está funcionando corretamente e conectado ao cluster Kafka. A autenticação foi completamente desabilitada para facilitar o desenvolvimento local. 
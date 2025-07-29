#!/bin/bash

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para executar um script de infraestrutura
run_infra_script() {
    local script_path=$1
    local component_name=$2
    
    log "🚀 Iniciando $component_name..."
    if [ -f "$script_path" ]; then
        if bash "$script_path"; then
            success "$component_name implantado com sucesso!"
        else
            error "$component_name falhou!"
            return 1
        fi
    else
        error "Script não encontrado: $script_path"
        return 1
    fi
}

# Função para verificar se um deployment está pronto
check_deployment() {
    local deployment_name=$1
    local timeout=${2:-120}
    local interval=${3:-10}
    
    log "Verificando deployment: $deployment_name"
    
    for ((i=0; i<timeout; i+=interval)); do
        if kubectl get deployment "$deployment_name" >/dev/null 2>&1; then
            if kubectl wait --for=condition=available --timeout=10s deployment/"$deployment_name" >/dev/null 2>&1; then
                success "Deployment $deployment_name está pronto!"
                return 0
            fi
        fi
        log "Aguardando deployment $deployment_name... ($((timeout-i))s restantes)"
        sleep $interval
    done
    
    error "Timeout aguardando deployment $deployment_name"
    return 1
}

# Função para verificar se um pod está rodando
check_pod() {
    local pod_label=$1
    local timeout=${2:-120}
    local interval=${3:-10}
    
    log "Verificando pod com label: $pod_label"
    
    for ((i=0; i<timeout; i+=interval)); do
        if kubectl get pods -l "$pod_label" --no-headers | grep -q "Running"; then
            success "Pod com label $pod_label está rodando!"
            return 0
        fi
        log "Aguardando pod com label $pod_label... ($((timeout-i))s restantes)"
        sleep $interval
    done
    
    error "Timeout aguardando pod com label $pod_label"
    return 1
}

# Função para verificar o estado final de todos os componentes
check_final_status() {
    log "🔍 Verificando estado final dos componentes..."
    
    local all_healthy=true
    
    # Verificar deployments
    local deployments=("mongo" "localstack" "keycloak" "sonarqube" "kafka" "kafka-ui")
    for deployment in "${deployments[@]}"; do
        if check_deployment "$deployment" 60 5; then
            success "Deployment $deployment: OK"
        else
            error "Deployment $deployment: FALHOU"
            all_healthy=false
        fi
    done
    
    # Verificar pods
    local pod_labels=("app=mongo" "app=localstack" "app=keycloak" "app=sonarqube" "app=kafka" "app=kafka-ui")
    for label in "${pod_labels[@]}"; do
        if check_pod "$label" 60 5; then
            success "Pod com label $label: OK"
        else
            error "Pod com label $label: FALHOU"
            all_healthy=false
        fi
    done
    
    if [ "$all_healthy" = true ]; then
        success "🎉 Todos os componentes estão saudáveis!"
        return 0
    else
        error "❌ Alguns componentes falharam."
        return 1
    fi
}

# Função para mostrar informações de acesso
show_access_info() {
    log "📋 Informações de acesso:"
    echo ""
    echo "🌐 Serviços disponíveis:"
    echo "  • Kafka UI: http://localhost:8081 (sem autenticação)"
    echo "  • Keycloak: http://localhost:8888/admin"
    echo "  • SonarQube: http://localhost:9000"
    echo "  • LocalStack: http://localhost:4566"
    echo ""
    echo "🔧 Scripts auxiliares:"
    echo "  • Verificar status: ./k8s/aux/infra-status.sh"
    echo "  • Gerenciar port-forwards: ./k8s/aux/port-forward-all.sh"
    echo ""
    echo "🔧 Para fazer port-forward manualmente:"
    echo "  • kubectl port-forward svc/kafka-ui 8081:8081"
    echo "  • kubectl port-forward svc/keycloak 8888:8080"
    echo "  • kubectl port-forward svc/sonarqube 9000:9000"
    echo "  • kubectl port-forward svc/localstack 4566:4566"
    echo "  • kubectl port-forward svc/mongo 27017:27017"
    echo "  • kubectl port-forward svc/kafka 9092:9092"
    echo ""
}

# Função principal
main() {
    log "🚀 Iniciando implantação da infraestrutura sequencialmente..."
    
    # Executar todos os scripts sequencialmente
    run_infra_script "./k8s/init/mongo-init/mongo-infra-up.sh" "MongoDB"
    run_infra_script "./k8s/init/localstack-init/localstack-infra-up.sh" "LocalStack"
    run_infra_script "./k8s/init/keycloak-init/keycloak-infra-up.sh" "Keycloak"
    run_infra_script "./k8s/init/sonarqube-init/sonarqube-infra-up.sh" "SonarQube"
    run_infra_script "./k8s/init/kafka-init/kafka-infra-up.sh" "Kafka"
    run_infra_script "./k8s/init/kafka-ui-init/kafka-ui-infra-up.sh" "Kafka-UI"
    
    # Aguardar um pouco para que tudo estabilize
    log "⏳ Aguardando estabilização dos componentes..."
    sleep 30
    
    # Verificar estado final
    if check_final_status; then
        success "🎉 Infraestrutura implantada com sucesso!"
        show_access_info
    else
        error "❌ Falha na implantação da infraestrutura"
        exit 1
    fi
}

# Executar função principal
main "$@" 
#!/bin/bash

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

# Função para verificar status de deployments
check_deployments() {
    log "📦 Verificando Deployments..."
    echo ""
    
    local deployments=("mongo" "localstack" "keycloak" "sonarqube" "kafka" "kafka-ui")
    local all_ready=true
    
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment "$deployment" >/dev/null 2>&1; then
            local ready=$(kubectl get deployment "$deployment" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
            local desired=$(kubectl get deployment "$deployment" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
            
            if [ "$ready" = "$desired" ] && [ "$ready" != "0" ]; then
                success "  $deployment: $ready/$desired ready"
            else
                error "  $deployment: $ready/$desired ready"
                all_ready=false
            fi
        else
            error "  $deployment: não encontrado"
            all_ready=false
        fi
    done
    
    echo ""
    return $([ "$all_ready" = true ] && echo 0 || echo 1)
}

# Função para verificar status de pods
check_pods() {
    log "🔍 Verificando Pods..."
    echo ""
    
    local pod_labels=("app=mongo" "app=localstack" "app=keycloak" "app=sonarqube" "app=kafka" "app=kafka-ui")
    local all_running=true
    
    for label in "${pod_labels[@]}"; do
        local running=$(kubectl get pods -l "$label" --no-headers 2>/dev/null | grep -c "Running" || echo "0")
        local total=$(kubectl get pods -l "$label" --no-headers 2>/dev/null | wc -l || echo "0")
        
        if [ "$running" = "$total" ] && [ "$running" != "0" ]; then
            success "  $label: $running/$total running"
        else
            error "  $label: $running/$total running"
            all_running=false
        fi
    done
    
    echo ""
    return $([ "$all_running" = true ] && echo 0 || echo 1)
}

# Função para verificar status de services
check_services() {
    log "🌐 Verificando Services..."
    echo ""
    
    local services=("mongo" "localstack" "keycloak" "sonarqube" "kafka" "kafka-ui")
    local all_available=true
    
    for service in "${services[@]}"; do
        if kubectl get service "$service" >/dev/null 2>&1; then
            local cluster_ip=$(kubectl get service "$service" -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
            if [ -n "$cluster_ip" ] && [ "$cluster_ip" != "None" ]; then
                success "  $service: $cluster_ip"
            else
                error "  $service: sem ClusterIP"
                all_available=false
            fi
        else
            error "  $service: não encontrado"
            all_available=false
        fi
    done
    
    echo ""
    return $([ "$all_available" = true ] && echo 0 || echo 1)
}

# Função para verificar port-forwards ativos
check_port_forwards() {
    log "🔌 Verificando Port-Forwards..."
    echo ""
    
    local ports=("8081" "8888" "9000" "4566" "27017" "9092")
    local port_names=("Kafka UI" "Keycloak" "SonarQube" "LocalStack" "MongoDB" "Kafka")
    local all_active=true
    
    for i in "${!ports[@]}"; do
        local port=${ports[$i]}
        local name=${port_names[$i]}
        
        if ss -tlnp | grep -q ":$port "; then
            success "  $name ($port): ativo"
        else
            warning "  $name ($port): inativo"
            all_active=false
        fi
    done
    
    echo ""
    return $([ "$all_active" = true ] && echo 0 || echo 1)
}

# Função para verificar conectividade dos serviços
check_connectivity() {
    log "🌍 Verificando Conectividade..."
    echo ""
    
    local endpoints=(
        "http://localhost:8081"
        "http://localhost:8888"
        "http://localhost:9000"
        "http://localhost:4566"
    )
    local names=("Kafka UI" "Keycloak" "SonarQube" "LocalStack")
    local all_accessible=true
    
    for i in "${!endpoints[@]}"; do
        local endpoint=${endpoints[$i]}
        local name=${names[$i]}
        
        if curl -s -o /dev/null -w "%{http_code}" "$endpoint" | grep -q "200\|302\|401"; then
            success "  $name: acessível"
        else
            error "  $name: não acessível"
            all_accessible=false
        fi
    done
    
    echo ""
    return $([ "$all_accessible" = true ] && echo 0 || echo 1)
}

# Função para mostrar logs de erro
show_error_logs() {
    log "📋 Logs de erro recentes..."
    echo ""
    
    local deployments=("mongo" "localstack" "keycloak" "sonarqube" "kafka" "kafka-ui")
    
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment "$deployment" >/dev/null 2>&1; then
            local pod=$(kubectl get pods -l "app=$deployment" --no-headers | head -1 | awk '{print $1}')
            if [ -n "$pod" ]; then
                local status=$(kubectl get pod "$pod" -o jsonpath='{.status.phase}' 2>/dev/null)
                if [ "$status" != "Running" ]; then
                    warning "Pod $pod ($deployment) - Status: $status"
                    kubectl logs "$pod" --tail=3 2>/dev/null | sed 's/^/    /'
                    echo ""
                fi
            fi
        fi
    done
}

# Função para mostrar informações de acesso
show_access_info() {
    log "📋 Informações de Acesso:"
    echo ""
    echo "🌐 Serviços disponíveis:"
    echo "  • Kafka UI: http://localhost:8081 (sem autenticação)"
    echo "  • Keycloak: http://localhost:8888/admin"
    echo "  • SonarQube: http://localhost:9000"
    echo "  • LocalStack: http://localhost:4566"
    echo ""
    echo "🔧 Comandos úteis:"
    echo "  • kubectl get pods"
    echo "  • kubectl get services"
    echo "  • kubectl get deployments"
    echo "  • kubectl logs deployment/<nome>"
    echo ""
}

# Função principal
main() {
    echo "🔍 Verificando status da infraestrutura..."
    echo "=========================================="
    echo ""
    
    local overall_status=0
    
    # Verificar deployments
    if check_deployments; then
        success "Deployments: OK"
    else
        error "Deployments: PROBLEMAS DETECTADOS"
        overall_status=1
    fi
    
    # Verificar pods
    if check_pods; then
        success "Pods: OK"
    else
        error "Pods: PROBLEMAS DETECTADOS"
        overall_status=1
    fi
    
    # Verificar services
    if check_services; then
        success "Services: OK"
    else
        error "Services: PROBLEMAS DETECTADOS"
        overall_status=1
    fi
    
    # Verificar port-forwards
    if check_port_forwards; then
        success "Port-Forwards: OK"
    else
        warning "Port-Forwards: ALGUNS INATIVOS"
    fi
    
    # Verificar conectividade
    if check_connectivity; then
        success "Conectividade: OK"
    else
        error "Conectividade: PROBLEMAS DETECTADOS"
        overall_status=1
    fi
    
    echo "=========================================="
    
    if [ $overall_status -eq 0 ]; then
        success "🎉 Infraestrutura está saudável!"
        show_access_info
    else
        error "❌ Problemas detectados na infraestrutura"
        show_error_logs
        echo ""
        warning "💡 Dicas para resolver problemas:"
        echo "  • Execute: kubectl get pods"
        echo "  • Verifique logs: kubectl logs <pod-name>"
        echo "  • Reinicie deployments: kubectl rollout restart deployment/<name>"
        echo "  • Faça port-forward: kubectl port-forward svc/<service> <port>:<port>"
    fi
    
    exit $overall_status
}

# Executar função principal
main "$@" 
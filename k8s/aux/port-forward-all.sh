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

# Função para verificar se uma porta está em uso
check_port() {
    local port=$1
    if ss -tlnp | grep -q ":$port "; then
        return 0
    else
        return 1
    fi
}

# Função para matar processos usando uma porta
kill_port() {
    local port=$1
    local pids=$(ss -tlnp | grep ":$port " | awk '{print $7}' | sed 's/.*pid=\([0-9]*\).*/\1/' | sort -u)
    
    if [ -n "$pids" ]; then
        log "Matando processos usando porta $port: $pids"
        echo "$pids" | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

# Função para fazer port-forward
start_port_forward() {
    local service=$1
    local local_port=$2
    local target_port=${3:-$local_port}
    
    if check_port "$local_port"; then
        warning "Porta $local_port já está em uso. Matando processo..."
        kill_port "$local_port"
    fi
    
    log "Iniciando port-forward para $service na porta $local_port..."
    kubectl port-forward "svc/$service" "$local_port:$target_port" > "/tmp/port-forward-$service.log" 2>&1 &
    local pid=$!
    echo $pid > "/tmp/port-forward-$service.pid"
    
    # Aguardar um pouco para verificar se iniciou
    sleep 3
    if check_port "$local_port"; then
        success "Port-forward para $service iniciado (PID: $pid)"
        return 0
    else
        error "Falha ao iniciar port-forward para $service"
        return 1
    fi
}

# Função para parar todos os port-forwards
stop_all_port_forwards() {
    log "Parando todos os port-forwards..."
    
    local services=("kafka-ui" "keycloak" "sonarqube" "localstack" "mongo" "kafka")
    
    for service in "${services[@]}"; do
        if [ -f "/tmp/port-forward-$service.pid" ]; then
            local pid=$(cat "/tmp/port-forward-$service.pid")
            if kill -0 "$pid" 2>/dev/null; then
                log "Parando port-forward $service (PID: $pid)"
                kill "$pid" 2>/dev/null || true
            fi
        fi
    done
    
    # Limpar arquivos PID
    rm -f /tmp/port-forward-*.pid
    success "Todos os port-forwards parados"
}

# Função para mostrar status dos port-forwards
show_status() {
    log "Status dos Port-Forwards:"
    echo ""
    
    local services=(
        "kafka-ui:8081:Kafka UI"
        "keycloak:8888:8080:Keycloak"
        "sonarqube:9000:SonarQube"
        "localstack:4566:LocalStack"
        "mongo:27017:MongoDB"
        "kafka:9092:Kafka"
    )
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r service local_port target_port name <<< "$service_info"
        
        if [ -z "$target_port" ]; then
            target_port=$local_port
        fi
        
        if check_port "$local_port"; then
            success "  $name: $local_port -> $target_port (ativo)"
        else
            warning "  $name: $local_port -> $target_port (inativo)"
        fi
    done
    
    echo ""
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
    echo "🔧 Para parar todos os port-forwards:"
echo "  • ./k8s/aux/port-forward-all.sh stop"
    echo ""
}

# Função principal
main() {
    local action=${1:-start}
    
    case $action in
        start)
            log "🚀 Iniciando port-forwards para todos os serviços..."
            echo ""
            
            # Criar diretório temporário se não existir
            mkdir -p /tmp
            
            # Iniciar port-forwards
            start_port_forward "kafka-ui" "8081"
            start_port_forward "keycloak" "8888" "8080"
            start_port_forward "sonarqube" "9000"
            start_port_forward "localstack" "4566"
            start_port_forward "mongo" "27017"
            start_port_forward "kafka" "9092"
            
            echo ""
            success "🎉 Todos os port-forwards iniciados!"
            show_status
            show_access_info
            
            log "💡 Para parar todos os port-forwards, execute: ./k8s/aux/port-forward-all.sh stop"
            ;;
            
        stop)
            stop_all_port_forwards
            ;;
            
        status)
            show_status
            show_access_info
            ;;
            
        restart)
            log "🔄 Reiniciando port-forwards..."
            stop_all_port_forwards
            sleep 2
            main start
            ;;
            
        *)
            echo "Uso: $0 [start|stop|status|restart]"
            echo ""
            echo "Comandos:"
            echo "  start   - Iniciar todos os port-forwards (padrão)"
            echo "  stop    - Parar todos os port-forwards"
            echo "  status  - Mostrar status dos port-forwards"
            echo "  restart - Reiniciar todos os port-forwards"
            echo ""
            exit 1
            ;;
    esac
}

# Capturar Ctrl+C para limpeza
cleanup() {
    log "Interrompendo port-forwards..."
    stop_all_port_forwards
    exit 0
}

trap cleanup SIGINT

# Executar função principal
main "$@" 
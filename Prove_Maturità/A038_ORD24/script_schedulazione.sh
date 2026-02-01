#!/bin/bash
################################################################################
# Script di Schedulazione Trasferimenti Dati FSE
# Strutture Sanitarie Private → Data-Center Regionale
#
# Questo script gestisce la schedulazione dei trasferimenti dati
# secondo le specifiche della prova d'esame (Punto 4)
#
# Autore: Regione IT Services
# Data: 2024-01-30
# Versione: 1.0
################################################################################

# ==============================================================================
# CONFIGURAZIONE
# ==============================================================================

# Endpoint FSE
FSE_API_ENDPOINT="https://fse.regione.it/api/v1"
FSE_SFTP_SERVER="sftp.fse.regione.it"
FSE_SFTP_PORT="22"

# Credenziali (da environment o file sicuro)
API_CLIENT_ID="${FSE_CLIENT_ID:-}"
API_CLIENT_SECRET="${FSE_CLIENT_SECRET:-}"
SFTP_USERNAME="${FSE_SFTP_USER:-}"
SFTP_KEY_PATH="${HOME}/.ssh/fse_rsa"

# Directory locali
LOCAL_DATA_DIR="/opt/fse/data"
LOCAL_QUEUE_DIR="/opt/fse/queue"
LOCAL_ARCHIVE_DIR="/opt/fse/archive"
LOCAL_LOG_DIR="/var/log/fse"
LOCAL_TEMP_DIR="/tmp/fse"

# File di stato
LOCK_FILE="/var/run/fse_sync.lock"
STATE_FILE="${LOCAL_DATA_DIR}/.sync_state"
ERROR_LOG="${LOCAL_LOG_DIR}/errors.log"
SUCCESS_LOG="${LOCAL_LOG_DIR}/success.log"

# Limiti
MAX_RETRY=3
RETRY_DELAY=300  # 5 minuti
MAX_FILE_SIZE_MB=100
BATCH_SIZE=50

# ==============================================================================
# FUNZIONI UTILITY
# ==============================================================================

# Logging
log() {
    local level=$1
    shift
    local message="$@"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "${LOCAL_LOG_DIR}/main.log"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }

# Verifica lock (evita esecuzioni parallele)
acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_warn "Processo già in esecuzione (PID: $pid)"
            return 1
        else
            log_info "Rimuovo lock file obsoleto"
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
    return 0
}

release_lock() {
    rm -f "$LOCK_FILE"
}

# Cleanup su exit
cleanup() {
    release_lock
    rm -rf "$LOCAL_TEMP_DIR"/*
}
trap cleanup EXIT INT TERM

# ==============================================================================
# FUNZIONI AUTENTICAZIONE
# ==============================================================================

# Ottieni token OAuth 2.0
get_access_token() {
    log_info "Richiesta access token OAuth2..."
    
    local response=$(curl -s -X POST \
        "${FSE_API_ENDPOINT}/auth/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=client_credentials" \
        -d "client_id=${API_CLIENT_ID}" \
        -d "client_secret=${API_CLIENT_SECRET}")
    
    local token=$(echo "$response" | jq -r '.access_token')
    
    if [ "$token" != "null" ] && [ -n "$token" ]; then
        log_info "Access token ottenuto con successo"
        echo "$token"
        return 0
    else
        log_error "Errore ottenimento token: $response"
        return 1
    fi
}

# ==============================================================================
# FUNZIONI TRASFERIMENTO DATI
# ==============================================================================

# Invia prestazione sanitaria via API REST
send_prestazione_api() {
    local file=$1
    local token=$2
    local attempt=${3:-1}
    
    log_info "Invio prestazione: $(basename $file) (tentativo $attempt/$MAX_RETRY)"
    
    # Calcola checksum per integrità
    local checksum=$(sha256sum "$file" | awk '{print $1}')
    
    # Invia richiesta
    local response=$(curl -s -w "\n%{http_code}" -X POST \
        "${FSE_API_ENDPOINT}/prestazioni" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "X-Checksum: $checksum" \
        -d @"$file")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        log_info "Prestazione inviata con successo: $(echo $body | jq -r '.transaction_id')"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$(basename $file),$checksum,SUCCESS,$http_code" >> "$SUCCESS_LOG"
        
        # Archivia file
        mv "$file" "${LOCAL_ARCHIVE_DIR}/$(basename $file).$(date +%Y%m%d-%H%M%S)"
        return 0
    else
        log_error "Errore invio prestazione: HTTP $http_code - $body"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$(basename $file),$checksum,ERROR,$http_code,$body" >> "$ERROR_LOG"
        
        # Retry se non è l'ultimo tentativo
        if [ $attempt -lt $MAX_RETRY ]; then
            log_info "Nuovo tentativo tra $RETRY_DELAY secondi..."
            sleep $RETRY_DELAY
            send_prestazione_api "$file" "$token" $((attempt + 1))
            return $?
        else
            # Sposta in coda per retry successivo
            mv "$file" "${LOCAL_QUEUE_DIR}/failed_$(date +%Y%m%d-%H%M%S)_$(basename $file)"
            return 1
        fi
    fi
}

# Trasferimento file grandi via SFTP
send_large_file_sftp() {
    local file=$1
    local remote_path=$2
    
    log_info "Trasferimento file grande via SFTP: $(basename $file)"
    
    # Verifica dimensione file
    local file_size_mb=$(du -m "$file" | cut -f1)
    log_info "Dimensione file: ${file_size_mb}MB"
    
    # Comprimi file se >50MB
    local transfer_file="$file"
    if [ $file_size_mb -gt 50 ]; then
        log_info "Compressione file..."
        transfer_file="${LOCAL_TEMP_DIR}/$(basename $file).gz"
        gzip -c "$file" > "$transfer_file"
        remote_path="${remote_path}.gz"
    fi
    
    # Calcola checksum
    local checksum=$(sha256sum "$transfer_file" | awk '{print $1}')
    
    # Trasferisci via SFTP
    sftp -i "$SFTP_KEY_PATH" \
         -P "$FSE_SFTP_PORT" \
         -o StrictHostKeyChecking=no \
         "${SFTP_USERNAME}@${FSE_SFTP_SERVER}" << SFTP_COMMANDS
put $transfer_file $remote_path
bye
SFTP_COMMANDS
    
    if [ $? -eq 0 ]; then
        log_info "File trasferito con successo"
        
        # Invia checksum per verifica
        curl -s -X POST \
            "${FSE_API_ENDPOINT}/files/verify" \
            -H "Authorization: Bearer $(get_access_token)" \
            -H "Content-Type: application/json" \
            -d "{\"path\": \"$remote_path\", \"checksum\": \"$checksum\"}"
        
        # Archivia file
        mv "$file" "${LOCAL_ARCHIVE_DIR}/$(basename $file).$(date +%Y%m%d-%H%M%S)"
        
        # Cleanup temporanei
        [ -f "$transfer_file" ] && rm -f "$transfer_file"
        
        return 0
    else
        log_error "Errore trasferimento SFTP"
        return 1
    fi
}

# ==============================================================================
# TASK SCHEDULATI
# ==============================================================================

# Task 1: Trasferimenti Real-Time (prestazioni urgenti)
# Eseguito ogni minuto da cron: * * * * *
task_realtime_urgent() {
    log_info "=== Task Real-Time: Prestazioni Urgenti ==="
    
    acquire_lock || return 1
    
    # Ottieni token
    local token=$(get_access_token)
    [ -z "$token" ] && { log_error "Impossibile ottenere token"; return 1; }
    
    # Cerca file urgenti
    local urgent_files=$(find "${LOCAL_QUEUE_DIR}/urgent" -type f -name "*.json" 2>/dev/null)
    
    if [ -z "$urgent_files" ]; then
        log_info "Nessuna prestazione urgente da inviare"
        return 0
    fi
    
    local count=0
    local success=0
    local failed=0
    
    for file in $urgent_files; do
        ((count++))
        if send_prestazione_api "$file" "$token"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    log_info "Completato: $success successi, $failed errori su $count totali"
}

# Task 2: Trasferimenti Near Real-Time (prestazioni ordinarie)
# Eseguito ogni 15 minuti da cron: */15 * * * *
task_neartime_ordinary() {
    log_info "=== Task Near Real-Time: Prestazioni Ordinarie ==="
    
    acquire_lock || return 1
    
    # Ottieni token
    local token=$(get_access_token)
    [ -z "$token" ] && { log_error "Impossibile ottenere token"; return 1; }
    
    # Cerca file ordinari
    local ordinary_files=$(find "${LOCAL_QUEUE_DIR}/ordinary" -type f -name "*.json" | head -n $BATCH_SIZE)
    
    if [ -z "$ordinary_files" ]; then
        log_info "Nessuna prestazione ordinaria da inviare"
        return 0
    fi
    
    local count=0
    local success=0
    local failed=0
    
    for file in $ordinary_files; do
        ((count++))
        if send_prestazione_api "$file" "$token"; then
            ((success++))
        else
            ((failed++))
        fi
        
        # Rate limiting (max 10 req/sec)
        sleep 0.1
    done
    
    log_info "Completato: $success successi, $failed errori su $count totali"
}

# Task 3: Trasferimenti Batch Notturni (file grandi)
# Eseguito ogni notte da cron: 0 1 * * *
task_batch_large_files() {
    log_info "=== Task Batch Notturno: File Grandi ==="
    
    acquire_lock || return 1
    
    # Cerca file grandi (immagini, video)
    local large_files=$(find "${LOCAL_QUEUE_DIR}/large" -type f \( -name "*.dcm" -o -name "*.mp4" -o -name "*.avi" \) 2>/dev/null)
    
    if [ -z "$large_files" ]; then
        log_info "Nessun file grande da trasferire"
        return 0
    fi
    
    local count=0
    local success=0
    local failed=0
    
    for file in $large_files; do
        ((count++))
        local remote_path="/upload/large/$(basename $file)"
        
        if send_large_file_sftp "$file" "$remote_path"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    log_info "Completato: $success successi, $failed errori su $count totali"
}

# Task 4: Backup Database Locale
# Eseguito ogni notte da cron: 0 0 * * *
task_backup_local() {
    log_info "=== Task Backup: Database Locale ==="
    
    acquire_lock || return 1
    
    local backup_file="${LOCAL_TEMP_DIR}/backup_$(date +%Y%m%d-%H%M%S).sql.gz"
    local remote_path="/backups/struttura_${STRUTTURA_ID}/$(basename $backup_file)"
    
    # Esegui backup database (esempio PostgreSQL)
    log_info "Creazione backup database..."
    pg_dump -U fse_user fse_db | gzip > "$backup_file"
    
    if [ $? -eq 0 ]; then
        log_info "Backup creato: $(du -h $backup_file | cut -f1)"
        
        # Trasferisci backup
        if send_large_file_sftp "$backup_file" "$remote_path"; then
            log_info "Backup trasferito con successo"
            rm -f "$backup_file"
        else
            log_error "Errore trasferimento backup"
        fi
    else
        log_error "Errore creazione backup"
    fi
}

# Task 5: Retry Failed Transfers
# Eseguito ogni ora da cron: 0 * * * *
task_retry_failed() {
    log_info "=== Task Retry: Trasferimenti Falliti ==="
    
    acquire_lock || return 1
    
    # Ottieni token
    local token=$(get_access_token)
    [ -z "$token" ] && { log_error "Impossibile ottenere token"; return 1; }
    
    # Cerca file falliti non troppo vecchi (max 24 ore)
    local failed_files=$(find "${LOCAL_QUEUE_DIR}" -name "failed_*" -type f -mmin -1440 2>/dev/null)
    
    if [ -z "$failed_files" ]; then
        log_info "Nessun file fallito da re-inviare"
        return 0
    fi
    
    local count=0
    local success=0
    local failed=0
    
    for file in $failed_files; do
        ((count++))
        
        # Ripristina nome originale
        local original_name=$(basename "$file" | sed 's/^failed_[0-9]\{8\}-[0-9]\{6\}_//')
        local temp_file="${LOCAL_TEMP_DIR}/${original_name}"
        cp "$file" "$temp_file"
        
        if send_prestazione_api "$temp_file" "$token"; then
            ((success++))
            rm -f "$file"  # Rimuovi da failed
        else
            ((failed++))
        fi
        
        rm -f "$temp_file"
    done
    
    log_info "Completato: $success successi, $failed errori su $count totali"
}

# Task 6: Cleanup Archivi Vecchi
# Eseguito settimanalmente da cron: 0 2 * * 0
task_cleanup_archives() {
    log_info "=== Task Cleanup: Archivi Vecchi ==="
    
    acquire_lock || return 1
    
    # Rimuovi archivi più vecchi di 90 giorni
    log_info "Rimozione archivi > 90 giorni..."
    find "${LOCAL_ARCHIVE_DIR}" -type f -mtime +90 -delete
    
    # Rimuovi log più vecchi di 30 giorni
    log_info "Rimozione log > 30 giorni..."
    find "${LOCAL_LOG_DIR}" -type f -name "*.log" -mtime +30 -delete
    
    # Rimuovi file falliti più vecchi di 7 giorni
    log_info "Rimozione failed > 7 giorni..."
    find "${LOCAL_QUEUE_DIR}" -name "failed_*" -mtime +7 -delete
    
    log_info "Cleanup completato"
}

# Task 7: Health Check e Monitoring
# Eseguito ogni 5 minuti da cron: */5 * * * *
task_health_check() {
    log_info "=== Health Check ==="
    
    # Verifica connettività data-center
    if ! ping -c 2 -W 2 10.1.0.1 > /dev/null 2>&1; then
        log_error "ALERT: Data-center non raggiungibile!"
        # Invia alert (email, SMS, etc.)
        echo "Data-center non raggiungibile" | mail -s "ALERT FSE" support@regione.it
    fi
    
    # Verifica spazio disco
    local disk_usage=$(df "${LOCAL_DATA_DIR}" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $disk_usage -gt 90 ]; then
        log_error "ALERT: Spazio disco quasi esaurito: ${disk_usage}%"
        echo "Spazio disco: ${disk_usage}%" | mail -s "ALERT Spazio Disco FSE" support@regione.it
    fi
    
    # Verifica dimensione coda
    local queue_size=$(find "${LOCAL_QUEUE_DIR}" -type f | wc -l)
    if [ $queue_size -gt 1000 ]; then
        log_warn "WARN: Coda grande: $queue_size file in attesa"
    fi
    
    # Verifica VPN IPsec
    if ! ip xfrm state | grep -q "proto esp"; then
        log_error "ALERT: VPN IPsec non attiva!"
        echo "VPN IPsec down" | mail -s "ALERT VPN FSE" support@regione.it
    fi
    
    log_info "Health check completato"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    # Crea directory se non esistono
    mkdir -p "$LOCAL_DATA_DIR" "$LOCAL_QUEUE_DIR" "$LOCAL_ARCHIVE_DIR" \
             "$LOCAL_LOG_DIR" "$LOCAL_TEMP_DIR" \
             "${LOCAL_QUEUE_DIR}/urgent" \
             "${LOCAL_QUEUE_DIR}/ordinary" \
             "${LOCAL_QUEUE_DIR}/large"
    
    # Determina quale task eseguire in base al parametro
    case "${1:-}" in
        "realtime")
            task_realtime_urgent
            ;;
        "neartime")
            task_neartime_ordinary
            ;;
        "batch")
            task_batch_large_files
            ;;
        "backup")
            task_backup_local
            ;;
        "retry")
            task_retry_failed
            ;;
        "cleanup")
            task_cleanup_archives
            ;;
        "health")
            task_health_check
            ;;
        *)
            echo "Utilizzo: $0 {realtime|neartime|batch|backup|retry|cleanup|health}"
            echo ""
            echo "Task disponibili:"
            echo "  realtime  - Trasferimenti real-time prestazioni urgenti"
            echo "  neartime  - Trasferimenti near-realtime prestazioni ordinarie"
            echo "  batch     - Trasferimenti batch notturni file grandi"
            echo "  backup    - Backup database locale"
            echo "  retry     - Retry trasferimenti falliti"
            echo "  cleanup   - Cleanup archivi vecchi"
            echo "  health    - Health check sistema"
            exit 1
            ;;
    esac
}

# Esegui main
main "$@"

exit 0

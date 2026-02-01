#!/bin/bash
################################################################################
# Script di Configurazione Automatica CPE Router
# Strutture Sanitarie Private - Rete Regionale FSE
#
# Utilizzo: ./script_configurazione_cpe.sh <struttura_id> <nome_struttura>
# Esempio: ./script_configurazione_cpe.sh 1 "Clinica San Marco"
#
# Autore: Regione IT Services
# Data: 2024-01-30
# Versione: 1.0
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# ==============================================================================
# CONFIGURAZIONE
# ==============================================================================

# Parametri da linea di comando
STRUTTURA_ID="${1:-}"
NOME_STRUTTURA="${2:-}"

# Validazione parametri
if [ -z "$STRUTTURA_ID" ] || [ -z "$NOME_STRUTTURA" ]; then
    echo "Errore: Parametri mancanti"
    echo "Utilizzo: $0 <struttura_id> <nome_struttura>"
    echo "Esempio: $0 1 'Clinica San Marco'"
    exit 1
fi

# Costanti rete regionale
BASE_NETWORK="10.100.0.0"
SUBNET_SIZE=32  # /27 = 32 indirizzi
NETMASK="255.255.255.224"
NETMASK_BITS=27
DATA_CENTER="10.1.0.0/24"
CORE_ROUTER="10.1.0.1"
DNS_PRIMARY="10.1.0.10"
DNS_SECONDARY="10.1.0.11"
SYSLOG_SERVER="10.1.0.201"
SNMP_SERVER="10.1.0.202"
BACKUP_SERVER="10.1.0.203"

# Parametri LAN interna
LAN_NETWORK="192.168.1.0/24"
LAN_IP="192.168.1.1"
LAN_NETMASK="255.255.255.0"
DHCP_START="192.168.1.10"
DHCP_END="192.168.1.250"

# File di output
OUTPUT_DIR="./config_generated"
CONFIG_FILE="${OUTPUT_DIR}/CPE-${STRUTTURA_ID}-config.txt"
BACKUP_FILE="${OUTPUT_DIR}/CPE-${STRUTTURA_ID}-backup-$(date +%Y%m%d-%H%M%S).txt"

# ==============================================================================
# FUNZIONI UTILITY
# ==============================================================================

# Funzione per logging
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Funzione per calcolare subnet
calculate_subnet() {
    local id=$1
    local offset=$((id * SUBNET_SIZE))
    
    # Calcola network address
    local network_int=$(($(echo $BASE_NETWORK | awk -F. '{print $1*256*256*256 + $2*256*256 + $3*256 + $4}') + offset))
    
    local octet1=$((network_int / 256 / 256 / 256 % 256))
    local octet2=$((network_int / 256 / 256 % 256))
    local octet3=$((network_int / 256 % 256))
    local octet4=$((network_int % 256))
    
    NETWORK_ADDRESS="${octet1}.${octet2}.${octet3}.${octet4}"
    GATEWAY="${octet1}.${octet2}.${octet3}.$((octet4 + 1))"
    FIRST_USABLE="${octet1}.${octet2}.${octet3}.$((octet4 + 2))"
    LAST_USABLE="${octet1}.${octet2}.${octet3}.$((octet4 + 30))"
    BROADCAST="${octet1}.${octet2}.${octet3}.$((octet4 + 31))"
}

# Funzione per validare IP
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# GENERAZIONE CONFIGURAZIONE
# ==============================================================================

generate_config() {
    log_info "Generazione configurazione per Struttura ID: $STRUTTURA_ID ($NOME_STRUTTURA)"
    
    # Calcola subnet
    calculate_subnet $STRUTTURA_ID
    
    log_info "Network assegnato: ${NETWORK_ADDRESS}/${NETMASK_BITS}"
    log_info "Gateway: $GATEWAY"
    log_info "Range utilizzabile: $FIRST_USABLE - $LAST_USABLE"
    
    # Crea directory output se non esiste
    mkdir -p "$OUTPUT_DIR"
    
    # Genera file configurazione
    cat > "$CONFIG_FILE" << EOF
! ============================================
! CPE Router Configurazione Automatica
! ============================================
! Struttura ID: $STRUTTURA_ID
! Nome: $NOME_STRUTTURA
! Network: ${NETWORK_ADDRESS}/${NETMASK_BITS}
! Gateway: $GATEWAY
! Generato: $(date '+%Y-%m-%d %H:%M:%S')
! ============================================

! Hostname
hostname CPE-Struttura-$(printf "%03d" $STRUTTURA_ID)
!
! Banner
banner login ^C
*****************************************************
* CPE Router - Regione - Rete Sanitaria            *
* Accesso Riservato                                 *
* Struttura: $NOME_STRUTTURA                        *
* ID: $STRUTTURA_ID                                 *
*****************************************************
^C
!
! Password e sicurezza
enable secret 5 \$1\$mERr\$hx5rVt7rPNoS4wqbXKX7m0
service password-encryption
!
no ip http server
no ip http secure-server
no service config
no service pad
!
! Logging
logging buffered 51200
logging console warnings
!
! Timezone
clock timezone CET 1 0
clock summer-time CEST recurring last Sun Mar 2:00 last Sun Oct 3:00
!
! ============================================
! INTERFACCE
! ============================================

! WAN Interface
interface GigabitEthernet0/0/0
 description Uplink-Rete-Regionale-Fibra-Struttura-${STRUTTURA_ID}
 ip address $GATEWAY $NETMASK
 ip nat outside
 ip access-group WAN-IN in
 no shutdown
!

! LAN Interface
interface GigabitEthernet0/0/1
 description LAN-Interna-${NOME_STRUTTURA}
 ip address $LAN_IP $LAN_NETMASK
 ip nat inside
 no shutdown
!

! ============================================
! ROUTING
! ============================================

ip route 0.0.0.0 0.0.0.0 $CORE_ROUTER
ip route $DATA_CENTER $CORE_ROUTER
!

! ============================================
! NAT
! ============================================

ip nat inside source list NAT-ALLOWED interface GigabitEthernet0/0/0 overload
!
ip access-list standard NAT-ALLOWED
 permit 192.168.1.0 0.0.0.255
!

! ============================================
! FIREWALL
! ============================================

! WAN Input ACL
ip access-list extended WAN-IN
 permit tcp any any established
 permit udp any any established
 permit tcp host 10.1.0.200 host $GATEWAY eq 22
 permit icmp 10.1.0.0 0.0.0.255 any echo
 permit icmp 10.1.0.0 0.0.0.255 any echo-reply
 permit udp any host $GATEWAY eq isakmp
 permit udp any host $GATEWAY eq non500-isakmp
 permit esp any host $GATEWAY
 deny ip any any log
!

! LAN Output ACL
ip access-list extended LAN-OUT
 permit tcp 192.168.1.0 0.0.0.255 10.1.0.0 0.0.0.255 eq 443
 permit tcp 192.168.1.0 0.0.0.255 10.1.0.0 0.0.0.255 eq 22
 permit udp 192.168.1.0 0.0.0.255 host $DNS_PRIMARY eq domain
 permit udp 192.168.1.0 0.0.0.255 host $DNS_SECONDARY eq domain
 permit icmp 192.168.1.0 0.0.0.255 10.1.0.0 0.0.0.255
 deny ip 192.168.1.0 0.0.0.255 10.100.0.0 0.0.255.255 log
 deny ip 192.168.1.0 0.0.0.255 any log
!

interface GigabitEthernet0/0/1
 ip access-group LAN-OUT in
!

! ============================================
! DHCP
! ============================================

ip dhcp excluded-address $LAN_IP 192.168.1.10
ip dhcp excluded-address 192.168.1.251 192.168.1.254
!
ip dhcp pool LAN-POOL
 network 192.168.1.0 255.255.255.0
 default-router $LAN_IP
 dns-server $DNS_PRIMARY $DNS_SECONDARY
 domain-name struttura${STRUTTURA_ID}.local
 lease 7
!

! ============================================
! DNS & NTP
! ============================================

ip name-server $DNS_PRIMARY
ip name-server $DNS_SECONDARY
ip domain-lookup
!
ntp server $CORE_ROUTER
ntp update-calendar
!

! ============================================
! IPsec VPN
! ============================================

crypto isakmp policy 10
 encryption aes 256
 hash sha256
 authentication pre-share
 group 14
 lifetime 86400
!
crypto isakmp key VPN_KEY_STRUTTURA_${STRUTTURA_ID} address $CORE_ROUTER
!
crypto ipsec transform-set VPN-TRANSFORM esp-aes 256 esp-sha256-hmac
 mode tunnel
!
crypto map VPN-MAP 10 ipsec-isakmp
 set peer $CORE_ROUTER
 set transform-set VPN-TRANSFORM
 set pfs group14
 match address VPN-TRAFFIC
!
ip access-list extended VPN-TRAFFIC
 permit ip 192.168.1.0 0.0.0.255 10.1.0.0 0.0.0.255
!
interface GigabitEthernet0/0/0
 crypto map VPN-MAP
!

! ============================================
! QoS
! ============================================

class-map match-any FSE-TRAFFIC
 match access-group name FSE-ACL
!
policy-map QOS-POLICY
 class FSE-TRAFFIC
  priority percent 70
  set dscp ef
 class class-default
  fair-queue
  random-detect
!
ip access-list extended FSE-ACL
 permit tcp any 10.1.0.0 0.0.0.255 eq 443
!
interface GigabitEthernet0/0/0
 service-policy output QOS-POLICY
!

! ============================================
! LOGGING E MONITORING
! ============================================

logging host $SYSLOG_SERVER
logging trap informational
logging facility local7
!
snmp-server community RegioneSNMP RO
snmp-server location "$NOME_STRUTTURA - ID $STRUTTURA_ID"
snmp-server contact "support@regione.it"
snmp-server host $SNMP_SERVER version 2c RegioneSNMP
!
ip flow-export version 9
ip flow-export destination $SNMP_SERVER 2055
!
interface GigabitEthernet0/0/0
 ip flow ingress
 ip flow egress
!

! ============================================
! SSH
! ============================================

crypto key generate rsa modulus 2048
!
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3
!
line vty 0 4
 transport input ssh
 login local
 exec-timeout 15 0
 logging synchronous
 access-class SSH-ACCESS in
!
ip access-list standard SSH-ACCESS
 permit 10.1.0.200
 permit 10.1.0.0 0.0.0.255
 deny any log
!
username admin privilege 15 secret AdminPass${STRUTTURA_ID}!
username regione-admin privilege 15 secret RegionAdmin${STRUTTURA_ID}!
!

! ============================================
! BACKUP
! ============================================

archive
 path tftp://${BACKUP_SERVER}/backups/CPE-$(printf "%03d" $STRUTTURA_ID)-\$h-\$t
 time-period 10080
!

! ============================================
! FINE
! ============================================

end
write memory
EOF

    log_info "Configurazione generata: $CONFIG_FILE"
}

# ==============================================================================
# GENERAZIONE SCRIPT DEPLOYMENT
# ==============================================================================

generate_deployment_script() {
    local deploy_script="${OUTPUT_DIR}/deploy_CPE-${STRUTTURA_ID}.sh"
    
    cat > "$deploy_script" << 'EOFSCRIPT'
#!/bin/bash
################################################################################
# Script di Deployment CPE Router
################################################################################

CPE_IP="$GATEWAY"
USERNAME="admin"
CONFIG_FILE="$CONFIG_FILE"

echo "================================================"
echo "Deployment Configurazione CPE"
echo "Struttura: $NOME_STRUTTURA (ID: $STRUTTURA_ID)"
echo "IP CPE: $CPE_IP"
echo "================================================"

# Verifica connettività
echo -n "Verifica connettività CPE... "
if ping -c 2 -W 2 $CPE_IP > /dev/null 2>&1; then
    echo "OK"
else
    echo "ERRORE: CPE non raggiungibile"
    exit 1
fi

# Backup configurazione esistente
echo "Backup configurazione esistente..."
ssh -o StrictHostKeyChecking=no ${USERNAME}@${CPE_IP} "copy running-config tftp://${BACKUP_SERVER}/backups/CPE-${STRUTTURA_ID}-pre-deploy-$(date +%Y%m%d-%H%M%S).cfg"

# Upload nuova configurazione
echo "Upload nuova configurazione..."
cat "$CONFIG_FILE" | ssh -o StrictHostKeyChecking=no ${USERNAME}@${CPE_IP}

# Verifica configurazione
echo "Verifica configurazione..."
ssh -o StrictHostKeyChecking=no ${USERNAME}@${CPE_IP} "show running-config"

echo "================================================"
echo "Deployment completato con successo"
echo "================================================"

# Post-deployment checks
echo "Esecuzione controlli post-deployment..."

echo "1. Test ping gateway: "
ping -c 4 $CORE_ROUTER

echo "2. Test ping data-center: "
ping -c 4 10.1.0.1

echo "3. Verifica VPN IPsec: "
ssh -o StrictHostKeyChecking=no ${USERNAME}@${CPE_IP} "show crypto isakmp sa"

echo "================================================"
echo "CHECKLIST POST-DEPLOYMENT"
echo "================================================"
echo "[ ] Verifica connettività WAN"
echo "[ ] Verifica connettività LAN"
echo "[ ] Test VPN IPsec attiva"
echo "[ ] Test DHCP funzionante"
echo "[ ] Test accesso FSE da workstation"
echo "[ ] Verifica logging remoto"
echo "[ ] Verifica SNMP monitoring"
echo "================================================"
EOFSCRIPT

    chmod +x "$deploy_script"
    log_info "Script deployment generato: $deploy_script"
}

# ==============================================================================
# GENERAZIONE DOCUMENTAZIONE
# ==============================================================================

generate_documentation() {
    local doc_file="${OUTPUT_DIR}/CPE-${STRUTTURA_ID}-README.md"
    
    cat > "$doc_file" << EOF
# CPE Router - Struttura $NOME_STRUTTURA (ID: $STRUTTURA_ID)

## Informazioni Rete

| Parametro | Valore |
|-----------|--------|
| Network Address | ${NETWORK_ADDRESS}/${NETMASK_BITS} |
| Netmask | $NETMASK |
| Gateway | $GATEWAY |
| Range Utilizzabile | $FIRST_USABLE - $LAST_USABLE |
| Broadcast | $BROADCAST |
| LAN Interna | $LAN_NETWORK |
| LAN Gateway | $LAN_IP |

## Servizi Configurati

- ✅ NAT (LAN → WAN)
- ✅ Firewall (ACL in/out)
- ✅ VPN IPsec verso data-center
- ✅ DHCP Server (LAN)
- ✅ QoS (priorità traffico FSE)
- ✅ SSH (gestione remota)
- ✅ SNMP (monitoring)
- ✅ Syslog (logging remoto)
- ✅ NTP (sincronizzazione orario)

## Credenziali Default

**IMPORTANTE**: Cambiare le password dopo la prima configurazione!

- Username: \`admin\`
- Password: \`AdminPass${STRUTTURA_ID}!\`

- Username: \`regione-admin\`
- Password: \`RegionAdmin${STRUTTURA_ID}!\`

## Comandi Utili

### Verifica Connettività
\`\`\`bash
ping 10.1.0.1          # Data-center
ping $CORE_ROUTER      # Core router
\`\`\`

### Verifica VPN
\`\`\`bash
show crypto isakmp sa
show crypto ipsec sa
\`\`\`

### Verifica NAT
\`\`\`bash
show ip nat translations
show ip nat statistics
\`\`\`

### Verifica Routing
\`\`\`bash
show ip route
show ip interface brief
\`\`\`

### Logs
\`\`\`bash
show logging
show logging | include BLOCK
\`\`\`

## Contatti

- **Supporto Tecnico**: +39 XXX XXXXXXX
- **Email**: support@regione.it
- **Portal**: https://helpdesk.regione.it

## File Generati

- Configurazione: \`$CONFIG_FILE\`
- Deployment Script: \`${OUTPUT_DIR}/deploy_CPE-${STRUTTURA_ID}.sh\`
- Documentazione: \`$doc_file\`

Generato il: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    log_info "Documentazione generata: $doc_file"
}

# ==============================================================================
# GENERAZIONE REPORT CSV
# ==============================================================================

generate_csv_report() {
    local csv_file="${OUTPUT_DIR}/allocazioni.csv"
    local csv_exists=false
    
    # Controlla se file CSV esiste
    if [ -f "$csv_file" ]; then
        csv_exists=true
    else
        # Crea header CSV
        echo "ID,Nome,Network,Gateway,First_IP,Last_IP,Broadcast,LAN_Network,Data_Generazione" > "$csv_file"
    fi
    
    # Aggiungi riga
    echo "${STRUTTURA_ID},\"${NOME_STRUTTURA}\",${NETWORK_ADDRESS}/${NETMASK_BITS},${GATEWAY},${FIRST_USABLE},${LAST_USABLE},${BROADCAST},${LAN_NETWORK},$(date '+%Y-%m-%d %H:%M:%S')" >> "$csv_file"
    
    log_info "Report CSV aggiornato: $csv_file"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    log_info "=== Inizio generazione configurazione CPE ==="
    log_info "Struttura ID: $STRUTTURA_ID"
    log_info "Nome: $NOME_STRUTTURA"
    
    # Genera configurazione
    generate_config
    
    # Genera script deployment
    generate_deployment_script
    
    # Genera documentazione
    generate_documentation
    
    # Genera/aggiorna CSV
    generate_csv_report
    
    log_info "=== Generazione completata con successo ==="
    log_info ""
    log_info "File generati in: $OUTPUT_DIR"
    log_info "  - Configurazione: $CONFIG_FILE"
    log_info "  - Script deployment: ${OUTPUT_DIR}/deploy_CPE-${STRUTTURA_ID}.sh"
    log_info "  - Documentazione: ${OUTPUT_DIR}/CPE-${STRUTTURA_ID}-README.md"
    log_info "  - Report CSV: ${OUTPUT_DIR}/allocazioni.csv"
    log_info ""
    log_info "Prossimi passi:"
    log_info "  1. Revisiona la configurazione generata"
    log_info "  2. Esegui lo script di deployment"
    log_info "  3. Verifica i controlli post-deployment"
}

# Esegui main
main

exit 0

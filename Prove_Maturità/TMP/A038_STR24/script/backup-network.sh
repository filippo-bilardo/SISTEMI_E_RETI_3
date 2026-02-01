#!/bin/bash
# Script di Backup Automatico
# File: backup-network.sh
# Riferimento Prova: Procedure di backup e disaster recovery

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"/{configs,databases,files}

# Backup configurazioni dispositivi di rete
echo "Backup configurazioni dispositivi di rete..."
# Router (esempio con SSH)
# sshpass -p 'password' ssh admin@172.16.0.1 "show running-config" > "$BACKUP_DIR/configs/router-$DATE.conf"

# Backup configurazioni server
echo "Backup configurazioni server..."
tar -czf "$BACKUP_DIR/configs/apache-$DATE.tar.gz" /etc/apache2/ 2>/dev/null
tar -czf "$BACKUP_DIR/configs/postfix-$DATE.tar.gz" /etc/postfix/ /etc/dovecot/ 2>/dev/null
tar -czf "$BACKUP_DIR/configs/bind-$DATE.tar.gz" /etc/bind/ 2>/dev/null
tar -czf "$BACKUP_DIR/configs/iptables-$DATE.tar.gz" /etc/iptables/ 2>/dev/null

# Backup database
echo "Backup database..."
# mysqldump -u root -p'password' --all-databases | gzip > "$BACKUP_DIR/databases/mysql-all-$DATE.sql.gz"

# Backup siti web
echo "Backup siti web..."
tar -czf "$BACKUP_DIR/files/www-$DATE.tar.gz" /var/www/ 2>/dev/null

# Pulizia backup vecchi
echo "Pulizia backup più vecchi di $RETENTION_DAYS giorni..."
find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete

echo "Backup completato: $(date)"

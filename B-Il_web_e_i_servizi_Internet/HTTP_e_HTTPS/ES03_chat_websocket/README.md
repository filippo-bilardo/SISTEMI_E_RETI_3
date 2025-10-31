# ES02 - Chat WebSocket

## Obiettivo
Implementare una chat tra client e server. Scrivere il codice html e javascript per il client da eseguire nel browser; scrivere il codice java, utilizzando le socket, per il server da eseguire tramite terminale.

## 📁 File del Progetto

- **ChatServer.java** - Server Java con Socket TCP
- **client.html** - Client HTML/JavaScript per browser
- **GUIDA.md** - Guida completa con spiegazione dettagliata

## 🚀 Quick Start

### 1. Compila e avvia il server Java

```bash
javac ChatServer.java
java ChatServer
```

### 2. Installa e avvia websockify (proxy WebSocket)

```bash
pip install websockify
websockify localhost:8081 localhost:8080
```

### 3. Apri client.html nel browser

```bash
xdg-open client.html
# oppure apri manualmente il file nel browser
```

## 📖 Documentazione Completa

Leggi **GUIDA.md** per:
- Architettura del sistema
- Spiegazione dettagliata del codice
- Flusso di comunicazione
- Troubleshooting
- Miglioramenti possibili

## 🎯 Funzionalità

✅ Chat multi-utente in tempo reale  
✅ Interfaccia grafica moderna  
✅ Notifiche join/leave  
✅ Gestione connessione/disconnessione  
✅ Codice completamente commentato 


# Guida Completa - Chat Client-Server

## 📋 Descrizione Progetto

Implementazione di una chat multi-utente con:
- **Server**: Java con Socket TCP (esecuzione da terminale)
- **Client**: HTML/JavaScript (esecuzione nel browser)
- **Comunicazione**: WebSocket per connessione browser-server

---

## 🏗️ Architettura del Sistema

```
┌─────────────────┐         WebSocket         ┌──────────────────┐
│   Browser 1     │◄─────────────────────────►│                  │
│  (client.html)  │         ws://8081         │   Websockify     │
└─────────────────┘                           │     Proxy        │
                                              │                  │
┌─────────────────┐         WebSocket         │   localhost:8081 │
│   Browser 2     │◄─────────────────────────►│        ▼         │
│  (client.html)  │         ws://8081         │   Socket TCP     │
└─────────────────┘                           │   localhost:8080 │
                                              │        ▼         │
┌─────────────────┐         WebSocket         │                  │
│   Browser 3     │◄─────────────────────────►│  ChatServer.java │
│  (client.html)  │         ws://8081         │                  │
└─────────────────┘                           └──────────────────┘
```

### Perché serve Websockify?

Il browser può comunicare solo tramite **WebSocket** (protocollo ws://), mentre il server Java usa **Socket TCP puro**. Websockify fa da traduttore tra i due protocolli.

---

## 🚀 Setup e Installazione

### 1. Prerequisiti

```bash
# Java (JDK 8 o superiore)
java -version

# Python 3 (per websockify)
python3 --version

# Pip (package manager Python)
pip3 --version
```

### 2. Installazione Websockify

```bash
# Installa websockify
pip3 install websockify

# Verifica installazione
websockify --help
```

### 3. Compilazione Server Java

```bash
# Vai nella directory del progetto
cd ES02_chat_websocket

# Compila il server
javac ChatServer.java

# Verifica che sia stato creato ChatServer.class
ls -la ChatServer*.class
```

---

## 📝 Esecuzione del Progetto

### Passo 1: Avvia il Server Java

```bash
# Terminale 1 - Server Java
java ChatServer
```

**Output atteso:**
```
=== Chat Server ===
Server in ascolto sulla porta 8080
In attesa di connessioni...
```

### Passo 2: Avvia Websockify (Proxy)

```bash
# Terminale 2 - Websockify Proxy
websockify localhost:8081 localhost:8080
```

**Output atteso:**
```
WebSocket server settings:
  - Listen on localhost:8081
  - Web server disabled
  - Target is localhost:8080
```

### Passo 3: Apri il Client nel Browser

```bash
# Apri con browser predefinito (Linux)
xdg-open client.html

# Oppure apri manualmente:
# File → Apri file → seleziona client.html
```

### Passo 4: Usa la Chat

1. Inserisci il tuo nome utente
2. Clicca "Entra nella Chat"
3. Scrivi messaggi e premi Invio o clicca "Invia"
4. Apri altri tab/browser per testare la chat multi-utente

---

## 📖 Spiegazione del Codice

### ChatServer.java - Server Java

#### Struttura Principale

```java
public class ChatServer {
    private static final int PORT = 8080;
    private static Set<ClientHandler> clientHandlers = new CopyOnWriteArraySet<>();
}
```

**Spiegazione:**
- `PORT`: Porta su cui il server ascolta (8080)
- `clientHandlers`: Set thread-safe di tutti i client connessi
- `CopyOnWriteArraySet`: Permette iterazione sicura anche durante modifiche concorrenti

#### Main Loop

```java
try (ServerSocket serverSocket = new ServerSocket(PORT)) {
    while (true) {
        Socket clientSocket = serverSocket.accept();  // Blocca finché non arriva connessione
        ClientHandler handler = new ClientHandler(clientSocket);
        clientHandlers.add(handler);
        new Thread(handler).start();  // Thread dedicato per ogni client
    }
}
```

**Flusso:**
1. `ServerSocket.accept()` attende connessioni (blocking)
2. Quando arriva un client, crea un `ClientHandler`
3. Lo aggiunge al set dei client attivi
4. Avvia un thread dedicato per gestirlo

#### Broadcast

```java
public static void broadcast(String message, ClientHandler sender) {
    for (ClientHandler client : clientHandlers) {
        client.sendMessage(message);  // Invia a TUTTI i client
    }
}
```

**Spiegazione:**
- Itera su tutti i client connessi
- Invia lo stesso messaggio a tutti
- Implementa la funzionalità "chat room"

#### ClientHandler (Thread per singolo client)

```java
class ClientHandler implements Runnable {
    @Override
    public void run() {
        // 1. Inizializza stream I/O
        out = new PrintWriter(socket.getOutputStream(), true);
        in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
        
        // 2. Riceve username
        username = in.readLine();
        
        // 3. Notifica join
        broadcast("SERVER: " + username + " è entrato nella chat", null);
        
        // 4. Loop ricezione messaggi
        String message;
        while ((message = in.readLine()) != null) {
            broadcast(username + ": " + message, this);
        }
    }
}
```

**Flusso operativo:**
1. Crea stream per leggere/scrivere dal socket
2. Prima riga ricevuta = username del client
3. Notifica a tutti l'ingresso del nuovo utente
4. Loop infinito: legge messaggi e fa broadcast

---

### client.html - Client Browser

#### Connessione WebSocket

```javascript
socket = new WebSocket('ws://localhost:8081');
```

**Spiegazione:**
- Crea connessione WebSocket al proxy (porta 8081)
- Il proxy inoltra al server Java (porta 8080)
- Protocollo: `ws://` (non sicuro) o `wss://` (sicuro con SSL)

#### Event Handlers

```javascript
socket.onopen = function(event) {
    // Connessione stabilita
    socket.send(username);  // Invia username come primo messaggio
};

socket.onmessage = function(event) {
    const message = event.data;  // Messaggio ricevuto
    
    if (message.startsWith('SERVER:')) {
        addSystemMessage(message);  // Notifica di sistema
    } else {
        addUserMessage(message);    // Messaggio utente
    }
};

socket.onerror = function(error) {
    // Gestione errori
};

socket.onclose = function(event) {
    // Connessione chiusa
};
```

**Eventi WebSocket:**
- `onopen`: Chiamato quando la connessione è pronta
- `onmessage`: Chiamato quando arriva un messaggio
- `onerror`: Chiamato in caso di errore
- `onclose`: Chiamato quando la connessione si chiude

#### Invio Messaggi

```javascript
function sendMessage(event) {
    event.preventDefault();  // Previene reload pagina
    
    const message = messageInput.value.trim();
    
    if (message && isConnected) {
        socket.send(message);  // Invia al server
        messageInput.value = '';  // Pulisce input
    }
}
```

**Flusso:**
1. Previene il comportamento default del form
2. Ottiene il testo dall'input
3. Se valido e connesso, invia tramite `socket.send()`
4. Pulisce l'input per il prossimo messaggio

#### Visualizzazione Messaggi

```javascript
function addUserMessage(message) {
    // Formato: "username: testo"
    const colonIndex = message.indexOf(':');
    const user = message.substring(0, colonIndex);
    const text = message.substring(colonIndex + 1);
    
    // Crea elementi DOM
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message user';
    
    // Aggiunge username e testo
    messageDiv.innerHTML = `
        <span class="username">${user}</span>
        <span class="text">${text}</span>
    `;
    
    messagesDiv.appendChild(messageDiv);
    scrollToBottom();
}
```

**Spiegazione:**
1. Parse del messaggio per separare username e testo
2. Crea elemento DOM dinamicamente
3. Applica stili CSS per la visualizzazione
4. Scrolla automaticamente verso il basso

---

## 🔄 Flusso Comunicazione Completo

### 1. Connessione Iniziale

```
Browser                Websockify              Server Java
   │                       │                       │
   │──── new WebSocket ───►│                       │
   │                       │──── TCP connect ─────►│
   │                       │                       │
   │◄──── onopen ─────────│◄──── accept() ────────│
   │                       │                       │
   │──── send(username) ──►│──── write() ─────────►│
   │                       │                       │
```

### 2. Invio Messaggio

```
Browser A              Websockify              Server Java
   │                       │                       │
   │──── send(msg) ───────►│──── write() ─────────►│
   │                       │                       │
   │                       │    ┌─── broadcast() ───┐
   │                       │    │                    │
   │◄──── onmessage ◄─────│◄───┤ Invia a tutti i   │
Browser B                  │    │ client connessi    │
   │◄──── onmessage ◄─────│◄───┤                    │
Browser C                  │    │                    │
   │◄──── onmessage ◄─────│◄───┘                    │
```

### 3. Disconnessione

```
Browser                Websockify              Server Java
   │                       │                       │
   │──── close() ─────────►│──── close() ─────────►│
   │                       │                       │
   │                       │    removeClient()     │
   │                       │    broadcast("user left")
   │                       │                       │
   │◄──── onclose ────────│◄───────────────────────│
```

---

## 🐛 Troubleshooting

### Errore: "Connection refused"

**Causa:** Il server Java non è in esecuzione

**Soluzione:**
```bash
# Verifica che il server sia attivo
java ChatServer
```

### Errore: "WebSocket connection failed"

**Causa:** Websockify non è in esecuzione

**Soluzione:**
```bash
# Avvia websockify
websockify localhost:8081 localhost:8080
```

### Errore: "Port already in use"

**Causa:** La porta è già occupata

**Soluzione:**
```bash
# Trova il processo che usa la porta
lsof -i :8080
lsof -i :8081

# Termina il processo (sostituisci PID)
kill -9 <PID>
```

### Il messaggio non viene visualizzato

**Causa:** Formato messaggio non corretto

**Verifica:**
1. Il server invia messaggi nel formato corretto?
2. I log della console mostrano errori?
3. Il browser riceve effettivamente il messaggio?

```javascript
// Debug nel browser (F12 → Console)
socket.onmessage = function(event) {
    console.log('Messaggio ricevuto:', event.data);
    // ... resto del codice
};
```

---

## 🔐 Miglioramenti Possibili

### 1. Autenticazione
- Aggiungere login con password
- Database utenti
- Token di sessione

### 2. Persistenza
- Salvare messaggi in database
- Storico conversazioni
- Recupero messaggi precedenti

### 3. Features Avanzate
- Chat private (1-to-1)
- Room/canali multipli
- Invio file/immagini
- Notifiche desktop
- Emoji picker
- Typing indicator ("Utente sta scrivendo...")

### 4. Sicurezza
- Crittografia end-to-end
- Rate limiting (prevenzione spam)
- Sanitizzazione input (prevenzione XSS)
- HTTPS/WSS in produzione

---

## 📚 Concetti Chiave Appresi

### Socket TCP (Java)
- Comunicazione client-server bidirezionale
- ServerSocket per ascoltare connessioni
- Socket per comunicare con un client specifico
- Stream I/O: BufferedReader, PrintWriter

### WebSocket (JavaScript)
- Protocollo full-duplex su singola connessione
- Eventi: onopen, onmessage, onerror, onclose
- Metodi: send(), close()
- Differenza tra ws:// e wss://

### Multithreading (Java)
- Thread dedicato per ogni client
- CopyOnWriteArraySet per accesso concorrente
- Gestione sincronizzazione implicita

### DOM Manipulation (JavaScript)
- createElement(), appendChild()
- Event listeners
- Animazioni CSS

### Architettura Client-Server
- Separazione responsabilità
- Protocolli di comunicazione
- Gestione stato connessione
- Broadcast messaging

---

## 📞 Test Multi-Utente

Per testare la chat con più utenti:

1. **Apri 3-4 tab del browser**
2. In ogni tab apri `client.html`
3. Usa nomi utente diversi: Alice, Bob, Carol
4. Scrivi messaggi in un tab
5. Verifica che appaiano in TUTTI i tab

**Output atteso Server:**
```
[CONNESSIONE] Nuovo client connesso: 127.0.0.1
[JOIN] Alice è entrato nella chat
[BROADCAST] SERVER: Alice è entrato nella chat
[CONNESSIONE] Nuovo client connesso: 127.0.0.1
[JOIN] Bob è entrato nella chat
[BROADCAST] SERVER: Bob è entrato nella chat
[BROADCAST] Alice: Ciao a tutti!
[BROADCAST] Bob: Ciao Alice!
```

---

## ✅ Checklist Completamento

- [ ] Server Java compilato senza errori
- [ ] Websockify installato e funzionante
- [ ] Client HTML apre correttamente nel browser
- [ ] Connessione stabilita (status "Connesso")
- [ ] Messaggi inviati vengono ricevuti
- [ ] Broadcast funziona con più client
- [ ] Disconnessione gestita correttamente
- [ ] Log chiari su server e browser console

---

**Progetto completato!** 🎉

Ora hai una chat funzionante con comunicazione real-time tra browser e server Java!

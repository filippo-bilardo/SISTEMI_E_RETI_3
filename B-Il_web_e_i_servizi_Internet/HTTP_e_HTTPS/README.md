Implementare una chat tra client e server. Scrivi il codice client in html e javascript da eseguire nel browser e server con java socket con da eseguire  tramite terminale 


1. **Esempio Base: Richiesta GET**
   - Utilizzo di `HttpURLConnection` per inviare una richiesta GET a un'API pubblica e stampare la risposta.

```java
// Server Java
import java.io.*;
import java.net.*;

public class ChatServer {
    public static void main(String[] args) {
        try (ServerSocket serverSocket = new ServerSocket(12345)) {
            System.out.println("Server in ascolto sulla porta 12345...");
            Socket clientSocket = serverSocket.accept();
            System.out.println("Client connesso: " + clientSocket.getInetAddress());

            BufferedReader in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
            PrintWriter out = new PrintWriter(clientSocket.getOutputStream(), true);
            BufferedReader userInput = new BufferedReader(new InputStreamReader(System.in));

            String clientMessage;
            while ((clientMessage = in.readLine()) != null) {
                System.out.println("Client: " + clientMessage);
                System.out.print("Risposta del server: ");
                String serverResponse = userInput.readLine();
                out.println(serverResponse);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

```javascript
// Client JavaScript
const net = require('net');

const client = new net.Socket();
client.connect(12345, '127.0.0.1', () => {
    console.log('Connesso al server');
    process.stdin.on('data', (data) => {
        client.write(data.toString().trim());
    });
});

client.on('data', (data) => {
    console.log('Risposta del server: ' + data);
});

client.on('close', () => {
    console.log('Connessione chiusa');
});
```

2. **Esempio Intermedio: Richiesta POST con Dati JSON**
   - Inviare una richiesta POST a un'API REST con un corpo JSON utilizzando `HttpClient` e gestire la risposta.

3. **Esempio Avanzato: Autenticazione e HTTPS**
   - Implementare l'autenticazione di base su un'API HTTPS e gestire i certificati SSL.

4. **Esempio Complesso: Client HTTP Asincrono**
   - Creare un client HTTP asincrono utilizzando `CompletableFuture` per gestire più richieste in parallelo.

5. **Esempio Esperto: Gestione degli Errori e Retry**
   - Implementare una logica di retry per le richieste HTTP fallite e gestire gli errori in modo elegante.

Scrivi altri esempi che utilizzano solo i sockets in java per implementare HTTP e HTTPS.

6. **Esempio Base: Server HTTP Semplice con Sockets**
   - Creare un server HTTP di base utilizzando `ServerSocket` che risponde a richieste GET con una pagina HTML statica.

7. **Esempio Intermedio: Client HTTP Semplice con Sockets**
   - Creare un client HTTP di base utilizzando `Socket` per inviare richieste GET a un server e stampare la risposta.

8. **Esempio Avanzato: Server HTTPS con Sockets**
   - Creare un server HTTPS utilizzando `SSLServerSocket` che gestisce le connessioni sicure e risponde a richieste GET.

9. **Esempio Complesso: Client HTTPS con Sockets**
   - Creare un client HTTPS utilizzando `SSLSocket` per inviare richieste sicure a un server e gestire i certificati SSL.

10. **Esempio Esperto: Proxy HTTP con Sockets**
   - Implementare un server proxy HTTP che inoltra le richieste a un server di destinazione e restituisce la risposta al client.

# Esercizi sul protocollo HTTP e HTTPS in Java con le Sockets

1. **Esercizio Base: Implementare un Server HTTP**
   - Creare un server HTTP che risponde con un messaggio "Hello World" a tutte le richieste GET.

2. **Esercizio Intermedio: Gestire Più Client**
   - Modificare il server HTTP per gestire più client contemporaneamente utilizzando thread.

3. **Esercizio Avanzato: Implementare HTTPS**
   - Creare un server HTTPS che utilizza certificati SSL per crittografare le comunicazioni.

4. **Esercizio Complesso: Client HTTP con Sockets**
   - Creare un client HTTP che invia richieste GET a un server e gestisce le risposte in modo asincrono.

5. **Esercizio Esperto: Proxy HTTP con Sockets**
   - Implementare un server proxy HTTP che inoltra le richieste a un server di destinazione e restituisce la risposta al client.
6. **Esercizio Bonus: Logging delle Richieste**
   - Aggiungere funzionalità di logging al server HTTP per registrare tutte le richieste ricevute con timestamp e indirizzo IP del client.
7. **Esercizio Bonus Avanzato: Supporto per Metodi HTTP Multipli**
   - Estendere il server HTTP per supportare metodi HTTP multipli come POST, PUT e DELETE, gestendo correttamente i corpi delle richieste e le risposte.
8. **Esercizio Bonus Esperto: Implementare un Load Balancer**
   - Creare un load balancer HTTP che distribuisce le richieste in arrivo tra più server backend per migliorare le prestazioni e la disponibilità del servizio.


import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;

/**
 * Chat Server - Gestisce connessioni multiple di client
 * 
 * FUNZIONAMENTO:
 * 1. Il server apre una ServerSocket sulla porta 8080
 * 2. Accetta connessioni dai client in un loop infinito
 * 3. Per ogni client crea un thread dedicato (ClientHandler)
 * 4. Broadcast dei messaggi a tutti i client connessi
 * 
 * COMPILAZIONE ED ESECUZIONE:
 * javac ChatServer.java
 * java ChatServer
 */
public class ChatServer {
    // Porta su cui il server ascolta le connessioni
    private static final int PORT = 8080;
    
    // Set thread-safe che contiene tutti i ClientHandler attivi
    // CopyOnWriteArraySet garantisce operazioni thread-safe senza lock espliciti
    private static Set<ClientHandler> clientHandlers = new CopyOnWriteArraySet<>();
    
    public static void main(String[] args) {
        System.out.println("=== Chat Server ===");
        System.out.println("Server in ascolto sulla porta " + PORT);
        System.out.println("In attesa di connessioni...\n");
        
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            // Loop infinito per accettare nuove connessioni
            while (true) {
                // accept() blocca il thread finché non arriva una connessione
                Socket clientSocket = serverSocket.accept();
                
                // Ottiene l'indirizzo IP del client connesso
                String clientAddress = clientSocket.getInetAddress().getHostAddress();
                System.out.println("[CONNESSIONE] Nuovo client connesso: " + clientAddress);
                
                // Crea un nuovo handler per gestire questo client
                ClientHandler clientHandler = new ClientHandler(clientSocket);
                clientHandlers.add(clientHandler);
                
                // Avvia il thread del client handler
                new Thread(clientHandler).start();
                
                System.out.println("[INFO] Client attivi: " + clientHandlers.size());
            }
        } catch (IOException e) {
            System.err.println("[ERRORE] Errore del server: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Broadcast: invia un messaggio a tutti i client connessi
     * @param message Il messaggio da inviare
     * @param sender Il client che ha inviato il messaggio (può essere null)
     */
    public static void broadcast(String message, ClientHandler sender) {
        System.out.println("[BROADCAST] " + message);
        
        // Itera su tutti i client handler
        for (ClientHandler client : clientHandlers) {
            // Invia il messaggio a tutti i client (incluso il sender)
            client.sendMessage(message);
        }
    }
    
    /**
     * Rimuove un client handler dalla lista quando si disconnette
     * @param clientHandler Il client da rimuovere
     */
    public static void removeClient(ClientHandler clientHandler) {
        clientHandlers.remove(clientHandler);
        System.out.println("[DISCONNESSIONE] Client rimosso. Client attivi: " + clientHandlers.size());
    }
    
    /**
     * ClientHandler - Thread dedicato per gestire un singolo client
     * Ogni client ha il suo thread per ricevere e inviare messaggi
     */
    static class ClientHandler implements Runnable {
        private Socket socket;
        private PrintWriter out;      // Stream per inviare messaggi al client
        private BufferedReader in;     // Stream per ricevere messaggi dal client
        private String username;       // Nome utente del client
        
        public ClientHandler(Socket socket) {
            this.socket = socket;
        }
        
        @Override
        public void run() {
            try {
                // Inizializza gli stream di input/output
                out = new PrintWriter(socket.getOutputStream(), true);
                in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
                
                // Riceve il nome utente come primo messaggio
                username = in.readLine();
                if (username == null || username.trim().isEmpty()) {
                    username = "Utente" + socket.getPort(); // Nome di default
                }
                
                System.out.println("[JOIN] " + username + " è entrato nella chat");
                
                // Notifica a tutti che un nuovo utente è entrato
                broadcast("SERVER: " + username + " è entrato nella chat", null);
                
                // Loop di ricezione messaggi
                String message;
                while ((message = in.readLine()) != null) {
                    // Se il messaggio è vuoto, ignora
                    if (message.trim().isEmpty()) {
                        continue;
                    }
                    
                    // Formatta il messaggio con il nome utente
                    String formattedMessage = username + ": " + message;
                    
                    // Invia il messaggio a tutti i client
                    broadcast(formattedMessage, this);
                }
                
            } catch (IOException e) {
                System.err.println("[ERRORE] Errore con client " + username + ": " + e.getMessage());
            } finally {
                // Pulizia quando il client si disconnette
                disconnect();
            }
        }
        
        /**
         * Invia un messaggio a questo client specifico
         * @param message Il messaggio da inviare
         */
        public void sendMessage(String message) {
            if (out != null) {
                out.println(message);
            }
        }
        
        /**
         * Gestisce la disconnessione del client
         * Chiude gli stream e rimuove il client dalla lista
         */
        private void disconnect() {
            try {
                // Rimuove il client dalla lista
                ChatServer.removeClient(this);
                
                // Notifica agli altri utenti
                if (username != null) {
                    System.out.println("[LEAVE] " + username + " ha lasciato la chat");
                    broadcast("SERVER: " + username + " ha lasciato la chat", null);
                }
                
                // Chiude gli stream e il socket
                if (in != null) in.close();
                if (out != null) out.close();
                if (socket != null) socket.close();
                
            } catch (IOException e) {
                System.err.println("[ERRORE] Errore durante la disconnessione: " + e.getMessage());
            }
        }
    }
}

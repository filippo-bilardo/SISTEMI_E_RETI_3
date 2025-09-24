// Il nostro secondo programma

// Il nome della classe è uguale al nome del file
class CiaoMondo2 {
    public static void main(String[] args) {
        // Dichiarazione e inizializzazione delle stringhe
        String hello = "Ciao ";      // Stringa di saluto con spazio finale
        String world = "mondo\n";    // Stringa "mondo" con carattere di nuova riga
        
        // Prima riga: stampa "CIAO " in maiuscolo seguito da "mondo" e poi "odnom" (mondo al contrario)
        System.out.print(hello.toUpperCase()); // Converte "Ciao " in "CIAO " e lo stampa
        
        // Primo ciclo: stampa ogni carattere di "mondo\n" (incluso il \n)
        for(int i=0; i<world.length(); i++) {
            System.out.print(world.charAt(i));  // Stampa carattere per carattere: m-o-n-d-o-\n
        }
        
        // Secondo ciclo: stampa "mondo" al contrario (escluso il \n finale)
        // Inizia da world.length()-2 per saltare il carattere \n
        for(int i=world.length()-2; i>=0; i--) {
            System.out.print(world.charAt(i));  // Stampa caratteri al contrario: o-d-n-o-m
        }
        
        // Seconda riga: stampa uno spazio, poi "Ciao " originale, poi va a capo
        System.out.print(" " + hello + "\n");   // Stampa " Ciao " seguito da nuova riga
        
        // Terza riga: stampa una linea di separazione
        System.out.println("---");              // Stampa "---" e va automaticamente a capo
        
        /* 
         * Output del programma:
         * CIAO mondo
         * odnom Ciao 
         * ---
         */
    }
}

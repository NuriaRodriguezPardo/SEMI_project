import processing.serial.*;
import org.firmata.*;
import cc.arduino.*;
import themidibus.*;

// Objetos principales
Arduino arduino;
MidiBus myBus;
ArrayList<Particula> rastro;

// Configuración del Teclado (Matriz 2x4)
//int[] pinesFilas = {9, 8};
int[] pinesBotones = {5, 4, 3, 2};
//boolean[][] estadoAnterior = new boolean[2][4];
boolean[] estadoAnterior = new boolean[pinesBotones.length];

// Variables de control
int notaAnterior = -1;
int instrumentoActual = 0;

void setup() {
  fullScreen();
  colorMode(HSB, 360, 100, 100, 100);
  
  // 1. Inicializar Arduino con Firmata
  // Imprime la lista para que verifiques el índice de tu puerto COM
  println(Arduino.list()); 
  arduino = new Arduino(this, Arduino.list()[0], 57600); // Cambia el [0] si es necesario
  
  // Configurar pines: Filas como INPUT_PULLUP, Columnas como OUTPUT
  //for (int f : pinesFilas) arduino.pinMode(f, Arduino.INPUT_PULLUP);
  //for (int c : pinesColumnas) arduino.pinMode(c, Arduino.OUTPUT);
  for (int p : pinesBotones) arduino.pinMode(p, Arduino.INPUT_PULLUP);
  

  // 2. Inicializar MIDI
  
  myBus = new MidiBus(null, 1, 3); 
  
  rastro = new ArrayList<Particula>();
  noCursor();
}

void draw() {
  background(0);

  // --- LÓGICA DEL TECLADO (FIRMATA) ---
  leerBotonesIndependientes();

  // --- LÓGICA VISUAL ---
  if (mouseX != pmouseX || mouseY != pmouseY) {
    for (int i = 0; i < 3; i++) rastro.add(new Particula(mouseX, mouseY));
  }

  for (int i = rastro.size()-1; i >= 0; i--) {
    Particula p = rastro.get(i);
    p.update();
    p.display();
    if (p.estaMuerta()) rastro.remove(i);
  }

  // --- LÓGICA SONORA (MOUSE) ---
  gestionarSonidoMouse();
}
/*
void leerTecladoFisico() {
  // Escaneo manual de la matriz 2x4
  for (int c = 0; c < 4; c++) {
    // Activamos una columna a la vez (LOW porque usamos PULLUP en las filas)
    for (int j = 0; j < 4; j++) arduino.digitalWrite(pinesColumnas[j], Arduino.HIGH);
    arduino.digitalWrite(pinesColumnas[c], Arduino.LOW);

    for (int f = 0; f < 2; f++) {
      boolean estaPresionado = (arduino.digitalRead(pinesFilas[f]) == Arduino.LOW);
      
      // Detectar flanco de bajada (clic)
      if (estaPresionado && !estadoAnterior[f][c]) {
        ejecutarAccionTeclado(f, c);
      }
      estadoAnterior[f][c] = estaPresionado;
    }
  }
}
*/
void leerBotonesIndependientes() {
  for (int i = 0; i < pinesBotones.length; i++) {
    // Al usar INPUT_PULLUP, el botón presionado devuelve LOW
    boolean estaPresionado = (arduino.digitalRead(pinesBotones[i]) == Arduino.LOW);
    
    // Detectar el momento justo en que se presiona (flanco de bajada)
    if (estaPresionado && !estadoAnterior[i]) {
      ejecutarAccion(i);
    }
    estadoAnterior[i] = estaPresionado;
  }
}

/*
void ejecutarAccionTeclado(int fila, int col) {
  // Mapeo de instrumentos según tu código original
  if (fila == 0) {
    if (col == 0) 
    {
      cambiarInstrumento(18);  // Tecla 1: Piano
      println("Has presionado S1");
    }
    if (col == 1) 
    {
      cambiarInstrumento(24);  // Tecla 2: Guitarra
      println("Has presionado S2");
    }
    if (col == 2) 
    {
      cambiarInstrumento(65);  // Tecla 3: Saxo
      println("Has presionado S3");
    }
    if (col == 3) 
    {
      cambiarInstrumento(41);  // Tecla 4: Violin
      println("Has presionado S4");
    }
  }
  // Puedes añadir más casos para la fila 1 (teclas 5, 6, 7, 8) aquí
}
*/

void ejecutarAccion(int indiceBoton) {
  // Asignamos instrumentos según el índice del botón en el array
  switch(indiceBoton) {
    case 0: cambiarInstrumento(0);  break; // Piano (Botón pin 2)
    case 1: cambiarInstrumento(29); break; // Electrica (Botón pin 3)
    case 2: cambiarInstrumento(64); break; // Saxo (Botón pin 4)
    case 3: cambiarInstrumento(40); break; // Violín (Botón pin 5)
  }
}

void cambiarInstrumento(int id) {
  instrumentoActual = id;
  myBus.sendMessage(0xC0, 0, instrumentoActual, 0);
  println("Instrumento cambiado a: " + id);
}

void gestionarSonidoMouse() {
  int nuevaNota = (int) map(mouseX, 0, width, 36, 96);
  int volumen = (int) map(mouseY, 0, height, 110, 40);

  if (nuevaNota != notaAnterior && mouseX != pmouseX) {
    myBus.sendNoteOff(0, notaAnterior, 0);
    myBus.sendNoteOn(0, nuevaNota, volumen);
    notaAnterior = nuevaNota;
  }
}

// --- CLASE PARTÍCULA ---
class Particula {
  PVector pos, vel;
  float vida = 100;
  color c;

  Particula(float x, float y) {
    pos = new PVector(x, y);
    vel = new PVector(random(-1, 1), random(-1, 1));
    float tono = map(x, 0, width, 330, 220);
    float brillo = map(y, 0, height, 100, 30);
    c = color(tono, 80, brillo); 
  }

  void update() {
    pos.add(vel);
    vida -= 2.0;
  }

  void display() {
    noStroke();
    fill(c, vida);
    float tam = map(vida, 100, 0, 15, 2);
    ellipse(pos.x, pos.y, tam, tam);
  }

  boolean estaMuerta() { return vida <= 0; }
}

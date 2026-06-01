import processing.serial.*;
import org.firmata.*;
import cc.arduino.*;
import themidibus.*;

// Objetos principales
Arduino arduino;
MidiBus myBus;
ArrayList<Particula> rastro;

int pinPot = 0; // Pin analógico A0
int instrumentoActual = -1; // Empezamos en -1 para forzar el primer cambio

int notaAnterior = -1;

void setup() {
  fullScreen();
  colorMode(HSB, 360, 100, 100, 100);
  
  // 1. Inicializar Arduino con Firmata
  // Imprime la lista para que verifiques el índice de tu puerto COM
  println(Arduino.list()); 
  arduino = new Arduino(this, Arduino.list()[0], 57600);

  // 2. Inicializar MIDI
  
  myBus = new MidiBus(null, 1, 3); 
  
  rastro = new ArrayList<Particula>();
  noCursor();
}

void draw() {
  background(0);

  // --- LÓGICA DEL TECLADO (FIRMATA) ---
  leerPotenciometro();
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

  gestionarSonidoMouse();
  dibujarTextoPantalla();
}

void leerPotenciometro() {
  // El Arduino lee de 0 a 1023. Lo mapeamos de 0 a 127 (los 128 instrumentos MIDI)
  int valorPot = arduino.analogRead(pinPot);
  int nuevoInstrumento = (int) map(valorPot, 0, 1023, 0, 127);
  
  // Solo enviamos el mensaje MIDI si la posición del potenciómetro cambió
  if (nuevoInstrumento != instrumentoActual) {
    instrumentoActual = nuevoInstrumento;
    myBus.sendMessage(0xC0, 0, instrumentoActual, 0); // 0xC0 es Program Change
    // Obtener el nombre del grupo
    String nombreGrupo = obtenerGrupoMIDI(instrumentoActual);
    
    // Imprimir en terminal según lo solicitado
    println("Instrumento MIDI cambiado a: " + instrumentoActual + " del grupo musical: " + nombreGrupo);
  }
}

void dibujarTextoPantalla() {
  String nombreGrupo = obtenerGrupoMIDI(instrumentoActual);
  String mensaje = "Instrumento MIDI cambiado a: " + instrumentoActual + " del grupo musical: " + nombreGrupo;
  
  fill(255); // Color blanco
  textSize(18); // Tamaño de letra legible
  textAlign(RIGHT, TOP); // Alineación a la derecha y arriba
  
  // Dibujamos con un margen de 20 píxeles desde los bordes
  text(mensaje, width - 20, 20);
}

String obtenerGrupoMIDI(int id) {
  if (id >= 0   && id <= 7)   return "Piano";
  if (id >= 8   && id <= 15)  return "Percusión Cromática";
  if (id >= 16  && id <= 23)  return "Órgano";
  if (id >= 24  && id <= 31)  return "Guitarra";
  if (id >= 32  && id <= 39)  return "Bajo";
  if (id >= 40  && id <= 47)  return "Cuerdas (Strings)";
  if (id >= 48  && id <= 55)  return "Ensamble";
  if (id >= 56  && id <= 63)  return "Metales (Brass)";
  if (id >= 64  && id <= 71)  return "Lengüeta (Reed)";
  if (id >= 72  && id <= 79)  return "Viento (Pipe)";
  if (id >= 80  && id <= 87)  return "Sintetizador solista (Lead)";
  if (id >= 88  && id <= 95)  return "Sintetizador ambiental (Pad)";
  if (id >= 96  && id <= 103) return "Efectos de sintetizador (FX)";
  if (id >= 104 && id <= 111) return "Étnico";
  if (id >= 112 && id <= 119) return "Percusivo";
  if (id >= 120 && id <= 127) return "Efectos de sonido";
  return "Desconocido";
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

import themidibus.*; // Importamos la librería

MidiBus myBus; 
ArrayList<Particula> rastro; // Lista para el efecto de la colilla

int notaAnterior = -1; // Para no repetir la misma nota mil veces por segundo

void setup() {
  fullScreen(); // Pantalla completa
  background(0);
  
  // Usamos HSB para controlar mejor los colores: 
  // Tono (0-360), Saturación (0-100), Brillo (0-100)
  colorMode(HSB, 360, 100, 100, 100); 
  
  // Inicialización de MIDI con el parche para Processing 4
  // Cambia el "1" por el índice de tu sintetizador si no suena
  myBus = new MidiBus(null, 1, 3); 
  myBus.registerParent(this);
  
  // Cambiamos al instrumento 0 (Piano Acústico) en el canal 0
  myBus.sendMessage(0xC0, 0, 0, 0); 
  
  rastro = new ArrayList<Particula>();
  noCursor(); // Escondemos el ratón para que solo se vea la magia
}

void draw() {
  background(0); // Fondo negro total

  // 1. LÓGICA VISUAL (El rastro de fantasía)
  if (mouseX != pmouseX || mouseY != pmouseY) {
    // Si el ratón se mueve, añadimos partículas
    for (int i = 0; i < 3; i++) {
      rastro.add(new Particula(mouseX, mouseY));
    }
  }

  // Dibujar y actualizar partículas
  for (int i = rastro.size()-1; i >= 0; i--) {
    Particula p = rastro.get(i);
    p.update();
    p.display();
    if (p.estaMuerta()) {
      rastro.remove(i);
    }
  }

  // 2. LÓGICA MIDI (Sonido basado en posición)
  gestionarSonido();
}

void gestionarSonido() {
  // MAPEOS:
  // X (Izquierda-Derecha) -> Notas (de 36 a 96, que es un rango de piano amplio)
  int nuevaNota = (int) map(mouseX, 0, width, 36, 96);
  
  // Y (Arriba-Abajo) -> Volumen/Velocity (Arriba más fuerte: 110, abajo más suave: 40)
  int volumen = (int) map(mouseY, 0, height, 110, 40);

  // Solo disparamos el piano si cambiamos de nota o si nos movemos
  if (nuevaNota != notaAnterior && mouseX != pmouseX) {
    // Apagamos la nota anterior para que no se amontonen
    myBus.sendNoteOff(0, notaAnterior, 0); 
    
    // Encendemos la nueva
    myBus.sendNoteOn(0, nuevaNota, volumen);
    notaAnterior = nuevaNota;
  }
}

// --- CLASE PARA EL EFECTO VISUAL ---
class Particula {
  PVector pos;
  PVector vel;
  float vida = 100; // Opacidad inicial
  color c;

  Particula(float x, float y) {
    pos = new PVector(x, y);
    // Un poco de movimiento aleatorio para el efecto fantasía
    vel = new PVector(random(-1, 1), random(-1, 1));
    
    // LÓGICA DE COLOR SOLICITADA:
    // Izquierda (Cálidos: Rojos/Naranjas 0-40) -> Derecha (Fríos: Azules/Violetas 180-280)
    float tono = map(x, 0, width, 330, 220);
    
    // Arriba (Brillantes: 100) -> Abajo (Menos brillantes: 30)
    float brillo = map(y, 0, height, 100, 30);
    
    c = color(tono, 80, brillo); 
  }

  void update() {
    pos.add(vel);
    vida -= 2.0; // Se va desvaneciendo
  }

  void display() {
    noStroke();
    fill(c, vida); // El segundo parámetro es la transparencia
    // Dibujamos círculos que se achican con la vida
    float tam = map(vida, 100, 0, 15, 2);
    ellipse(pos.x, pos.y, tam, tam);
  }

  boolean estaMuerta() {
    return vida <= 0;
  }
}

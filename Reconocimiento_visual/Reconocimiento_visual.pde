import processing.video.*;
import gab.opencv.*;
import java.awt.*;
 
PImage photo;
int pixelcount;
color pixelcolor;
 
Capture firstcam;
OpenCV opencv;

int ancho = 1920;
int alto = 1080;
int factor = 2; //factor que reduce dimensiones >> aumenta velocidad de muestreo

boolean saved = false;

int blackValue = -16000000;
int brightnessValue = 20;
int whiteValue = -13000000;

int loops = 1;

int row = 0;
int column = 0;

void settings() {
  size(ancho/factor, alto/factor);  // Dimensiones de pantalla
}
 
void setup() {
  
  firstcam=new Capture(this, ancho/factor, alto/factor);  //iniciar captura, dimensiones
  opencv=new OpenCV(this, ancho/factor, alto/factor); //iniciar OPENCV
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE); //activar OPENCV para reconocimiento visual
  
  firstcam.start(); //iniciar camara
  frameRate(60); //Muestreo del programa
  
  // Variables para dibujar
  noFill(); //figuras geometricas sin relleno
  stroke(255,255,0); //color amarillo de linea
  strokeWeight(5); //ancho de linea
}
 
void draw() {
  opencv.loadImage(firstcam); //cargar captura de video a procesar
  Rectangle[] faces = opencv.detect(); //detectar caras
  image(firstcam, 0, 0); //mostrar captura de video
  
 //Dibujar marcos recorriendo la lista faces
  for (int i = 0 ; i < faces.length ; i++) {
    // loop through columns
    row = faces[i].x;
    column = faces[i].x;
    while(column < faces[i].x + faces[i].width) {
      //println("Sorting Column " + column);
      firstcam.loadPixels(); 
      sortColumn(faces, i);
      column++;
      firstcam.updatePixels();
    }
    image(firstcam, 0, 0, width, height);
  }
}
 
void captureEvent(Capture c) { //evento de captura de imagen
  c.read();
}

void sortRow(Rectangle[] faces, int z) {
  // current row
  int y = row;
  
  // where to start sorting
  int x = 0;
  
  // where to stop sorting
  int xend = 0;
  
  while(xend < faces[z].width-1) {
     x = getFirstBrightX(x, y);
        xend = getNextDarkX(x, y);
    if(x < 0) break;
    
    int sortLength = xend-x;
    
    color[] unsorted = new color[sortLength];
    color[] sorted = new color[sortLength];
    
    for(int i=0; i<sortLength; i++) {
      unsorted[i] = firstcam.pixels[x + i + y * firstcam.width];
    }
    
    sorted = sort(unsorted);
    
    for(int i=0; i<sortLength; i++) {
      firstcam.pixels[x + i + y * firstcam.width] = sorted[i];      
    }
    
    x = xend+1;
  }
}


void sortColumn(Rectangle[] faces, int z) {
  // current column
  int x = column;
  
  // where to start sorting
  int y = 0;
  
  // where to stop sorting
  int yend = 0;
  
  while(yend < faces[z].height-1) {

        y = getFirstBrightY(x, y);
        yend = getNextDarkY(x, y);
     
    
    if(y < 0) break;
    
    int sortLength = yend-y;
    
    color[] unsorted = new color[sortLength];
    color[] sorted = new color[sortLength];
    
    for(int i=0; i<sortLength; i++) {
      unsorted[i] = firstcam.pixels[x + (y+i) * firstcam.width];
    }
    
    sorted = sort(unsorted);
    
    for(int i=0; i<sortLength; i++) {
      firstcam.pixels[x + (y+i) * firstcam.width] = sorted[i];
    }
    
    y = yend+1;
  }
}

// brightness x
int getFirstBrightX(int x, int y) {
  
  while(brightness(firstcam.pixels[x + y * firstcam.width]) < brightnessValue) {
    x++;
    if(x >= firstcam.width)
      return -1;
  }
  
  return x;
}

int getNextDarkX(int _x, int _y) {
  int x = _x+1;
  int y = _y;
  
  while(brightness(firstcam.pixels[x + y * firstcam.width]) > brightnessValue) {
    x++;
    if(x >= firstcam.width) return firstcam.width-1;
  }
  return x-1;
}

// brightness y
int getFirstBrightY(int x, int y) {

  if(y < firstcam.height) {
    while(brightness(firstcam.pixels[x + y * firstcam.width]) < brightnessValue) {
      y++;
      if(y >= firstcam.height)
        return -1;
    }
  }
  
  return y;
}

int getNextDarkY(int x, int y) {
  y++;

  if(y < firstcam.height) {
    while(brightness(firstcam.pixels[x + y * firstcam.width]) > brightnessValue) {
      y++;
      if(y >= firstcam.height)
        return firstcam.height-1;
    }
  }
  return y-1;
}

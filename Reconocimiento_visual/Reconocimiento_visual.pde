import processing.video.*;
import gab.opencv.*;
import java.awt.*;

/*
Osvaldo Torres and Esteban Sandoval, 2019
for Habitantes de la Imagen
–––––––––––––––––––––––
Code based strongly on:
ASDF Pixel Sort
Kim Asendorf | 2010 | kimasendorf.com
*/

PImage photo;
int pixelcount;
color pixelcolor;

Capture cam;
OpenCV opencv;

int ancho = 1920;
int alto = 1080;
int factor = 2; // factor que reduce dimensiones >> aumenta velocidad de
                // muestreo

boolean saved = false;

int brightnessValue = 30;

int row = 0;
int column = 0;
boolean image = false;

void settings() {
  size(ancho / factor, alto / factor); // Dimensiones de pantalla
}

void setup() {

  cam = new Capture(this, ancho / factor,
                    alto / factor); // iniciar captura, dimensiones
  opencv = new OpenCV(this, ancho / factor, alto / factor); // iniciar OPENCV
  opencv.loadCascade(
      OpenCV.CASCADE_FRONTALFACE); // activar OPENCV para reconocimiento visual

  cam.start();   // iniciar camara
  frameRate(60); // Muestreo del programa

  // Variables para dibujar
  noFill();            // figuras geometricas sin relleno
  stroke(255, 255, 0); // color amarillo de linea
  strokeWeight(5);     // ancho de linea
}

void draw() {
  if (cam.available()) {
    // Reads the new frame
    cam.read();
  }
  opencv.loadImage(cam);               // cargar captura de video a procesar
  Rectangle[] faces = opencv.detect(); // detectar caras
  image(cam, 0, 0);                    // mostrar captura de video
  // Dibujar marcos recorriendo la lista faces
  for (int i = 0; i < faces.length; i++) {
    // loop through columns
    row = faces[i].y;
    int noise = round(200 * noise(faces[i].x));
    if (faces[i].x - 150 >= 0 && faces[i].x + faces[i].width + 150 < cam.width)
      column = round(map(noise, 0, 200, faces[i].x - 150,
                         faces[i].x + faces[i].width + 150));
    else
      column =
          round(map(noise, 0, 200, faces[i].x, faces[i].x + faces[i].width));
    while (column < faces[i].x + faces[i].width) {
      // println("Sorting Column " + column);
      cam.loadPixels();
      sortColumn(faces, i);
      column++;
      cam.updatePixels();
    }
  }
  //tint(255, 50);
  //delay(50);
  image(cam, 0, 0, width, height);
  /*
  if (faces.length > 0){
          ellipse(faces[0].x + faces[0].width/2, faces[0].y + faces[0].height/2,
  faces[0].width, faces[0].height); //Dibujar marco eliptico rect(faces[0].x,
  faces[0].y, faces[0].width, faces[0].height); //Dibujar marco rectangular
  }*/
}

void sortColumn(Rectangle[] faces, int z) {
  // current column
  int x = column;

  // int noiseStart = round(map(round(100*noise(column, row, z)), 0, 100,
  // faces[z].y, faces[z].y + faces[z].height));
  // where to start sorting
  int noiseStart = round(300 * noise(column));
  int y, yend;
  if (faces[z].y - noiseStart > 0) {
    y = faces[z].y - noiseStart;
    // where to stop sorting
    yend = faces[z].y - noiseStart;
  } else {
    y = 0;
    // where to stop sorting
    yend = 0;
  }
  while (yend < cam.height - 1) {
    int noiseEnd = round(500 * noise(column));
    if (faces[z].y + faces[z].height + noiseEnd < cam.height) {
      y = getFirstBrightY(x, y, faces[z].y + faces[z].height + noiseEnd);
      yend = getNextDarkY(x, y, faces[z].y + faces[z].height + noiseEnd);
    } else {
      y = getFirstBrightY(x, y, cam.height);
      yend = getNextDarkY(x, y, cam.height);
    }

    if (y < 0)
      break;

    int sortLength = yend - y;

    color[] unsorted = new color[sortLength];
    color[] sorted = new color[sortLength];

    for (int i = 0; i < sortLength; i++) {
      unsorted[i] = cam.pixels[x + (y + i) * cam.width];
    }

    sorted = sort(unsorted);
    for (int i = 0; i < sortLength; i++) {
      cam.pixels[x + (y + i) * cam.width] = sorted[i];
    }
    y = yend + 1;
  }
}

// brightness y
int getFirstBrightY(int x, int y, int height) {
  if (y < height) {
    while (brightness(cam.pixels[x + y * cam.width]) < brightnessValue) {
      y++;
      if (y >= height)
        return -1;
    }
  }

  return y;
}

int getNextDarkY(int x, int y, int height) {
  y++;
  if (y < height) {
    while (brightness(cam.pixels[x + y * cam.width]) > brightnessValue) {
      y++;
      if (y >= height)
        return height - 1;
    }
  }
  return y - 1;
}

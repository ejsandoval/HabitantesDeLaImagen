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

PImage glitchPhoto;
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
int startTime;
int elapsed;
boolean faceDetected = false;

void settings() {
  size(ancho / factor, alto / factor); // Dimensiones de pantalla
}

void setup() {
  startTime = 0;
  elapsed = 0;
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
  elapsed = millis() - startTime;
  println(elapsed);
  if (cam.available()) {
    // Reads the new frame
    cam.read();
  }
  opencv.loadImage(cam);
    image(cam, 0, 0, width, height);
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

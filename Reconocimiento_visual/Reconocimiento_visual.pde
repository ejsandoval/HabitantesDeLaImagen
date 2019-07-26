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

PImage glitch;

Capture cam;
OpenCV opencv;

int ancho = 1920;
int alto = 1080;
int factor = 2; // factor que reduce dimensiones >> aumenta velocidad de
                // muestreo

boolean saved = false;
boolean sortBool; // boolean that changes every drawn frame for reversing sort

int brightnessValue;

int row = 0;
int column = 0;
int startTime;
int currentTime;
int faceStartTime = 0;
int faceTime = 30000;
int faceChangeStartTime;
int elapsed;
int currentDetectedFaces;
int prevDetectedFaces;
int readIndex = 0;
int numReadings = 30;
int[] readings;
boolean faceDetected = false;

void settings() {
  size(ancho / factor, alto / factor); // Dimensiones de pantalla
}

void setup() {
  // fullScreen(1);
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
  readings = new int[numReadings];
  for (int i = 0; i < numReadings; i++) {
    readings[i] = 0;
  }
}

void draw() {
  translate(width, height/2 - 1600/2);
  scale(1.6);
  rotate(HALF_PI);

  elapsed = millis() - startTime;

  // Reads the new frame
  if (cam.available()) {
    cam.read();
  }
  opencv.loadImage(cam);               // cargar captura de video a procesar
  Rectangle[] faces = opencv.detect(); // detectar caras
  readings[readIndex] = faces.length;
  int sum = 0;
  for (int value : readings) {
    sum += value;
  }
  currentDetectedFaces = Math.round(sum / numReadings);
  currentTime = millis();

  println("prev: ", prevDetectedFaces);
  println("current: ", currentDetectedFaces);

  if (faceChangeStartTime == 0) {
    prevDetectedFaces = faces.length;
    faceChangeStartTime = currentTime;
  }

  if (currentDetectedFaces > prevDetectedFaces && !faceDetected) {
    faceDetected = true;
    prevDetectedFaces++;
    startTime = currentTime;
  }
  elapsed = currentTime - startTime;
  println(faceDetected);

  if (faceDetected && elapsed > faceTime) {
    faceDetected = false;
    prevDetectedFaces--;
    int S = second();
    int M = minute();
    int h = hour();
    int d = day();   // Values from 1 - 31
    int m = month(); // Values from 1 - 12
    int y = year();  // 2003, 2004, 2005, etc.
    String filename = String.valueOf(y) + "-" + String.valueOf(m) + "-" +
                      String.valueOf(d) + " " + String.valueOf(h) + ":" +
                      String.valueOf(M) + ":" + String.valueOf(S) + ".jpg";
    save(filename);
  }

  if (faceDetected && elapsed < 5000) {
    glitch = createImage(ancho / factor, alto / factor, ARGB);
    glitch.loadPixels();
  }

  // Setting brightness value for each frame
  brightnessValue = round(random(15, 50));
  // Loading cam pixels for glitch generation
  cam.loadPixels();

  // loop through columns
  if (faceDetected) {
    for (int i = 0; i < faces.length; i++) {
      row = faces[i].y;
      int random = round(random(0, 100));
      column = round(map(random, 0, 100, faces[i].x - 20, faces[i].x));
      if (column < 0)
        column = 0;
      int end = round(map(random, 0, 100, faces[i].x + faces[i].width,
                          faces[i].x + faces[i].width + 20));
      if (end > ancho / factor)
        end = ancho / factor;
      while (column <= end) {
        sortColumn(faces, i);
        column++;
        glitch.updatePixels();
      }
    }
  }
  tint(190, 240, 250, 255);
  // Show camera image and place on top glitch if a face is detected
  image(cam, 0, 0, width, height);
  if (faceDetected)
    image(glitch, 0, 0, width, height);
  println(readIndex);
  readIndex++;
  if (readIndex >= numReadings) {
    readIndex = 0;
  }
}

void sortColumn(Rectangle[] faces, int z) {
  // current column
  int x = column;

  // where to start sorting
  int noiseStart = round(50 * noise(column));
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
    int noiseEnd = round(150 * noise(column));
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

    // if (sortBool == true) {
    //   sorted = sort(unsorted);
    //   sortBool = false;
    // } else {
    //   sorted = sort(unsorted);
    //   sorted = reverse(sorted);
    //   sortBool = true;
    // }

    for (int i = 0; i < sortLength; i++) {
      if (glitch.pixels[x + (y + i) * cam.width] == 0)
        glitch.pixels[x + (y + i) * cam.width] = sorted[i];
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

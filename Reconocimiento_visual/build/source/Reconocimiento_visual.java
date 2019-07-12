import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.video.*; 
import gab.opencv.*; 
import java.awt.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Reconocimiento_visual extends PApplet {





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
int pixelcolor;

Capture cam;
OpenCV opencv;

int ancho = 1920;
int alto = 1080;
int factor = 2; // factor que reduce dimensiones >> aumenta velocidad de
                // muestreo

boolean saved = false;

int brightnessValue = 200;

int row = 0;
int column = 0;
boolean image = false;

public void settings() {
  size(ancho / factor, alto / factor); // Dimensiones de pantalla
}

public void setup() {

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

public void draw() {
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
    column = round(map(round(200 * noise(faces[i].x)), 0, 200, faces[i].x - 250,
                       faces[i].x + faces[i].width + 150));
    // column = faces[i].x;
    while (column < faces[i].x + faces[i].width) {
      // println("Sorting Column " + column);
      cam.loadPixels();
      sortColumn(faces, i);
      column++;
      cam.updatePixels();
    }
  }
  tint(255, 50);
  delay(200);
  image(cam, 0, 0, width, height);
  /*
  if (faces.length > 0){
          ellipse(faces[0].x + faces[0].width/2, faces[0].y + faces[0].height/2,
  faces[0].width, faces[0].height); //Dibujar marco eliptico rect(faces[0].x,
  faces[0].y, faces[0].width, faces[0].height); //Dibujar marco rectangular
  }*/
}

public void sortColumn(Rectangle[] faces, int z) {
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
    int noiseEnd = round(400 * noise(column));
    if (cam.height - noiseEnd > 0) {
      y = getFirstBrightY(x, y, cam.height - noiseEnd);
      yend = getNextDarkY(x, y, cam.height - noiseEnd);
    } else {
      y = getFirstBrightY(x, y, cam.height);
      yend = getNextDarkY(x, y, cam.height);
    }

    if (y < 0)
      break;

    int sortLength = yend - y;

    int[] unsorted = new int[sortLength];
    int[] sorted = new int[sortLength];

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
public int getFirstBrightY(int x, int y, int height) {
  if (y < height) {
    while (brightness(cam.pixels[x + y * cam.width]) > brightnessValue) {
      y++;
      if (y >= height)
        return -1;
    }
  }

  return y;
}

public int getNextDarkY(int x, int y, int height) {
  y++;
  if (y < height) {
    while (brightness(cam.pixels[x + y * cam.width]) < brightnessValue) {
      y++;
      if (y >= height)
        return height - 1;
    }
  }
  return y - 1;
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Reconocimiento_visual" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}

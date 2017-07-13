/*  OctoWS2811 movie2serial.pde - Transmit video data to 1 or more
 Teensy 3.0 boards running OctoWS2811 VideoDisplay.ino
 http://www.pjrc.com/teensy/td_libs_OctoWS2811.html
 Copyright (c) 2013 Paul Stoffregen, PJRC.COM, LLC
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

/*  This program combines the two scripts from
 https://github.com/i-make-robots/LEDWall/tree/master/Processing
 
 To configure this program, edit the following sections:
 1: change state to import a media file of your choice    ;-)
 Image: state == 1
 Video: state == 2
 ScreenCapture: state == 3
 
 2: edit the serialConfigure() lines in setup() for your
 serial device names (Mac, Linux) or COM ports (Windows)
 
 3: if your LED strips have unusual color configuration,
 edit colorWiring().  Nearly all strips have GRB wiring,
 so normally you can leave this as-is.
 
 4: if playing 50 or 60 Hz progressive video (or faster),
 edit framerate in movieEvent().
 */

import processing.video.*;
import processing.serial.*;
import java.awt.Rectangle;


import java.awt.Robot;
import java.awt.Rectangle;
import java.awt.AWTException;

Robot robot;

final int SCREEN_WIDTH = 64;
final int SCREEN_HEIGHT = 36;
final int LEDS_PER_STRIP = 64*6;
int TOTAL_LIGHTS=SCREEN_WIDTH*SCREEN_HEIGHT;


Serial ledSerial;
Rectangle ledArea;
boolean ledLayout;
PImage ledImage;
byte[] ledData;

PImage img;// = new PImage();
Movie movie;

int errorCount=0;
float framerate=0;
int isNoSerialDebug = 0; //0 is to debug, 1 is not
boolean isRainbow=false;

int state = 1; //1=image 2=video 3=capture

void setup() {
  //Initialize Serial. If error, stop.
  initSerial();
  if (errorCount > 0) exit();

  //update ledArea and ledImage
  initData(); 

  // create the window and size of captured area
  size(640, 360);  
  //If true, the first row runs from RIGHT to LEFT
  ledLayout = true;  

  //Import a media or create a screen capture object
  if (state==1) {//image
    img=loadImage("image4.jpg");
  } else if (state==2) {//video
    movie = new Movie(this, "video.mp4");
    movie.loop();
  } else if (state==3) {//capture
    try {
      robot = new Robot();
    }
    catch (AWTException e) {
      println(e);
    }
  }
  
}


void draw() {
  
  //Import the media and send to leds
  movieEvent();

  int xsize = percentageInverse(ledImage.width, ledArea.width); //64
  int ysize = percentageInverse(ledImage.height, ledArea.height);  //36
  // computer this image's position within it
  int xloc =  percentage(xsize, ledArea.x); //0
  int yloc =  percentage(ysize, ledArea.y); //0
  // show what should appear on the LEDs
  image(ledImage, 240 - xsize / 2 + xloc, 10 + yloc);
  image(ledImage, 400, 300, 320, 180);

}  

// runs for each new frame of movie data
void movieEvent() {
  
  if (state==2) {
    //Read a new frame of the movie
    movie.read();
    img=movie.get();
  } 
  else if (state==3) {
    //Capture the screen
    img = new PImage(robot.createScreenCapture(new Rectangle(0, 0, width, height)));
  }
  

  // copy a portion of the movie's image to the LED image
  int xoffset = percentage(img.width, ledArea.x);
  int yoffset = percentage(img.height, ledArea.y);
  int xwidth =  percentage(img.width, ledArea.width);
  int yheight = percentage(img.height, ledArea.height);
  ledImage.copy(img, xoffset, yoffset, xwidth, yheight, 
    0, 0, ledImage.width, ledImage.height);
    
  // convert the LED image to raw data
  image2data(ledImage, ledData, ledLayout);

  //Send the data
  if (isNoSerialDebug!=1) {
    ledSerial.write(ledData); 
    delay(20);
  }

}


// image2data converts an image to OctoWS2811's raw data format.
// The number of vertical pixels in the image must be a multiple
// of 8.  The data array must be the proper size for the image.
void image2data(PImage image, byte[] data, boolean layout) {
  int offset=0, x, y=0;
  int pixel;
  int size = image.height * image.width;

  int tempX=0;

  for (y = 0; y < size; y++) {
    pixel = image.pixels[y];

    int r = ( pixel & 0xFF0000 ) >> 16; //from 0m to 255
    int g = ( pixel & 0x00FF00 ) >>  8; 
    int b = ( pixel & 0x0000FF );

    if (isRainbow) {
      /// zone 1:  red
      if (tempX>=0 && tempX<12) {
        r=255;  
        g=0; 
        b=0;
      } else if (tempX>=12 && tempX<24) {
        r=0;  
        g=255; 
        b=0;
      } else if (tempX>=24 && tempX<36) {
        r=0;  
        g=0; 
        b=255;
      } else if (tempX>=36 && tempX<48) {
        r=255;  
        g=255; 
        b=255;
      } else if (tempX>=48) { //My favourite color ;)
        r=55;  
        g=155; 
        b=50;
      }
      tempX++;
      if (tempX==64)
        tempX=0;
    }

    //because if rgb=0 it is the signal to update
    if ( r==0 ) r=1;
    if ( g==0 ) g=1;
    if ( b==0 ) b=1;

    //image.pixels[y] =  ((r << 16) | (g << 8) | b);
    data[led_map(y*3)] = (byte)(r);
    data[led_map(y*3+1)] = (byte)(g);
    data[led_map(y*3+2)] = (byte)(b);
  }

}

//Change the index to match the wiring
int led_map(int i){
  
  int x = i%SCREEN_WIDTH;
  int y = i/SCREEN_WIDTH;
  return XY(x,y);
  
}


int XY( int x, int y)
{
  int i = 0;
  if( ledLayout == false) {
    i = (y * SCREEN_WIDTH) + x;
  }
  else if( ledLayout == true) {
    if( y %2==0) {
      // Even rows run backwards
      int reverseX = (SCREEN_WIDTH - 1) - x;
      i = (y * SCREEN_WIDTH) + reverseX;
    } else {
      // Odd rows run forwards
      i = (y * SCREEN_WIDTH) + x;
    }
  }

  return i;
}
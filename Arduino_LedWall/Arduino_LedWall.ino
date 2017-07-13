/*  OctoWS2811 VideoDisplay.ino - Video on LEDs, from a PC, Mac, Raspberry Pi
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
 
  Required Connections
  --------------------
    pin 2:  LED Strip #1    OctoWS2811 drives 8 LED Strips.
    pin 14: LED strip #2    All 8 are the same length.
    pin 7:  LED strip #3
    pin 8:  LED strip #4    A 100 to 220 ohm resistor should used
    pin 6:  LED strip #5    between each Teensy pin and the
    pin 20: LED strip #6    wire to the LED strip, to minimize
    pin 21: LED strip #7    high frequency ringining & noise.
    pin 5:  LED strip #8
    pin 15 & 16 - Connect together, but do not use
    pin 4:  Do not use
    pin 3:  Do not use as PWM.  Normal use is ok.
    pin 12: Frame Sync
    When using more than 1 Teensy to display a video image, connect
    the Frame Sync signal between every board.  All boards will
    synchronize their WS2811 update using this signal.
    Beware of image distortion from long LED strip lengths.  During
    the WS2811 update, the LEDs update in sequence, not all at the
    same instant!  The first pixel updates after 30 microseconds,
    the second pixel after 60 us, and so on.  A strip of 120 LEDs
    updates in 3.6 ms, which is 10.8% of a 30 Hz video frame time.
    Doubling the strip length to 240 LEDs increases the lag to 21.6%
    of a video frame.  For best results, use shorter length strips.
    Multiple boards linked by the frame sync signal provides superior
    video timing accuracy.
    A Multi-TT USB hub should be used if 2 or more Teensy boards
    are connected.  The Multi-TT feature allows proper USB bandwidth
    allocation.  Single-TT hubs, or direct connection to multiple
    ports on the same motherboard, may give poor performance.
*/

#include "FastLED.h"

const int kMatrixWidth = 64;
const int kMatrixHeight = 36;

// Adjust these variables to match the wiring
#define NUM_STRIPS 6
#define NUM_LEDS_PER_STRIP kMatrixWidth*6
#define NUM_LEDS NUM_LEDS_PER_STRIP * NUM_STRIPS
CRGB leds[NUM_LEDS];
int ledPins[] = { 2,5,7,8,6,20 };  //Define the 6 OUTPUT pins

// Param for different pixel layouts: true = the first row runs backward
// When the board receives serial signal, the layout doesn't matter because Processing has taken care of it.
const bool kMatrixLayout = true;
bool isTest = false; //If true, draw the rainbow instead of reading serial

int pixeli=0;

void setup() {
  
  Serial.begin(115200);
  
  for(int i=0;i<6;i++){
    pinMode(i,OUTPUT);
  }
  //Tell FastLED there's 64*6 WS2812B leds on pin 2, starting at index 0 in the led array
  FastLED.addLeds<WS2812B, 2,GRB>(leds, 0 * NUM_LEDS_PER_STRIP, NUM_LEDS_PER_STRIP);
  FastLED.addLeds<WS2812B, 5,GRB>(leds, 1 * NUM_LEDS_PER_STRIP, NUM_LEDS_PER_STRIP);
  FastLED.addLeds<WS2812B, 7,GRB>(leds, 2 * NUM_LEDS_PER_STRIP, NUM_LEDS_PER_STRIP);
  FastLED.addLeds<WS2812B, 8,GRB>(leds, 3 * NUM_LEDS_PER_STRIP, NUM_LEDS_PER_STRIP);
  FastLED.addLeds<WS2812B, 6,GRB>(leds, 4 * NUM_LEDS_PER_STRIP, NUM_LEDS_PER_STRIP);
  FastLED.addLeds<WS2812B, 20,GRB>(leds, 5 * NUM_LEDS_PER_STRIP, NUM_LEDS_PER_STRIP);

  //Test the leds
  DrawRainbow();
  delay(100);
  
  Serial.setTimeout(50);
  
}

void loop() {
  
  //Test Mode
  while(isTest) DrawRainbow();
  
  //Read from Serial
  int r,g,b;
  while(Serial.available() <= 0){
    for(int i=0;i<6;i++) digitalWrite(ledPins[i],LOW);
    pixeli=0;
  }
  
  r = Serial.read();
  g = Serial.read();
  b = Serial.read();
  
  if( r==0 && g==0 && b==0 ) {
    //Show the frame
    pixeli=0;
    FastLED.show();
  }
  else if( pixeli < NUM_LEDS ) {
    //Fill this frame
    leds[pixeli] = CRGB(r,g,b);
    pixeli++;
  }
  
}


int led_map(int i){
  int x = i%kMatrixWidth;
  int y = i/kMatrixWidth;
  return XY(x,y);
}


int XY( int x, int y)
{
  int i;
  if( kMatrixLayout == false) {
    i = (y * kMatrixWidth) + x;
  }

  if( kMatrixLayout == true) {
    if( y %2 == 0) {
      // Even-indexed rows run backwards
      int reverseX = (kMatrixWidth - 1) - x;
      i = (y * kMatrixWidth) + reverseX;
    } else {
      // Odd rows run forwards
      i = (y * kMatrixWidth) + x;
    }
  }

  return i;
}

void DrawRainbow(){
  int32_t ms = millis();
  int32_t yHueDelta32 = ((int32_t)cos16( ms * (27/1) ) * (350 / kMatrixWidth));
  int32_t xHueDelta32 = ((int32_t)cos16( ms * (39/1) ) * (310 / kMatrixHeight));
  DrawOneFrame( ms / 65536, yHueDelta32 / 32768, xHueDelta32 / 32768);
  FastLed.show();
}

void DrawOneFrame( byte startHue8, int8_t yHueDelta8, int8_t xHueDelta8)
{
  byte lineStartHue = startHue8;
  for( byte y = 0; y < kMatrixHeight; y++) {
    lineStartHue += yHueDelta8;
    byte pixelHue = lineStartHue;
    for( byte x = 0; x < kMatrixWidth; x++) {
      pixelHue += xHueDelta8;
      leds[ XY(x, y)]  = CHSV( pixelHue, 255, 255);
    }
  }
}


# LedWall
A LedWall made of 64*36 leds that can display movie and screen.


# Hardware
The most suitable board is Teensy with version later than 3.0.
The result of tests on Arduino is not satisfying. 
Arduino Mega 2560 delays almost 1 second when reading serial data, 
and Arduino Uno simply doesn't support such amount of data storage
(like an array of the size of 3 times the total led numbers).
However, Arduino Mega 2560 works if not for serial reading.

It utilizes WS2812B Leds or any type of led that the FastLED library support.


# Reference
This script is modified version of https://github.com/i-make-robots/LEDWall


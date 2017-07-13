//######  Serial Init ####################

// Init serial port
void initSerial() {
  
  String[] list = Serial.list();
  delay(20);
  println("Serial Ports List:");
  printArray(list);

  if (isNoSerialDebug!=1) {
    try {
      //Try connecting the last serial port, which is usually the board
      ledSerial= new Serial(this, list[list.length-1], 115200);
      if (ledSerial == null) throw new NullPointerException();
      ledSerial.write('?');
    } 
    catch (Throwable e) {
      println("Serial port " + list[list.length-1] + " does not exist or is non-functional");
      errorCount++;
      return;
    }
  }
  
}

void initData() {
  
  initPortData();

  int size=TOTAL_LIGHTS*3;
  ledData =  new byte[size+3];
  //Define ledData's last three bytes to be 0
  //The last 3 bytes command the led wall to show
  ledData[size+0]=0;
  ledData[size+1]=0;
  ledData[size+2]=0;
  
}

void initPortData() {
  
  String line = "64,36,0,0,0,0,0,100,100,0,0,0";
  String param[] = line.split(",");

  //ledimage is of the size of the screen which is 640*360
  ledImage = new PImage(SCREEN_WIDTH, SCREEN_HEIGHT, RGB);
  //Define the Area as the full screen
  ledArea = new Rectangle(Integer.parseInt(param[5]), Integer.parseInt(param[6]), 
    Integer.parseInt(param[7]), Integer.parseInt(param[8]));
  
  
}


void printDebug(String s) {
  println("Reayun DEBUG: ", s);
}
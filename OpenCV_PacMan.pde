/*
  This code is free software: you can redistribute it and/or modify 
  it under the terms of the GNU General Public License as published 
  by the Free Software Foundation, either version 3 of the License, 
  or (at your option) any later version.
  This code is distributed in the hope that it will be useful, but 
  WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
  General Public License for more details.
  You should have received a copy of the GNU General Public License
  along with this code. If not, see <http://www.gnu.org/licenses/>.
*/

/* Code logic in short:
  The code reads the webcam image
  Detects contours
  Filter contours based on size
  Checks whether contour is new or a movement of an existing contour based on a threshold
  Reoccuring contours are saved as blobs
  The first blob is assigned as being pacman, you can also click on another blob to switch pacman
  A matrix of dots is drawn
  In case pacman is near a dot, it gets destroy and score + 1
*/

/* Load libraries */
import gab.opencv.*;              // Load library https://github.com/atduskgreg/opencv-processing
import processing.video.*;        // Load video camera library 

/* Declare variables */
Capture video;                    // Camera stream
OpenCV opencv;                    // OpenCV
PImage now, diff;                 // PImage variables to store the current image and the difference between two images 

PGraphics drawing;                // PGraphics buffer

ArrayList<Contour> contours;      // ArrayList to hold all detected contours
ArrayList<Blob> blobs = new ArrayList <Blob>(); // ArrayList to hold all blobs

int score;                        //  Count total number of dots eaten
ArrayList dots;                   //  ArrayList to hold the dots objects
PFont font;                       //  A new font object
PImage dotPNG;                    //  PImage that holds the Dot image
PImage pacManPNG;                 //  PImage that holds the PacMan image
int pacManBlobID = 0;             //  Initial blob that holds PacMan image 

int ContourThreshold = 20;        //  Contour detection sensitivity of the script
int SizeThreshold = 100;          //  Contour size threshold
int MovementMargin = 40;          //  Max difference in coordinates
int segmentSize = 10;
int segmentThreshold = segmentSize * segmentSize / 3;

/* Slider Bar */
HScrollbar hs1, hs2;

/* Define a Blob class */
class Blob {
  ArrayList<Integer> blobX = new ArrayList<Integer>();  //  X coordinates
  ArrayList<Integer> blobY = new ArrayList<Integer>();  //  Y coordinates
  ArrayList<Integer> blobS = new ArrayList<Integer>();  //  # of sections
  ArrayList<Integer> blobA = new ArrayList<Integer>();  //  Area in pixels
  boolean isPacMan = false;                             //  Pacman flag
  
  Blob (int bX, int bY, int bS, int bA, boolean selected) // Constructor
  {
      blobX.add(bX);
      blobY.add(bY);
      blobS.add(bS);
      blobA.add(bA);
      isPacMan = selected;
  }
  
  void addXYSA(int X, int Y, int S, int A) // add coordinates
  {
      blobX.add(X);
      blobY.add(Y);
      blobS.add(S);
      blobA.add(A);
  }
  
  void togglePacMan() {
    if(isPacMan) { 
      isPacMan = false;
    } else {
      isPacMan = true;
    }
  }
}

/* Define a Dot class */
class Dot {
  int dotX, dotY, dotWidth, dotHeight;    //  Variables to hold the dot's coordinates and width/height
 
  Dot ( int dX, int dY, int dW, int dH )  //  Class constructor- sets all the values when a new dot object is created
  {
    dotX = dX;
    dotY = dY;
    dotWidth = dW;
    dotHeight = dH;
  }
 
  int update()              //  The Dot update function
  {
    boolean hit = false;    //  Flag whether PacMan has hit this dot
    for(int i = 0; i < blobs.size(); i++) {  //  Loop through all blobs
      Blob _blob = (Blob) blobs.get(i);      //  Copy temp blob
      if(_blob.isPacMan) {                   //  Check whether blob is PacMan
        if(dotX > _blob.blobX.get(_blob.blobX.size()-1)-20 && dotX < _blob.blobX.get(_blob.blobX.size()-1)+20) {    //  Check whether dot is in range of PacMan
          if(dotY > _blob.blobY.get(_blob.blobY.size()-1)-20 && dotY < _blob.blobY.get(_blob.blobY.size()-1)+20) {  //  Check whether dot is in range of PacMan
            hit = true;  // In case PacMan is in range, flag that dot has been eaten
          }
        }
      }
    }
    if(hit) {     //  In case dot has been eaten
      score++;    //  Score goes 1 up
      return 1;   //  Return 1 so dot gets destroyed
    } else {
      image(dotPNG, dotX, dotY);  // Draw dot on screen
      return 0;   //  Return 0 so dot is saved
    }
  }
}

/* Setup function */
void setup() {
  size(640, 960);                         //  Create canvas window
  video = new Capture(this, 640, 480);    //  Define video size
  opencv = new OpenCV(this, 640, 480);    //  Define opencv size

  video.start();                          //  Start capturing video        

  score = 0;                              //  Set score to 0
  dots = new ArrayList();                 //  Initialises the ArrayList
 
  dotPNG = loadImage("dot.png");          //  Load the dot image into memory
  pacManPNG = loadImage("pacman.png");    //  Load the pacman image into memory
  font = loadFont("Serif-48.vlw");        //  Load the font file into memory
  textFont(font, 12);                     //  Set font size
  strokeWeight(3);                        //  Set stroke size
  
  noStroke();
  hs1 = new HScrollbar(0, height/2-8, width, 16, 16);
  hs2 = new HScrollbar(0, height/2+8, width, 16, 16);
  
  // Add dots to the dots ArrayList
  for(int i = 1; i < 15; i++) { 
    for(int j = 1; j < 12; j++) {
      dots.add(new Dot( 40*i, 40*j, dotPNG.width, dotPNG.height));
    }
  }
}

/* Draw function */
void draw() { 
  
  // start buffer
  drawing = createGraphics(640, 480);
  drawing.beginDraw();
  drawing.noStroke();
  int[] segments = new int[int(width/segmentSize)*int((height/2)/segmentSize)];  //  Set number segments
  
  opencv.loadImage(video);   //  Capture video from camera in OpenCV
  
  image(video, 0, 0);        //  Draw camera image to screen 
  
  opencv.gray();             //  Convert into gray scale
  //opencv.contrast(2);        //  Increase contrast
  opencv.invert();           //  Invert b/w
  //opencv.blur(3);            //  Reduce camera noise
  opencv.threshold(ContourThreshold);  //  Convert to Black and White
  //opencv.flip(OpenCV.VERTICAL); // Flip image vertical
  
  now = opencv.getOutput();   //  Store image in PImage
  image(now, 0, 480);         //  Show video

  // Analyze image
  int segmentCounter = 0;
  for( int x = 1; x < width; x = x + segmentSize) {
    for ( int y = 1; y < (height/2); y = y + segmentSize) {
      
      int segmentBrightness = 0;
      for ( int i = 0; i < segmentSize; i++) {
        for ( int j = 0; j < segmentSize; j++) {
          if (brightness(now.pixels[x+i+(y*width)+j]) > 127) {
            segmentBrightness++;
          }
        }
      }
      if(segmentBrightness > segmentThreshold) { //  segment is bright
        segments[segmentCounter] = 1;
        drawing.fill(255,255,255);
        drawing.rect(x-1,y-1,12,12);
      }
      segmentCounter++;
    }  
  }

  drawing.endDraw();
  
  // Draw all dots
  for( int i = 0; i < dots.size(); i++) {   //  Loop through all dots
    Dot _dot = (Dot) dots.get(i);           //  Temp copy
    
    // Check whether dot is eaten by PacMan
    if(_dot.update() == 1){                 //  If the dot's update function returns '1'
      dots.remove(i);                       //  then remove the dot from the array
      _dot = null;                          //  and make the temporary dot object null
      i--;                                  //  since we've removed a dot from the array, we need to subtract 1 from i, or we'll skip the next dot
    }else{                                  //  If the dot's update function doesn't return '1'
      dots.set(i, _dot);                    //  Copies the updated temporary dot object back into the array
      _dot = null;                          //  Makes the temporary dot object null.
    }
  }
  
  // Draw the offscreen buffer to the screen with image() 
  image(drawing, 0, 0);
  
  opencv.loadImage(drawing);
  
  // Analyze video
  contours = opencv.findContours();         //  Find contours
  
  int evalc = 0;                            //  Count number of evaluated contours
  for (Contour contour : contours) {        //  Loop through all contours
    int sumx = 0;        //  Sum of all x coordinates
    int sections = 0;    //  # of sections
    int sumy = 0;        //  Sum of all y coordinates
    int area = 0;        //  Area of polygon
    
    ArrayList<Integer> Xcoors = new ArrayList<Integer>();  // List of all X coordinates
    ArrayList<Integer> Ycoors = new ArrayList<Integer>();  // List of all Y coordinates
    
    for (PVector point : contour.getPolygonApproximation().getPoints()) {  // Loop through all vertex X Y coordinates of polygon
      sumx = sumx + int(point.x);  //  Sum up all X coordinates, needed for calculating the middle
      sumy = sumy + int(point.y);  //  Sum up all Y coordinates, needed for calculating the middle
      Xcoors.add(int(point.x));    //  Store all X coordinates, needed for calculating the area
      Ycoors.add(int(point.y));    //  Store all Y coordinates, needed for calculating the area
      sections++;                  //  Count the number of sections
    }
    
    // Calculate the area of the polygon
    int j = 0;
    for (int i = 0; i < sections; i++) {
      area = area + (Xcoors.get(j)+Xcoors.get(i)) * (Ycoors.get(j)-Ycoors.get(i));
      j = i;
    }
    area = area / 2;
    
    if(area > SizeThreshold && area < 100000) {  // Check whether area is above threshold and not as big as the video itself
      evalc++;            //  Up 1 for the evaluated contours counter
      noFill();           //  Disable filled shapes
      stroke(0, 255, 0);  //  Set stroke color to green
      contour.draw();     //  Draw the contour
      //fill(255, 0, 0);    //  Set color to red
      //text((sumx/sections) + ", " + (sumy/sections), (sumx/sections), (sumy/sections)); // Print the coordinates on screen
    
      if(blobs.size() > 0) {  //  Check whether this is the first blob or not
        boolean withinmargin = false;    //  Flag whether it is close to a previous blob
        int withinmarginID = 0;          //  Remember which one that was
        
        for( int i = 0; i < blobs.size(); i++) { //  Loop through all blobs
          Blob _blob = (Blob) blobs.get(i);      //  Make a temp copy
          int lastX = _blob.blobX.get(_blob.blobX.size()-1); //  most recent X coordinate
          int lastY = _blob.blobY.get(_blob.blobY.size()-1); //  most recent Y coordinate
          
          // Check whether the contour is within movement margin, otherwise it's a new blob
          if(lastX < (sumx/sections + MovementMargin)){
            if(lastX > (sumx/sections - MovementMargin)) {
              if(lastY < (sumy/sections + MovementMargin)) {
                if(lastY > (sumy/sections - MovementMargin)) {
                    withinmargin = true;
                    withinmarginID = i;
                    //println("hit X old: " + lastX + "; new:" + sumx/c + "; Y old: " + lastY + "; Y new: " +sumy/c);
                 
                }
              }
            }
          }
          
          _blob = null; // Reset temp copy
        }
        
        if(withinmargin) {                                               //  Within margin? True: add coordinates to ArrayList
          Blob _blob = (Blob) blobs.get(withinmarginID);                 //  Make temp copy of blob
          _blob.addXYSA(sumx/sections, sumy/sections, sections, area);   //  Add the information to the ArrayLists of the blob object
          blobs.set(withinmarginID, _blob);                              //  Store the blob
        } else {                                                         //  else: it's a new blob
          blobs.add(new Blob(sumx/sections, sumy/sections, sections, area, false));  // Add new blob to the blobs ArrayList
        }
      } else { // Add first blob, which becomes PacMan
        blobs.add(new Blob(sumx/sections, sumy/sections, sections, area, true));  // Store blob and flag as PacMan
      }
    }
  }
  
  // Print some useful monitoring info to the console
  println("Found " + contours.size() + " Contours; area > "+SizeThreshold+" px " + evalc + "; Total "+ blobs.size() + " blobs");

  // Draw PacMan
  for( int i = 0; i < blobs.size(); i++) { //  Loop through all blobs
    Blob _blob = (Blob) blobs.get(i);      //  Make a temp copy
    if(_blob.isPacMan) {                   //  In case it is flagged as PacMan
      image(pacManPNG, _blob.blobX.get(_blob.blobX.size()-1)-10, _blob.blobY.get(_blob.blobY.size()-1)-10);  // Draw PacMan image
    }
    _blob = null;  // Reset temp copy
  }

  // Print the score
  fill(0,255,0);  // Set color to green
  textSize(20); // Increase text size
  text("Score: " + score, 20, 20);   // Display score
  
  ContourThreshold = int(hs1.getPos()); // get scrollbar position
  fill(0,255,0);  // Set color to green
  textSize(20); // Increase text size
  text("CountourThreshold: " + ContourThreshold, 20, 40);
  
  SizeThreshold = int(hs2.getPos());
  text("SizeThreshold: " + SizeThreshold * 10, 30, 60);
  
  hs1.update();
  hs2.update();
  hs1.display();
  hs2.display();
  
  // Wait a little before the next round to save processing power and memory
  delay(20);
}

/* Capture function */
void captureEvent(Capture c) {
  c.read();
}

/* MouseClick function to select a new blob to become PacMan */
void mouseClicked() {
  for( int i = 0; i < blobs.size(); i++) { //  Loop through all blobs
    Blob _blob = (Blob) blobs.get(i);      //  Make a temp copy
    if(mouseX > _blob.blobX.get(_blob.blobX.size()-1)-10 && mouseX < _blob.blobX.get(_blob.blobX.size()-1)+10) { //  Check whether X coordinates are within range
      if(mouseY > _blob.blobY.get(_blob.blobY.size()-1)-10 && mouseY < _blob.blobY.get(_blob.blobY.size()-1)+10) { //  Check whether Y coordinates are within range
        // Found hit
        _blob.togglePacMan(); // Toggle PacMan flag
        blobs.set(i, _blob);  // Save it
        _blob = (Blob) blobs.get(pacManBlobID); // Get previous PacMan blob
        _blob.togglePacMan(); // Toggle PacMan flag
        blobs.set(pacManBlobID, _blob); // Save it
        pacManBlobID = i;     // Set new PacMan ID
      }
    }
    _blob = null; //  Reset
  }
}

/* Scrollbar class */
class HScrollbar {
  int swidth, sheight;    // width and height of bar
  float xpos, ypos;       // x and y position of bar
  float spos, newspos;    // x position of slider
  float sposMin, sposMax; // max and min values of slider
  int loose;              // how loose/heavy
  boolean over;           // is the mouse over the slider?
  boolean locked;
  float ratio;

  HScrollbar (float xp, float yp, int sw, int sh, int l) {
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    ratio = (float)sw / (float)widthtoheight;
    xpos = xp;
    ypos = yp-sheight/2;
    spos = xpos + swidth/2 - sheight/2;
    newspos = spos;
    sposMin = xpos;
    sposMax = xpos + swidth - sheight;
    loose = l;
  }

  void update() {
    if (overEvent()) {
      over = true;
    } else {
      over = false;
    }
    if (mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      newspos = constrain(mouseX-sheight/2, sposMin, sposMax);
    }
    if (abs(newspos - spos) > 1) {
      spos = spos + (newspos-spos)/loose;
    }
  }

  float constrain(float val, float minv, float maxv) {
    return min(max(val, minv), maxv);
  }

  boolean overEvent() {
    if (mouseX > xpos && mouseX < xpos+swidth &&
       mouseY > ypos && mouseY < ypos+sheight) {
      return true;
    } else {
      return false;
    }
  }

  void display() {
    noStroke();
    fill(204);
    rect(xpos, ypos, swidth, sheight);
    if (over || locked) {
      fill(0, 0, 0);
    } else {
      fill(102, 102, 102);
    }
    rect(spos, ypos, sheight, sheight);
  }

  float getPos() {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return spos * ratio;
  }
}

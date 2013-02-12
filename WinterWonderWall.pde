// See README.md for more information about this sketch

import java.awt.Frame;
import java.awt.BorderLayout;
import java.util.*;
import java.util.concurrent.*;

import controlP5.*;
import processing.video.*;

// In demo mode, the carpet on the wall is shown
boolean demoMode = true;

// Show second window with on-screen controllers
boolean enableControllerWindow = true;

// Enable midi controller
boolean enableMidi = false;
int midiInPort = 2;
int midiOutPort = 5;

// Width and height in Normal mode. In Present mode, height is set to displayHeight and width
// is scaled according to designWidth : designHeight as given below
int normalModeWidth = 800;
int normalModeHeight = 600;

// masks and images will be scaled to actual width / height
int designWidth = 1400;
int designHeight = 1050;

// Midi controllers:
// BCF2000, preset 10
final static int CONTROL_SNOW          = 81; // amount of new snowflakes
final static int CONTROL_STORM         = 82; // amount of stormyness + double speed + more new snowflakes
final static int CONTROL_PEOPLE        = 83; // fade people in from the middle. NB slows framerate.
final static int CONTROL_ADD_AMOUNT    = 84;
final static int CONTROL_BLEND_MODE    = 85;
final static int CONTROL_WHITE_OVERLAY         = 86;
final static int CONTROL_WHITE_BACKGROUND    = 87; // aid to see when drawing masks
final static int CONTROL_BLACK = 88;

final static int NOTE_BETLEHEM     = 61;
final static int NOTE_SHEPHERDS    = 62;
final static int NOTE_KINGS        = 63;
final static int NOTE_FAMILY       = 64;
final static int NOTE_PEOPLE       = 65;
//final static int NOTE_PEOPLE_RIGHT = 66;
final static int NOTE_INVISIBLE_SNOW = 67;
final static int NOTE_CLEAR_SKYLINE= 68; // and drop snow

final static int NOTE_MOVIE_START_PAUSE = 71;
final static int NOTE_MOVIE_STOP = 72;

// MPKMini
/*
final static int CONTROL_WHITE_OVERLAY = 53;
final static int CONTROL_SNOW = 54; // amount
final static int CONTROL_STORM = 55; // amount of stormyness + double speed
final static int CONTROL_WHITE_BACKGROUND = 59; // aid to see when drawing masks
final static int CONTROL_BLACK = 60;
*/

ControlWindow controls;
boolean internalControlUpdate = false;
boolean initDone = false;

HashMap<String, String> commandLine = new HashMap<String, String>();

int sketchWidth; // width of sketch
int width; // width of layer where all is drawn, layer is centered in sketch 
int height; // height of layer where all is drawm, layer is centered in sketch
float scaleFactor; // width : designWidth;

ParticleSystem particleSystem;

PImage sprite;
PImage sprite2;
PImage white1x1;
PImage white3x3;
PImage white5x5;

PGraphics skyline;

PImage betlehem;
PImage shepherds;
PImage kings;
PImage family;
PImage peopleLeft;
PImage peopleRight;

ImageWipe peopleLeftWipe;
ImageWipe peopleRightWipe;

PImage wall;

Movie movie;
boolean moviePlaying = false;
boolean moviePaused = false;
boolean movieFrameReady = true;
float movieWidth;
float movieHeight;

PGraphics layer;
PGraphics blackOverlay;

PolygonMask wallMask;
PolygonMask whiteOverlayMask;

String wallMaskFilename = "data/WallMask.txt";
String whiteOverlayMaskFilename = "data/WhiteOverlayMask.txt";

boolean enableBethlehem = false;
boolean enableShepherds = false;
boolean enableKings = false;
boolean enableStable = false;

MidiBus midi;
Queue<MidiMessage> messages; // to handle concurrency

float[]   midiValues = new float[128];  // control change
boolean[] midiState = new boolean[128]; // note on/off state

float lastTime = 0;
float lastFlakeTime = 0;  

boolean debugFlag = false;

boolean presentMode = false;

void init()
{
  parseCommandLine();

  if (frame.isUndecorated())
    presentMode = true;

  super.init();
}

void setup()
{  
  if (presentMode)
  {
    height = displayHeight;
    sketchWidth = displayWidth;
    width = (int)getWidthFromHeight(designWidth, designHeight, height);
//    width = designWidth;
//    height = designHeight;
  }
  else
  {
    height = normalModeHeight;
    sketchWidth = normalModeWidth;
    width = (int)getWidthFromHeight(designWidth, designHeight, height);
  }
  
  println("Sketch size: " + sketchWidth + " x " + height + 
          ". Layer size: " + width + ", "+ height + 
          ". " + (presentMode ? "Present mode" : "Normal mode"));
  
  scaleFactor = (float)width / (float)designWidth;
  
  println("Design size: " + designWidth + " x " + designHeight + ". Scale factor: " + scaleFactor);
  
  frame.setBackground(new java.awt.Color(0, 0, 0)); // startup color for present mode
  size(sketchWidth, height, P2D);

  parseCommandLine();
  demoMode = getCommandLineFlag("DemoMode", demoMode);
  enableControllerWindow = getCommandLineFlag("ControllerWindow", enableControllerWindow);
  enableMidi = getCommandLineFlag("Midi", enableMidi);
  midiInPort = getCommandLineInt("MidiInPort", midiInPort);
  midiOutPort = getCommandLineInt("MidiOutPort", midiOutPort);
  
  messages = new ConcurrentLinkedQueue<MidiMessage>();

  MidiBus.list();
  // Open Midi input device
  // midi = new MidiBus(this, "MPK mini", -1);
  //midi = new MidiBus(this, 0, 0);
  if (enableMidi)
    midi = new MidiBus(this, midiInPort, midiOutPort);

  for (int i=0; i<128; i++)
  {
    midiValues[i] = 0;
    midiState[i] = false;
  }
 
  if (demoMode)
  {
    wallMaskFilename = "data/WallMaskDemo.txt";
    whiteOverlayMaskFilename = "data/WhiteOverlayMaskDemo.txt";
  }
  
  wallMask = new PolygonMask(wallMaskFilename, width, height, 20, true, 'p', scaleFactor, 0.0, 0.0);
  whiteOverlayMask = new PolygonMask(whiteOverlayMaskFilename, width, height, 5, false, 'l', scaleFactor, 0.0, 0.0);
  
  sprite = loadImage("flake10-10.png");
  sprite2 = loadImage("flake10-25.png");
  white1x1 = loadImage("white-1x1.png");
  white3x3 = loadImage("white-3x3.png");
  white5x5 = loadImage("white-5x5.png");
  
  blackOverlay = createGraphics(width, height);
  blackOverlay.beginDraw();
  blackOverlay.background(0);
  blackOverlay.endDraw();

  betlehem = loadImage("betlehem-skyline-w1400-t.png");
  shepherds = loadImage("shepherds-h1050-t.png");
  kings = loadImage("kings-h1050-t.png");
  peopleLeft = loadImage("people-left-w1400-t.png");
  peopleRight = loadImage("people-right-w1400-t.png");
  family = loadImage("family-h1050-t.png");
    
  peopleLeftWipe = new ImageWipe(peopleLeft, ORIGIN_LEFT);
  peopleRightWipe = new ImageWipe(peopleRight, ORIGIN_RIGHT);
  
  //wall = loadImage("church-wall.png");
  wall = loadImage("church-wall-just-cross.png");
  skyline = createGraphics(width, height);
  
  layer = createGraphics(width, height, P2D);
  particleSystem = new ParticleSystem(layer, sprite);
  particleSystem.frameMin = new PVector(-50, -10);
  particleSystem.frameMax = new PVector(width + 50, height);
  particleSystem.setSkyline(skyline, new PVector(0, 0));
  
  movie = new Movie(this, "mitt-hjerte-animasjon-2-57-slim.m4v");
  movieFrameReady = false;
  movie.speed(16);
  movie.play(); // buffer to avoid gap when starting playback
  movie.pause();
  movieHeight = height;
  movieWidth = getWidthFromHeight(movie.width, movie.height, movieHeight);

  zeroMidi();

  if (enableControllerWindow)
  {
    setupControlWindow();  
    controls.setupFrame();
  }

  background(0);
  frameRate(60);
  
 
  println("Setup done");
}


void draw()
{
  if (!initDone)
  {
    initDone = true;
    println("Sketch is running.");
  }

  handleMidiMessages();
  
  float time = getTime();
  float dt = getDeltaTime(time);  
  
  layer.beginDraw();
  float backgroundGrey = midiValues[CONTROL_WHITE_BACKGROUND];
  layer.background(backgroundGrey);
   
  layer.tint(255);
  layer.imageMode(CENTER);
  
  if ( (moviePlaying || moviePaused) && movieFrameReady)
  {
    layer.image(movie, width / 2, height / 2, movieWidth, movieHeight);
  }

  layer.imageMode(CORNER);

  if (midiValues[CONTROL_PEOPLE] > 8)
  {
    peopleLeftWipe.wipeImage(255-midiValues[CONTROL_PEOPLE]);
    peopleRightWipe.wipeImage(255-midiValues[CONTROL_PEOPLE]);

    float h; 
    float w;
    w = 2.0 * width / 5.0;
    h = getHeightFromWidth(peopleRight.width, peopleRight.height, w);
    layer.image(peopleRightWipe.getImage(), width-w - width/30.0, 2.0 * height / 3.0 - h/2, w, h);

    w = 2.0 * width / 5.0;
    h = getHeightFromWidth(peopleLeft.width, peopleLeft.height, w);
    layer.image(peopleLeftWipe.getImage(), width/30.0, 2.0 * height / 3.0 - h/2, w, h);
    
  }
  
  // image(skyline, width / 2 - skyline.width/2, height / 2 - skyline.height/2);
  particleSystem.invisibleSnow = midiState[NOTE_INVISIBLE_SNOW];
  particleSystem.stormyness = (int)midiValues[CONTROL_STORM];
  particleSystem.update();
  particleSystem.draw();
  if (round(time) % 5 == 0) 
  {
    if (debugFlag == false)
    {
      println("Number of particles: " + particleSystem.numParticles());
      
      // The amount of memory allocated so far (usually the -Xms setting)
      long allocated = Runtime.getRuntime().totalMemory() / (1024 * 1024);
      // Free memory out of the amount allocated (value above minus used)
      long free = Runtime.getRuntime().freeMemory() / (1024 * 1024);
      // The maximum amount of memory that can eventually be consumed
      // by this application. This is the value set by the Preferences
      // dialog box to increase the memory settings for an application.
      long maximum = Runtime.getRuntime().maxMemory() / (1024 * 1024);
      
      println("Memory free (MB): " + free + ", allocated: " + allocated + " = max: " + maximum);
      
      debugFlag = true;
    }
  }
  else
  {
    debugFlag = false;
  }
    
  float flakesPerSecond = midiValues[CONTROL_SNOW] / 3 * (1 + 
    ( (midiValues[CONTROL_STORM] < 100) ? 0 : 3.0*midiValues[CONTROL_STORM]/255.0) ); 

  //flakesPerSecond = mouseY ;
  particleSystem.stormyness = mouseX / 2;
  
  if (lastFlakeTime == 0)
    lastFlakeTime = time;
  if (flakesPerSecond < 0.1)
    lastFlakeTime = time; // or else it could be an avalanche when it starts snowing after a while
  
  float initialVelocityScale = 1.0 + 2.0*midiValues[CONTROL_STORM]/255.0; // snow 3x fast when storming 
  
  float dft = time - lastFlakeTime;
  int newFlakes = (int)floor(flakesPerSecond * dft);

  if (newFlakes > 0) 
  {
    lastFlakeTime = time;
    for (int i=0; i< newFlakes; i++)
    {
      Particle p = new Particle(layer, sprite);
      p.position = new PVector(random(0, width), -1, random (-1, 1));
      p.setVelocity(new PVector(random(-4, 4), random(20, initialVelocityScale*60)));
      p.image = getImage();
  
      particleSystem.addParticle(p);
    }
  }
    
  layer.imageMode(CORNER);

  layer.image(wallMask.mask, 0, 0);

  float tintScale = 1.0;
  
  if (demoMode)
    tintScale = 0.6;
  
  layer.tint(255, midiValues[CONTROL_WHITE_OVERLAY] * tintScale);
  layer.image(whiteOverlayMask.mask, 0, 0);
  layer.tint(255, 255);

  if (midiValues[CONTROL_BLACK] > 4)
  {
    layer.tint(255, midiValues[CONTROL_BLACK]);
    layer.image(blackOverlay, 0, 0);
    layer.tint (255, 255);
  }

  layer.endDraw();

  if (demoMode)
  {
    // draw background image
    blendMode(BLEND);
    imageMode(CENTER);
    tint(255);
    image(wall, sketchWidth / 2, height / 2, width, height);
    blendMode(MULTIPLY);
  }
  
  imageMode(CENTER);
  image(layer, sketchWidth / 2, height / 2);

  if (demoMode)
  {
    // add some white on top
    blendMode(ADD);
    imageMode(CENTER);
    tint(60);
    image(layer, sketchWidth / 2, height / 2);
  }
}

float getHeightFromWidth(float sw, float sh, float dw)
{
  // dh/dw = sh/sw
  return round((sh * dw) / sw);
}

float getWidthFromHeight(float sw, float sh, float dh)
{
  // dh/dw = sh/sw 
  return round((dh * sw) / sh);
}

// returns time in seconds
float getTime()
{
  return (float) millis() / 1000.0;
}

float getDeltaTime()
{
  return getDeltaTime(getTime());
}

float getDeltaTime(float time)
{
  float dt = time - lastTime;
  if (lastTime == 0)
    dt = 0;
  lastTime = time;
  return dt;
}

PImage getImage()
{
  float r = random(0, 1);
  if (midiState[NOTE_INVISIBLE_SNOW])
    return sprite;
  else
    return r < 0.5 ? sprite : sprite2;
}

public void controllerChange(int channel, int number, int value) 
{
  messages.add(new MidiMessage(number, value));
}

void noteOn(int channel, int note, int velocity) 
{
  messages.add(new MidiMessage(true, note, velocity));
}

void noteOff(int channel, int note, int velocity) 
{
  messages.add(new MidiMessage(false, note, velocity));
}

void handleMidiMessages()
{
  MidiMessage message = messages.poll();
  while (message != null)
  {
    if (message.isNote)
    {
      if (message.onOff)
        handleNoteOn(0, message.note, message.velocity);
      else
        handleNoteOff(0, message.note, message.velocity);
    } else if (message.isCC)
    {
      handleCC(0, message.cc, message.ccValue);
    }

    message = messages.poll();
  }
}

void handleCC(int channel, int number, int value)
{
  if (internalControlUpdate)
    return;
  // println("Midi Controller - Channel: " + channel + ", number: " + number + ", value: " + value);
  midiValues[number] = floor((float)value *2.00787401574803); // Range: 0..255    (255/127)
  updateSliderFromMidi(number);
}

void handleNoteOn(int channel, int note, int velocity) 
{
  //println("Note on: " + note);
  midiState[note] = true;
  
  updateToggleFromMidi(note);

  if (note == NOTE_MOVIE_START_PAUSE)
    movieStartPause();
  else if (note == NOTE_MOVIE_STOP)
    movieStop();
  else if ( (note >= NOTE_BETLEHEM) && (note <= NOTE_CLEAR_SKYLINE) )
    updateSkyline(note == NOTE_CLEAR_SKYLINE);    
}

void handleNoteOff(int channel, int note, int velocity) 
{
  //println("Note off: " + note);
  midiState[note] = false;

  updateToggleFromMidi(note);

  if ( (note >= NOTE_BETLEHEM) && (note <= NOTE_CLEAR_SKYLINE) )
    updateSkyline(false);
}

void movieEvent(Movie m) {
  m.read();
  movieFrameReady = true;
}

void movieStartPause()
{
  if ( (!moviePlaying) || moviePaused)
  {
    movie.play();
    moviePlaying = true;
    moviePaused = false;
    println("Playing movie");
  }
  else
  {
    movie.pause();
    moviePlaying = false;
    moviePaused = true;
  }  
}

void movieStop()
{
  movie.stop();
  moviePlaying = false;
  movieFrameReady = false;
}

void zeroMidi()
{
  if (!enableMidi)
    return;
    
  internalControlUpdate = true;
  
  for (int i = NOTE_BETLEHEM; i<= NOTE_CLEAR_SKYLINE; i++)
  {
    midi.sendNoteOn(0, i, 0);
    midi.sendNoteOff(0, i, 0);
    midiState[i] = false;
  }

  for (int i = CONTROL_SNOW; i<= CONTROL_BLACK; i++)
  {
    midi.sendControllerChange(0, i, 0);
  }
  
  internalControlUpdate = false;  
}

void updateSkyline(boolean clearAllAndDropSnow)
{
  if (clearAllAndDropSnow)
  {
    if (enableMidi)
    {
      midi.sendNoteOn(0, NOTE_BETLEHEM, 0);
      midi.sendNoteOff(0, NOTE_BETLEHEM, 0);
      midi.sendNoteOn(0, NOTE_SHEPHERDS, 0);
      midi.sendNoteOff(0, NOTE_SHEPHERDS, 0);
      midi.sendNoteOn(0, NOTE_KINGS, 0);
      midi.sendNoteOff(0, NOTE_KINGS, 0);
      midi.sendNoteOn(0, NOTE_FAMILY, 0);
      midi.sendNoteOff(0, NOTE_FAMILY, 0);
      midi.sendNoteOn(0, NOTE_PEOPLE, 0);
      midi.sendNoteOff(0, NOTE_PEOPLE, 0);
    }

    midiState[NOTE_BETLEHEM] = false;
    midiState[NOTE_SHEPHERDS] = false;
    midiState[NOTE_KINGS] = false;
    midiState[NOTE_FAMILY] = false;
    midiState[NOTE_PEOPLE] = false;
    
    for (int i=NOTE_BETLEHEM; i<= NOTE_PEOPLE; i++)
    {
      updateToggleFromMidi(i);
    }
  }
  
  float h; 
  float w;

  skyline.beginDraw();

  skyline.tint(255);
  skyline.background(0);
  skyline.imageMode(CORNER);


  if (midiState[NOTE_BETLEHEM])
  {
    w = skyline.width;
    h = getHeightFromWidth(betlehem.width, betlehem.height, w) ;
    skyline.beginDraw();
    skyline.image(betlehem, 0, 2*skyline.height/3 - h/2, w, h);
    skyline.endDraw();
    particleSystem.setSkyline(skyline, new PVector(0, 0));
  }
  if (midiState[NOTE_SHEPHERDS])
  {
    h = 2.0 * skyline.height / 5.0;
    w = getWidthFromHeight(shepherds.width, shepherds.height, h);
    skyline.image(shepherds, 0, 2.0 * height / 3.0 - h/2, w, h);
  }  
  if (midiState[NOTE_KINGS])
  {
    h = 2.0 * skyline.height / 5.0;
    w = getWidthFromHeight(kings.width, kings.height, h);
    skyline.image(kings, skyline.width-w , 2.0 * height / 3.0 - h/2, w, h);
  }  
  if (midiState[NOTE_FAMILY])
  {
    w = 2.0 * skyline.width / 5.0;
    h = getHeightFromWidth(family.width, family.height, w);
    skyline.image(family, skyline.width/2 - w / 2 - w/8, 2.0 * height / 3.0 - h/2, w, h);
  }  
  if (midiState[NOTE_PEOPLE])
  {
    w = 2.0 * skyline.width / 5.0;
    h = getHeightFromWidth(peopleRight.width, peopleRight.height, w);
    skyline.image(peopleRight, skyline.width-w - skyline.width/30.0, 2.0 * height / 3.0 - h/2, w, h);
    w = 2.0 * skyline.width / 5.0;
    h = getHeightFromWidth(peopleLeft.width, peopleLeft.height, w);
    skyline.image(peopleLeft, skyline.width/30.0, 2.0 * height / 3.0 - h/2, w, h);
  }  

  skyline.endDraw();
  particleSystem.updateSkyline();

  if (clearAllAndDropSnow)
    particleSystem.unfreezeAll();  
}

void ChangeMidiValue(int cc, float delta)
{
  midiValues[cc] = midiValues[cc] + delta;
  if (midiValues[cc] < 0)
    midiValues[cc] = 0;
  else if (midiValues[cc] > 255)
    midiValues[cc] = 255;
}

void FlipMidiState(int note)
{
  midiState[note] = !midiState[note];
  updateSkyline(midiState[note] && note == NOTE_CLEAR_SKYLINE);
}

void keyPressed()
{
  // println("Key: " + key + ", keyCode: " + keyCode);
       if (key == '1') midiValues[CONTROL_SNOW] = 255; 
  else if (key == 'q') ChangeMidiValue(CONTROL_SNOW, 1); 
  else if (key == 'a') ChangeMidiValue(CONTROL_SNOW, -1);
  else if (key == 'z') midiValues[CONTROL_SNOW] = 0;

  else if (key == '2') midiValues[CONTROL_STORM] = 255;
  else if (key == 'w') ChangeMidiValue(CONTROL_STORM, 1);
  else if (key == 's') ChangeMidiValue(CONTROL_STORM, -1);
  else if (key == 'x') midiValues[CONTROL_STORM] = 0;

  else if (key == '3') midiValues[CONTROL_PEOPLE] = 255;
  else if (key == 'e') ChangeMidiValue(CONTROL_PEOPLE, 1);
  else if (key == 'd') ChangeMidiValue(CONTROL_PEOPLE, -1);
  else if (key == 'c') midiValues[CONTROL_PEOPLE] = 0;

  else if (key == '4') midiValues[CONTROL_WHITE_OVERLAY] = 255;
  else if (key == 'r') ChangeMidiValue(CONTROL_WHITE_OVERLAY, 1);
  else if (key == 'f') ChangeMidiValue(CONTROL_WHITE_OVERLAY, -1);
  else if (key == 'v') midiValues[CONTROL_WHITE_OVERLAY] = 0;

  else if (key == '5') midiValues[CONTROL_BLACK] = 255;
  else if (key == 't') ChangeMidiValue(CONTROL_BLACK, 1);
  else if (key == 'g') ChangeMidiValue(CONTROL_BLACK, -1);
  else if (key == 'b') midiValues[CONTROL_BLACK] = 255;
  
  else if (key == '6') midiValues[CONTROL_WHITE_BACKGROUND] = 255;
  else if (key == 'y') ChangeMidiValue(CONTROL_WHITE_BACKGROUND, 1);
  else if (key == 'h') ChangeMidiValue(CONTROL_WHITE_BACKGROUND, -1);
  else if (key == 'n') midiValues[CONTROL_BLACK] = 0;
  
  else if (keyCode == 112) FlipMidiState(NOTE_BETLEHEM);   // F1
  else if (keyCode == 113) FlipMidiState(NOTE_SHEPHERDS);  // F2
  else if (keyCode == 114) FlipMidiState(NOTE_KINGS);      // F3
  else if (keyCode == 115) FlipMidiState(NOTE_FAMILY);     // F4
  else if (keyCode == 116) FlipMidiState(NOTE_PEOPLE);         // F5
  else if (keyCode == 117) FlipMidiState(NOTE_INVISIBLE_SNOW); // F6
  else if (keyCode == 118) FlipMidiState(NOTE_CLEAR_SKYLINE);  // F7
  else if (keyCode == 119) movieStartPause();                  // F8
  else if (keyCode == 120) movieStop();                        // F9
}

void setupControlWindow()
{
  controls = new ControlWindow(this, "Winter Wonder World", 500, 500);

  PFont p = createFont("Georgia", 14); 
  controls.control().setControlFont(p, 14);

  controls.addSlider("midiValues", CONTROL_SNOW).setCaptionLabel("Snow amount").setRange(0, 255).setPosition(10, 10);
  controls.addSlider("midiValues", CONTROL_STORM).setCaptionLabel("Stormyness").setRange(0, 255).setPosition(10, 30);
  controls.addSlider("midiValues", CONTROL_PEOPLE).setCaptionLabel("People").setRange(0, 255).setPosition(10, 50);
  controls.addSlider("midiValues", CONTROL_WHITE_OVERLAY).setCaptionLabel("White overlay").setRange(0, 255).setPosition(10, 70);
  controls.addSlider("midiValues", CONTROL_WHITE_BACKGROUND).setCaptionLabel("White Back").setRange(0, 255).setPosition(10, 90);
  controls.addSlider("midiValues", CONTROL_BLACK).setCaptionLabel("Blackout").setRange(0, 255).setPosition(10, 110);

  controls.addToggle("midiState", NOTE_BETLEHEM).setCaptionLabel("Betlehem").setPosition(10, 150);
  controls.addToggle("midiState", NOTE_SHEPHERDS).setCaptionLabel("Shepherds").setPosition(10, 200);
  controls.addToggle("midiState", NOTE_KINGS).setCaptionLabel("Kings").setPosition(10, 250);
  controls.addToggle("midiState", NOTE_FAMILY).setCaptionLabel("Family").setPosition(10, 300);
  controls.addToggle("midiState", NOTE_PEOPLE).setCaptionLabel("People").setPosition(10, 350);
  controls.addToggle("midiState", NOTE_INVISIBLE_SNOW).setCaptionLabel("Invisible snow").setPosition(250, 150);

  controls.addButton("midiState", NOTE_CLEAR_SKYLINE).setCaptionLabel("Clear skyline").setPosition(250, 200);

  controls.addButton("midiState", NOTE_MOVIE_START_PAUSE).setCaptionLabel("Movie start / pause").setPosition(250, 300);
  controls.addButton("midiState", NOTE_MOVIE_STOP).setCaptionLabel("Movie stop").setPosition(250, 350);
}

// Workaround since ControlP5 doesn't support array fields
void controlEvent(ControlEvent theEvent) {
  if (!initDone)
    return;

  if (internalControlUpdate)
    return;
    
  if (theEvent.isController()) {
    // check if theEvent is coming from a midiValues controller
    if (theEvent.controller().name().startsWith("midiValues")) {
      // get the id of the controller and map the value
      // to an element inside the midiValues array.
      int id = theEvent.controller().id();
      if (id>=0 && id<midiValues.length) {
        internalControlUpdate = true;

        midiValues[id] = theEvent.value();

        int midiValue =  (int)(theEvent.value() / 2.00787401574803); // Range: 0..255    (255/127)

        if (enableMidi)
          midi.sendControllerChange(0, id, midiValue);

        internalControlUpdate = false;
      }
    }
    else if (theEvent.controller().name().startsWith("midiState")) {
      // get the id of the controller and map the value
      // to an element inside the midiState array.
      int id = theEvent.controller().id();
      if (id>=0 && id<midiState.length) {

        println("Event value: " + theEvent.value());

        boolean onOff = theEvent.value() == 1.0 ? true : false;
        midiState[id] = onOff;

        if (onOff)
          handleNoteOn(0, id, 127);
        else
          handleNoteOff(0, id, 127);

        internalControlUpdate = true;

        if ( (id >= NOTE_BETLEHEM) && (id <= NOTE_INVISIBLE_SNOW))
        { 
          if (enableMidi)
          {          
            if (onOff)
              midi.sendNoteOn(0, id, 127);
            else
            {        
              midi.sendNoteOn(0, id, 0);
              midi.sendNoteOff(0, id, 0);
            }
          }        
        }

        internalControlUpdate = false;
      }
    }
  }
}

void updateSliderFromMidi(int index)
{
  if (controls == null)
    return;
  
  if (internalControlUpdate)
    return;
  
  if (index == CONTROL_SNOW || index == CONTROL_STORM || index == CONTROL_PEOPLE || index == CONTROL_WHITE_OVERLAY ||
      index == CONTROL_WHITE_BACKGROUND || index == CONTROL_BLACK)
  {
    internalControlUpdate = true;

    Slider slider = controls.getSlider("midiValues", index);
    slider.setValue(midiValues[index]);

    internalControlUpdate = false;   
  } 
}

void updateToggleFromMidi(int index)
{
  if (controls == null)
    return;
  
  if (internalControlUpdate)
    return;
  
  if (index == NOTE_BETLEHEM || index == NOTE_SHEPHERDS || index == NOTE_KINGS || index == NOTE_FAMILY ||
      index == NOTE_PEOPLE || index == NOTE_INVISIBLE_SNOW)
  {
    internalControlUpdate = true;

    Toggle toggle = controls.getToggle("midiState", index);
    toggle.setValue(midiState[index]);

    internalControlUpdate = false;   
  } 
}

void parseCommandLine()
{
  for (String arg:args)
  {
    String[] parsed = arg.split("=", 2);
    if (parsed.length == 2)
      commandLine.put(parsed[0], parsed[1]);
    else
      commandLine.put(arg, arg);
  }
}

boolean getCommandLineFlag(String key, boolean def)
{
  if (commandLine.containsKey(key))
  { 
    return commandLine.get(key) == "true";
  }
  else
    return def;
}

int getCommandLineInt(String key, int def)
{
  if (commandLine.containsKey(key))
  { 
    String str = commandLine.get(key);
    try {
      int i = Integer.parseInt(str);
      return i;
    }
    catch (NumberFormatException e)
    {
      return def;
    }
  }
  else
    return def;
}


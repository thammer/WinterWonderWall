import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.awt.Frame; 
import java.awt.BorderLayout; 
import java.util.*; 
import java.util.concurrent.*; 
import controlP5.*; 
import processing.video.*; 

import themidibus.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class WinterWonderWall extends PApplet {

// See README.md for more information about this sketch









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

public void init()
{
  parseCommandLine();

  if (frame.isUndecorated())
    presentMode = true;

  super.init();
}

public void setup()
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
  
  if (demoMode)
  {
    wallMaskFilename = "data/WallMaskDemo.txt";
    whiteOverlayMaskFilename = "data/WhiteOverlayMaskDemo.txt";
  }
  
  wallMask = new PolygonMask(wallMaskFilename, width, height, 20, true, 'p', scaleFactor, 0.0f, 0.0f);
  whiteOverlayMask = new PolygonMask(whiteOverlayMaskFilename, width, height, 5, false, 'l', scaleFactor, 0.0f, 0.0f);
  
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

  messages = new ConcurrentLinkedQueue<MidiMessage>();

  MidiBus.list();
  if (enableMidi)
    midi = new MidiBus(this, midiInPort, midiOutPort);

  for (int i=0; i<128; i++)
  {
    midiValues[i] = 0;
    midiState[i] = false;
  }

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


public void draw()
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
    w = 2.0f * width / 5.0f;
    h = getHeightFromWidth(peopleRight.width, peopleRight.height, w);
    layer.image(peopleRightWipe.getImage(), width-w - width/30.0f, 2.0f * height / 3.0f - h/2, w, h);

    w = 2.0f * width / 5.0f;
    h = getHeightFromWidth(peopleLeft.width, peopleLeft.height, w);
    layer.image(peopleLeftWipe.getImage(), width/30.0f, 2.0f * height / 3.0f - h/2, w, h);
    
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
    ( (midiValues[CONTROL_STORM] < 100) ? 0 : 3.0f*midiValues[CONTROL_STORM]/255.0f) ); 

  //flakesPerSecond = mouseY ;
  particleSystem.stormyness = mouseX / 2;
  
  if (lastFlakeTime == 0)
    lastFlakeTime = time;
  if (flakesPerSecond < 0.1f)
    lastFlakeTime = time; // or else it could be an avalanche when it starts snowing after a while
  
  float initialVelocityScale = 1.0f + 2.0f*midiValues[CONTROL_STORM]/255.0f; // snow 3x fast when storming 
  
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

  float tintScale = 1.0f;
  
  if (demoMode)
    tintScale = 0.6f;
  
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

public float getHeightFromWidth(float sw, float sh, float dw)
{
  // dh/dw = sh/sw
  return round((sh * dw) / sw);
}

public float getWidthFromHeight(float sw, float sh, float dh)
{
  // dh/dw = sh/sw 
  return round((dh * sw) / sh);
}

// returns time in seconds
public float getTime()
{
  return (float) millis() / 1000.0f;
}

public float getDeltaTime()
{
  return getDeltaTime(getTime());
}

public float getDeltaTime(float time)
{
  float dt = time - lastTime;
  if (lastTime == 0)
    dt = 0;
  lastTime = time;
  return dt;
}

public PImage getImage()
{
  float r = random(0, 1);
  if (midiState[NOTE_INVISIBLE_SNOW])
    return sprite;
  else
    return r < 0.5f ? sprite : sprite2;
}

public void controllerChange(int channel, int number, int value) 
{
  messages.add(new MidiMessage(number, value));
}

public void noteOn(int channel, int note, int velocity) 
{
  messages.add(new MidiMessage(true, note, velocity));
}

public void noteOff(int channel, int note, int velocity) 
{
  messages.add(new MidiMessage(false, note, velocity));
}

public void handleMidiMessages()
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

public void handleCC(int channel, int number, int value)
{
  if (internalControlUpdate)
    return;
  // println("Midi Controller - Channel: " + channel + ", number: " + number + ", value: " + value);
  midiValues[number] = floor((float)value *2.00787401574803f); // Range: 0..255    (255/127)
  updateSliderFromMidi(number);
}

public void handleNoteOn(int channel, int note, int velocity) 
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

public void handleNoteOff(int channel, int note, int velocity) 
{
  //println("Note off: " + note);
  midiState[note] = false;

  updateToggleFromMidi(note);

  if ( (note >= NOTE_BETLEHEM) && (note <= NOTE_CLEAR_SKYLINE) )
    updateSkyline(false);
}

public void movieEvent(Movie m) {
  m.read();
  movieFrameReady = true;
}

public void movieStartPause()
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

public void movieStop()
{
  movie.stop();
  moviePlaying = false;
  movieFrameReady = false;
}

public void zeroMidi()
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

public void updateSkyline(boolean clearAllAndDropSnow)
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
    h = 2.0f * skyline.height / 5.0f;
    w = getWidthFromHeight(shepherds.width, shepherds.height, h);
    skyline.image(shepherds, 0, 2.0f * height / 3.0f - h/2, w, h);
  }  
  if (midiState[NOTE_KINGS])
  {
    h = 2.0f * skyline.height / 5.0f;
    w = getWidthFromHeight(kings.width, kings.height, h);
    skyline.image(kings, skyline.width-w , 2.0f * height / 3.0f - h/2, w, h);
  }  
  if (midiState[NOTE_FAMILY])
  {
    w = 2.0f * skyline.width / 5.0f;
    h = getHeightFromWidth(family.width, family.height, w);
    skyline.image(family, skyline.width/2 - w / 2 - w/8, 2.0f * height / 3.0f - h/2, w, h);
  }  
  if (midiState[NOTE_PEOPLE])
  {
    w = 2.0f * skyline.width / 5.0f;
    h = getHeightFromWidth(peopleRight.width, peopleRight.height, w);
    skyline.image(peopleRight, skyline.width-w - skyline.width/30.0f, 2.0f * height / 3.0f - h/2, w, h);
    w = 2.0f * skyline.width / 5.0f;
    h = getHeightFromWidth(peopleLeft.width, peopleLeft.height, w);
    skyline.image(peopleLeft, skyline.width/30.0f, 2.0f * height / 3.0f - h/2, w, h);
  }  

  skyline.endDraw();
  particleSystem.updateSkyline();

  if (clearAllAndDropSnow)
    particleSystem.unfreezeAll();  
}

public void ChangeMidiValue(int cc, float delta)
{
  midiValues[cc] = midiValues[cc] + delta;
  if (midiValues[cc] < 0)
    midiValues[cc] = 0;
  else if (midiValues[cc] > 255)
    midiValues[cc] = 255;
}

public void FlipMidiState(int note)
{
  midiState[note] = !midiState[note];
  updateSkyline(midiState[note] && note == NOTE_CLEAR_SKYLINE);
}

public void keyPressed()
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
  else if (key == 'n') midiValues[CONTROL_WHITE_BACKGROUND] = 0;
  
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

public void setupControlWindow()
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
public void controlEvent(ControlEvent theEvent) {
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

        int midiValue =  (int)(theEvent.value() / 2.00787401574803f); // Range: 0..255    (255/127)

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

        boolean onOff = theEvent.value() == 1.0f ? true : false;
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

public void updateSliderFromMidi(int index)
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

public void updateToggleFromMidi(int index)
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

public void parseCommandLine()
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

public boolean getCommandLineFlag(String key, boolean def)
{
  if (commandLine.containsKey(key))
  { 
    return commandLine.get(key) == "true";
  }
  else
    return def;
}

public int getCommandLineInt(String key, int def)
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

// Based on ControlP5 Sample: "ControlP5Frame" 

public class ControlWindow extends PApplet {

  ControlP5 cp5;
  Object parent;
  Frame frame;
  String title;

  int windowWidth, windowHeight;

  public void setup() {
    size(windowWidth, windowHeight);
    frameRate(25);
  }

  public void draw() {
      
    frame.setVisible(true); // concurrent draw / control creation workaround

    background(0);
  }
  
  private ControlWindow() {
  }

  public ControlWindow(Object parent, String title, int windowWidth, int windowHeight) {
    this.parent = parent;
    this.title = title;
    this.windowWidth = windowWidth;
    this.windowHeight = windowHeight;

    init();

    cp5 = new ControlP5(this);    
  }

  public void setupFrame()
  {
    frame = new Frame(title);
    frame.add(this);
    //init();
    frame.setTitle(title);  
    frame.setSize(windowWidth, windowHeight);
    frame.setLocation(100, 100);
    frame.setResizable(false);
    frame.setVisible(false); // concurrent draw / control creation workaround    
  }

  public ControlP5 control() {
    return cp5;
  }

  // Convenience methods for adding controls for variables that are part of the parent window
  
  // Slider
  
  public Slider addSlider(String theName)
  {
    Slider slider = cp5.addSlider(theName).plugTo(parent, theName);
    return slider;
  }

  public Slider addSlider(String theName, int index)
  {
    String nameWithPostfix = theName + "_" + index;
    Slider slider = cp5.addSlider(nameWithPostfix).setId(index).plugTo(parent, theName);
    return slider;
  }
  
  public Slider getSlider(String name)
  {
    return (Slider)cp5.getController(name);
  }

  public Slider getSlider(String name, int index)
  {
    String nameWithPostfix = name + "_" + index;
    return (Slider)cp5.getController(nameWithPostfix);
  }
  
  // Toggle
  
  public Toggle addToggle(String theName)
  {
    Toggle toggle = cp5.addToggle(theName).plugTo(parent, theName);
    return toggle;
  }

  public Toggle addToggle(String theName, int index)
  {
    String nameWithPostfix = theName + "_" + index;
    Toggle toggle = cp5.addToggle(nameWithPostfix).setId(index).plugTo(parent, theName);
    return toggle;
  }
  
  public Toggle getToggle(String name)
  {
    return (Toggle)cp5.getController(name);
  }

  public Toggle getToggle(String name, int index)
  {
    String nameWithPostfix = name + "_" + index;
    return (Toggle)cp5.getController(nameWithPostfix);
  }

  // Button
  
  public Button addButton(String theName)
  {
    Button button = cp5.addButton(theName).plugTo(parent, theName);
    return button;
  }

  public Button addButton(String theName, int index)
  {
    String nameWithPostfix = theName + "_" + index;
    Button button = cp5.addButton(nameWithPostfix).setId(index).plugTo(parent, theName);
    return button;
  }
  
  public Button getButton(String name)
  {
    return (Button)cp5.getController(name);
  }

  public Button getButton(String name, int index)
  {
    String nameWithPostfix = name + "_" + index;
    return (Button)cp5.getController(nameWithPostfix);
  }
}


final static int ORIGIN_LEFT   = 0;
final static int ORIGIN_RIGHT  = 1;
final static int ORIGIN_TOP    = 2;
final static int ORIGIN_BOTTOM = 3;

class ImageWipe
{
  private int origin = ORIGIN_LEFT;
  private PImage image;
  private float wipe = 0; // 0..255
  
  PGraphics wipedImage;
  
  ImageWipe(PImage image, int origin)
  {
    this.image = image;
    this.wipedImage = createGraphics(image.width, image.height);
    
    this.origin = origin;
  }
  
  public void wipeImage(float wipe)
  {
    wipedImage.beginDraw();
    wipedImage.image(image, 0, 0);
    wipedImage.fill(0);
    wipedImage.stroke(0);
    if (origin == ORIGIN_LEFT)
      wipedImage.rect(0, 0, wipe / 255.0f * image.width, image.height);
    else if (origin == ORIGIN_RIGHT)
      wipedImage.rect( (255 - wipe) / 255.0f * image.width, 0, image.width, image.height);
    else if (origin == ORIGIN_TOP)
      wipedImage.rect( 0, 0, image.width, wipe / 255.0f * image.height);
    else if (origin == ORIGIN_BOTTOM)
      wipedImage.rect( 0, (255 - wipe) / 255.0f * image.height, image.width, image.height);
    wipedImage.endDraw();
  }
  
  public PImage getImage()
  {
    return wipedImage;
  }
}

/*

ParticleSystem with frozen and freezing:

class ParticleSystem
{
  ArrayList<Particle> particles;
  ArrayList<Particle> freezingParticles;
  ArrayList<Particle> frozenParticles;
  PImage sprite;
  PVector frameMin = null;
  PVector frameMax = null;
  PImage skyline;
  PVector skylinePosition;
  PGraphics layer;
  PGraphics frozenLayer = null;
  float lastTime = 0;

  ParticleSystem(PGraphics layer, PImage sprite)
  {
    this.layer = layer;
    this.sprite = sprite;
    particles = new ArrayList<Particle>();
    freezingParticles = new ArrayList<Particle>();
    frozenParticles = new ArrayList<Particle>();
    frozenLayer = createGraphics(layer.width, layer.height, P2D);
    lastTime = 0;
    //populate();
  }
  
  void populate()
  {
    for (int i=0; i<100; i++)
    {
      Particle p = new Particle(layer, sprite);
      particles.add(p);
      p.position = new PVector(i*2, 20);
      p.velocity = new PVector(random(0.1, 1), random(0.5, 5));
      p.acceleration = new PVector(0, random(0, 0.5));
    }
  }
  
  // position is upper left corner of image
  void setSkyline(PImage skyline, PVector position)
  {
    this.skyline = skyline;
    this.skylinePosition = position;
    this.skyline.loadPixels();
  }
  
  void addParticle(Particle p)
  {
    particles.add(p);
  }
  
  void update()
  {
    float time = (float) millis() / 1000.0;
    float dt = time - lastTime;
    if (lastTime == 0)
      dt = 0;
    lastTime = time;
    update(dt);
  }
  
  // dt is difference in time since last time the function was called, given in seconds
  void update(float dt)
  {
    if (dt <= 0)
      return;
      
    Iterator<Particle> it = particles.iterator();
    while (it.hasNext())
    {
      Particle particle = it.next();
      particle.update(dt);
      checkInsideFrame(particle);
      checkSkyline(particle);
      if (particle.isDead())
      {
        it.remove();
      }
      else if (particle.isFrozen())
      {
        it.remove();
        freezingParticles.add(particle);
      }  
    }
  }
  
  void draw()
  {
    imageMode(CENTER);
    for (Particle particle: particles)
    {
      particle.draw();
    }
    
    if (drawFrozen)
    {
      drawFrozen = 
    }
  }
  
  int numParticles()
  {
    return particles.size();
  }

  void unfreezeAll()
  {
    for (Particle particle: particles)
    {
      particle.frozen = false;
    }
    updateFrozen = true;
  }
  
  private void checkInsideFrame(Particle particle)
  {
    if ( (frameMin != null) && (frameMax != null) &&
         ((particle.position.x < frameMin.x) || (particle.position.y < frameMin.y) ||
          (particle.position.x > frameMax.x) || (particle.position.y > frameMax.y)) )
    {
      particle.dead = true;
      //print("-");
    } 
  }
  
  private void checkSkyline(Particle particle)
  {
    if (this.skyline == null)
      return;
              
    float fsx = particle.position.x - skylinePosition.x;
    fsx = fsx < 0 ? 0 : fsx > this.skyline.width - 1 ? this.skyline.width - 1 : fsx;
    float fsy = particle.position.y - skylinePosition.y;
    fsy = fsy < 0 ? 0 : fsy > this.skyline.height - 1 ? this.skyline.height - 1 : fsy;
    int sx = round(fsx);
    int sy = round(fsy);
    
    int loc = sy * this.skyline.width + sx;
    
    //println("x: " + sx + ", y: " + sy + " - " + loc + " - " + particle.position);
    
    if (red(skyline.pixels[loc]) > 50)
    {
      particle.frozen = true;
      for (int y=-1; y<=1; y++)
        for (int x=-1; x<=1; x++)
        {
          loc = (sy + y) * this.skyline.width + (sx + x);
          if (loc < skyline.pixels.length)
            skyline.pixels[loc] = 0; // remove pixel in skyline
        }
    }
  }
  
  boolean lessThan(PVector v1, PVector v2)
  {
    return (v1.x < v2.x) && (v1.y < v2.y);
  }
  
  boolean greaterThan(PVector v1, PVector v2)
  {
    return (v1.x > v2.x) && (v1.y > v2.y);
  }
}

%% Particle system with separate skyline

class ParticleSystem
{
  ArrayList<Particle> particles;
  PImage sprite;
  PVector frameMin = null;
  PVector frameMax = null;
  PImage skyline;
  PVector skylinePosition;
  PGraphics layer;
  float lastTime = 0;
  int skylineThreshold = 50;

  ParticleSystem(PGraphics layer, PImage sprite)
  {
    this.layer = layer;
    this.sprite = sprite;
    particles = new ArrayList<Particle>();
    lastTime = 0;
    //populate();
  }
  
  void populate()
  {
    for (int i=0; i<100; i++)
    {
      Particle p = new Particle(layer, sprite);
      particles.add(p);
      p.position = new PVector(i*2, 20);
      p.velocity = new PVector(random(0.1, 1), random(0.5, 5));
      p.acceleration = new PVector(0, random(0, 0.5));
    }
  }
  
  // position is upper left corner of image
  void setSkyline(PImage originalSkyline, PVector position)
  {
    this.skyline = createGraphics(originalSkyline.width, originalSkyline.height);
    this.skylinePosition = position;
    this.skyline.loadPixels();
    originalSkyline.loadPixels();
    // 255 means no pixels below have color red > skylineThreshold
    
    for (int x = 0; x < originalSkyline.width; x++)
    {
      boolean first = true;
      for (int y = originalSkyline.height - 1; y >= 0; y--)
      {
        int loc = y * originalSkyline.width + x;
        if (red(originalSkyline.pixels[loc]) > skylineThreshold)
        {
          if (first)
          {
            this.skyline.pixels[loc] = color(254, 254, 254); // last pixel in that row
            first = false;
          }
          else
          {
            this.skyline.pixels[loc] = color(253, 253, 253); // more pixels below
          }
        }
        else
        {
          this.skyline.pixels[loc] = color(0, 0, 0);
        }
      }
    }   
  }
  
  void addParticle(Particle p)
  {
    particles.add(p);
  }
  
  void update()
  {
    float time = (float) millis() / 1000.0;
    float dt = time - lastTime;
    if (lastTime == 0)
      dt = 0;
    lastTime = time;
    update(dt);
  }
  
  // dt is difference in time since last time the function was called, given in seconds
  void update(float dt)
  {
    if (dt <= 0)
      return;
      
    Iterator<Particle> it = particles.iterator();
    while (it.hasNext())
    {
      Particle particle = it.next();
      particle.update(dt);
      checkInsideFrame(particle);
      checkSkyline(particle);
      if (particle.isDead())
      {
        it.remove();
      }
    }
  }
  
  void draw()
  {
    imageMode(CENTER);
    for (Particle particle: particles)
    {
      particle.draw();
    }
  }
  
  int numParticles()
  {
    return particles.size();
  }

  void unfreezeAll()
  {
    for (Particle particle: particles)
    {
      particle.frozen = false;
    }
  }
  
  private void checkInsideFrame(Particle particle)
  {
    if ( (frameMin != null) && (frameMax != null) &&
         ((particle.position.x < frameMin.x) || (particle.position.y < frameMin.y) ||
          (particle.position.x > frameMax.x) || (particle.position.y > frameMax.y)) )
    {
      particle.dead = true;
      //print("-");
    } 
  }
  
  private void checkSkyline(Particle particle)
  {
    if (this.skyline == null)
      return;
              
    float fsx = particle.position.x - skylinePosition.x;
    fsx = fsx < 0 ? 0 : fsx > this.skyline.width - 1 ? this.skyline.width - 1 : fsx;
    float fsy = particle.position.y - skylinePosition.y;
    fsy = fsy < 0 ? 0 : fsy > this.skyline.height - 1 ? this.skyline.height - 1 : fsy;
    int sx = round(fsx);
    int sy = round(fsy);
    
    int loc = sy * this.skyline.width + sx;
    
    //println("x: " + sx + ", y: " + sy + " - " + loc + " - " + particle.position);
    
    if (red(skyline.pixels[loc]) > skylineThreshold)
    {
      particle.frozen = true;
      for (int y=-1; y<=1; y++)
        for (int x=-1; x<=1; x++)
        {
          loc = (sy + y) * this.skyline.width + (sx + x);
          if (loc < skyline.pixels.length)
          {
            if (red(skyline.pixels[loc])<254)
              skyline.pixels[loc] = 0; // remove pixel in skyline
            else if (red(skyline.pixels[loc])==254) // last pixel in row
              skyline.pixels[loc] = color(255, 255, 255); // last pixel in row is now filled
            else if (red(skyline.pixels[loc]) == 255)
              particle.dead = true; // don't snow past last pixel in row
          }
        }
    }
  }
  
  boolean lessThan(PVector v1, PVector v2)
  {
    return (v1.x < v2.x) && (v1.y < v2.y);
  }
  
  boolean greaterThan(PVector v1, PVector v2)
  {
    return (v1.x > v2.x) && (v1.y > v2.y);
  }
}


*/
class MidiMessage
{
  boolean isNote;
  boolean isCC;
  
  boolean onOff;
  int note;
  int velocity;
  int cc;
  int ccValue;
  
  MidiMessage(boolean onOff, int note, int velocity)
  {
    this.isNote = true;
    this.isCC = false;
    this.onOff = onOff;
    this.note = note;
    this.velocity = velocity;
  }

  MidiMessage(int cc, int value)
  {
    this.isNote = false;
    this.isCC = true;
    this.cc = cc;
    this.ccValue = value;  
  }
}

/*

Next:
-v In present mode, use full screen size, but scale masks and images to 
  match actual resolution according to designWidth/designHeight,
  and position layer in the middle - effectively drawing over the
  "stop" text in lower left corner.
-v Make masks resolution independant
  -v Perhaps we should support resolution independence, but not aspect 
    ratio independence. This would work in development mode and in 
    present mode.
  - When defining mask, get position relative to layer, not relative to sketch 
    (in case width is different)
-x Support widescreen format
  - No, presentation should have the same aspect ratio independent of
    resolution.
- Control panel in second window
  -v midi and control panel in sync
  -v buttons in control panel
  - mask definition start/stop in second window
  - selectable midi input and output
  - status display in control panel (memory, particles, framerate)
  - larger font for slider
  - abstracttion layer for values and states (buttons)
  - mouse drag slider and click on buttons
  - keyboard control of buttons
  - selectable midi mapping
- Improve performance
  - profiling, test each feature standalone and measure framerate / CPU load
- use promodi, as it is LGPL - themidibus is GPL
- support OSC too
- ikke skygge under konger v snow, kanskje egen knapp for dette
- fade inn stjerner
- fade inn andre figurer
  - familie
  - konger fra siden a la people left right
- Stars tinkle
  - small stars
  - one big star
  - fader fades in small and big star
- Cross outline (lineset stored in text file)

Problems:
-v The ControlP5 library sometimes throws ConcurrentModificationException on startup.
  This is probably related to running it in a separate PApplet / frame, and
  controller (sliders, buttons) creation happening at the same time as a draw() for that PApplet.
  
  I have tried to work around it by not doing any draw()'ing until initDone (see ControlFrame),
  but as the PApplet draw() is called anyway methinks, some times it happens.
  
  See this link for a possible workaround, requiring modifications in ControlP5:
  - http://forum.processing.org/topic/controlp5-and-java-util-concurrentmodificationexception

  Update: I think I fixed this by not creating the frame where ControlP5 lives until all controllers have been created.
  
*/
class Particle
{
  PImage image;
  PGraphics layer; 
  PVector position;
  PVector velocity; // pixels per second (or should it be size-independant?)
  PVector initialVelocity; 
  float velocityBlend = 0; // [0..1], 0 = only velocity, 1 = only initialVelocity, inbetween = blend
  PVector acceleration; // pixels per second per second
  float life; // seconds
  boolean useLife = false;
  boolean dead = false;
  boolean frozen = false;
  
  Particle(PGraphics layer, PImage image)
  {
    this.layer = layer;
    this.image = image;
    this.position = new PVector(0, 0);
    this.velocity = new PVector(0, 0);
    this.acceleration = new PVector(0, 0);
    this.life = 20;
  }
  
  public void setVelocity(PVector velocity)
  {
    this.velocity = velocity.get();
    this.initialVelocity = velocity.get();
  }
  
  public void setForce(PVector force)
  {
    this.acceleration = force.get();
  }  
  
  public void applyForce(PVector force)
  {
    this.acceleration.add(force);
  }
  
  public void update(float dt)
  {
    if (frozen)
      return;
    // dp = v * dt
    PVector v = PVector.add( PVector.mult(initialVelocity, velocityBlend), PVector.mult(velocity, 1.0f - velocityBlend) );
    PVector dp = PVector.mult(v, dt);
    this.position.add(dp);
    // dv = a * dt
    PVector dv = PVector.mult(this.acceleration, dt);
    this.velocity.add(dv);
    //println("dt = " + dt + ", dp = " + dp + ", dv = " + dv);
    life = life - dt;
  }
  
  public void draw()
  {
    // tint(life/100.0*255);
    layer.image(this.image, position.x, position.y);
  }
  
  public boolean isDead()
  {
    if (useLife && (life <= 0))
      dead = true;
    return dead;
  }
  
  public boolean isFrozen()
  {
    return frozen;
  }
}
/*

Skyline:

Input image: > skylineThreshold means particle freezen when location hit

Input image is transformed slightly:
- bottom pixel in each row in skyline is set to 254
- when a particle reaches bottom pixel, bottom pixel is set to 255 and particle is deleted
  (to avoid growing amount of frozen particles)

*/

class ParticleSystem
{
  ArrayList<Particle> particles;
  PImage sprite;
  PVector frameMin = null;
  PVector frameMax = null;
  PImage skyline;
  PVector skylinePosition;
  PGraphics layer;
  int skylineThreshold = 50;
  int stormyness = 0; // [0..255] 0 = off, 255 = max
  private float lastTime = 0;
  private int[] lowestPointOnSkyline;
  private float accumulatedTime = 0;
  boolean invisibleSnow = false;

  ParticleSystem(PGraphics layer, PImage sprite)
  {
    this.layer = layer;
    this.sprite = sprite;
    particles = new ArrayList<Particle>();
    lastTime = 0;
    //populate();
  }
  
  public void populate()
  {
    for (int i=0; i<100; i++)
    {
      Particle p = new Particle(layer, sprite);
      particles.add(p);
      p.position = new PVector(i*2, 20);
      p.velocity = new PVector(random(0.1f, 1), random(0.5f, 5));
      p.acceleration = new PVector(0, random(0, 0.5f));
    }
  }
  
  // position is upper left corner of image
  public void setSkyline(PImage skyline, PVector position)
  {
    this.skyline = skyline;
    this.skylinePosition = position;
    updateSkyline();    
  }
  
  public void updateSkyline()
  {
    this.skyline.loadPixels();

    lowestPointOnSkyline = new int[this.skyline.width];
    Arrays.fill(lowestPointOnSkyline, this.skyline.height);
    
    for (int x = 0; x < this.skyline.width; x++)
    {
      boolean first = true;
      for (int y = this.skyline.height - 1; y >= 0; y--)
      {
        int loc = y * this.skyline.width + x;
        if (red(this.skyline.pixels[loc]) > skylineThreshold)
        {
          if (first)
          {
            lowestPointOnSkyline[x] = y;
            first = false;
          }
        }
      }
    }   
  }
  
  public void addParticle(Particle p)
  {
    particles.add(p);
  }
  
  public void update()
  {
    float time = (float) millis() / 1000.0f;
    float dt = time - lastTime;
    if (lastTime == 0)
      dt = 0;
    lastTime = time;
    update(dt);
  }
  
  // dt is difference in time since last time the function was called, given in seconds
  public void update(float dt)
  {
    if (dt <= 0)
      return;
      
    accumulatedTime += dt;
    Iterator<Particle> it = particles.iterator();
    while (it.hasNext())
    {
      Particle particle = it.next();
      applyForce(particle);
      particle.update(dt);
      checkInsideFrame(particle);
      checkSkyline(particle);
      if (particle.isDead())
      {
        it.remove();
      }
    }
  }
  
  public void draw()
  {
    imageMode(CENTER);
    for (Particle particle: particles)
    {
      if ( (!invisibleSnow) || (invisibleSnow && particle.frozen))
        particle.draw();
    }
  }
  
  public int numParticles()
  {
    return particles.size();
  }

  public void unfreezeAll()
  {
    for (Particle particle: particles)
    {
      particle.frozen = false;
    }
  }
  
  private void applyForce(Particle particle)
  {
    //if (stormyness <= 4)
    //  return;
      
    float scale = (float)stormyness / 255.0f;
    float sign = particle.position.z < 0 ? -1.0f : 1.0f;

    float phase = 400.0f * sin (accumulatedTime / 5.0f * 2 * PI) + random(-30, 30);
    float amp = scale * 100.0f;
    float wavelength = 600 + 400 * sin(accumulatedTime / 10.0f * 2 * PI);
    PVector f = new PVector(
      amp * sign * sin((particle.position.x + phase) / wavelength * 2 * PI), 
      amp * 0.5f * ( 0.2f + cos((particle.position.x + phase) / wavelength * 2 * PI)));
    particle.setForce(f);
    particle.velocityBlend = 1.0f - scale;
  }
  
  private void checkInsideFrame(Particle particle)
  {
    if ( (frameMin != null) && (frameMax != null) &&
         ((particle.position.x < frameMin.x) || (particle.position.y < frameMin.y) ||
          (particle.position.x > frameMax.x) || (particle.position.y > frameMax.y)) )
    {
      particle.dead = true;
      //print("-");
    } 
  }
  
  private void checkSkyline(Particle particle)
  {
    if (this.skyline == null)
      return;
              
    float fsx = particle.position.x - skylinePosition.x;
    fsx = fsx < 0 ? 0 : fsx > this.skyline.width - 1 ? this.skyline.width - 1 : fsx;
    float fsy = particle.position.y - skylinePosition.y;
    fsy = fsy < 0 ? 0 : fsy > this.skyline.height - 1 ? this.skyline.height - 1 : fsy;
    int sx = round(fsx);
    int sy = round(fsy);
    
    int loc = sy * this.skyline.width + sx;
    
    //println("x: " + sx + ", y: " + sy + " - " + loc + " - " + particle.position);
    
    if (red(skyline.pixels[loc]) > skylineThreshold)
    {
      particle.frozen = true;
      for (int y=-1; y<=1; y++)
      {
        for (int x=-1; x<=1; x++)
        {
          loc = (sy + y) * this.skyline.width + (sx + x);
          if (loc < skyline.pixels.length)
          {
            skyline.pixels[loc] = 0; // remove pixel in skyline
          }
        }
      }
    }
    if ( (sx < lowestPointOnSkyline.length) && (sy > lowestPointOnSkyline[sx]))
      particle.dead = true; // don't snow past last pixel in row
  }
  
  public boolean lessThan(PVector v1, PVector v2)
  {
    return (v1.x < v2.x) && (v1.y < v2.y);
  }
  
  public boolean greaterThan(PVector v1, PVector v2)
  {
    return (v1.x > v2.x) && (v1.y > v2.y);
  }
}

/*

2012-12-06 Christmas Concert with KorX in SSK
---------------------------------------------

  - Processing version 2.0b6 on OSX MacBook Pro 2011
  - Processing set to use 1024 MB RAM
  - Midi controller Behringer BCF2000
    Sliders CC 81-88 7-bit
    Buttons above sliders:
    - Button 1-5 toggle (skyline images)
    - Button 7 toggle (invisible snow)
    - Button 8 no toggle (clear skyline, snow fall)
    Buttons lower right
    - Button 1 no toggle (start/pause video)
    - Button 2 no toggle (stop/reset video)
    
  Framerate was OK, but CPU was above 100% when lots of 
  snow and especially when fading in people.
*/
public class PolygonMask
{
  PGraphics mask;
  ArrayList<PVector> polygon; // points in the mask, unscaled and relative to mask, not to sketch
  String filename;
  int width;
  int height;
  float blurRadius;
  boolean inverse;
  char settingsKey;
  float scale = 1.0f; // scale mask coordinates
  float mouseOffsetX; // needed if layer isn't positioned at 0, 0 in the sketch
  float mouseOffsetY;
  
  boolean editing = false;

  PolygonMask(String filename, int width, int height, float blurRadius, boolean inverse, char settingsKey, 
              float scale, float mouseOffsetX, float mouseOffsetY)
  {
    this.filename = filename;  
    this.width = width;
    this.height = height;
    this.blurRadius = blurRadius;
    this.inverse = inverse;
    this.settingsKey = settingsKey;
    this.scale = scale;
    this.mouseOffsetX = mouseOffsetX;
    this.mouseOffsetY = mouseOffsetY;
        
    mask = createGraphics(width, height);
    polygon = new ArrayList<PVector>();    
    
    registerMethod("mouseEvent", this);
    registerMethod("keyEvent", this);
    registerDraw(this);
    
    loadPolygon();
    updateMask();
  }
  
  public void savePolygon()
  {
    int length = polygon.size();
    String[] lines = new String[length];
    for (int i = 0; i < length; i++) 
    {
      PVector vec = polygon.get(i);
      lines[i] = vec.x + "\t" + vec.y;
    }
    saveStrings(filename, lines);  
  }
  
  public boolean loadPolygon()
  {
    String[] lines = loadStrings(filename);
    if (lines == null)
      return false;
      
    for (int i=0; i<lines.length; i++)
    {
      String[] strings = split(lines[i], "\t");
      PVector vec = new PVector(PApplet.parseFloat(strings[0]), PApplet.parseFloat(strings[1]));
      polygon.add(vec);
    }
    
    return true;
  }
  
  public void updateMask()
  {  
    if (polygon.size() <= 2)
      return;
    
    float grey = 255;
    if (inverse)
      grey = 0;
      
    mask.beginDraw();
   
    mask.background(0);
    mask.fill(255);
    mask.noStroke();
  
    mask.beginShape();
    for (PVector v: polygon)
    {
      mask.vertex(v.x * scale, v.y * scale);
    }
    mask.endShape();
  
    mask.endDraw();
    
    if (blurRadius > 0)
      mask.filter(BLUR, blurRadius);
    
    mask.loadPixels();
    for (int i=0; i<mask.pixels.length; i++)
    {
      int pixel = mask.pixels[i];
      float alpha = 0;
      if (inverse) {
        alpha = 255 - red(pixel);
      }
      else {
        alpha = red(pixel);
      }
      mask.pixels[i] = color(grey, grey, grey, alpha);
    }
    mask.updatePixels();
  }
 
  public void createEllipticalMask()
  {
  
    mask.beginDraw();
    mask.background(0);
    mask.fill(255);
    mask.noStroke();
    mask.ellipse(width/2, height/2, width-90, height-90);
    mask.endDraw();
    if (blurRadius > 0)
      mask.filter(BLUR, blurRadius);
    mask.loadPixels();
    for (int i=0; i<mask.pixels.length; i++)
    {
      int pixel = mask.pixels[i];
      mask.pixels[i] = color(0, 0, 0, 255 - red(pixel));
    }
    mask.updatePixels();
  }
  

  public void mouseEvent(MouseEvent event)
  {
    if (event.getAction() == MouseEvent.CLICK)
    {
      if (editing)
      {
        polygon.add(new PVector( (mouseX - mouseOffsetX) / scale, (mouseY - mouseOffsetY) / scale));
      }
    }
  }
  
  public void keyEvent(KeyEvent event)
  {
    if ( (event.getAction() == KeyEvent.RELEASE) && (event.getKey() == settingsKey) )
    {
      if (editing)
        endEditing();
      else
        startEditing();
    }
  }
  
  public void startEditing()
  {
    editing = true;
    polygon.clear();
  }
  
  public void endEditing()
  {
    editing = false;
    savePolygon();
    updateMask();  
  }
  
  public void draw()
  {
    if (editing)
    {  
      noStroke();
      fill(255);
      beginShape();
      for (PVector v: polygon)
      {
        vertex(v.x, v.y);
      }
      endShape();
    }
  }
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "WinterWonderWall" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}

/*

Notes:
  - 123 MB (default) is too little. Increase to 1024 MB to be on the safe side.
  
*/

import java.util.*;
import java.util.concurrent.*;

import processing.video.*;

boolean demoMode = true;

// Midi controllers:
// BCF2000, preset 10
final static int CONTROL_SNOW          = 81; // amount of new snowflakes
final static int CONTROL_STORM         = 82; // amount of stormyness + double speed + more new snowflakes
final static int CONTROL_PEOPLE        = 83; // fade people in from the middle. NB slows framerate.
final static int CONTROL_ADD_AMOUNT    = 84;
final static int CONTROL_BLEND_MODE    = 85;
final static int CONTROL_JESUS         = 86;
final static int CONTROL_BACKGROUND    = 87; // aid to see when drawing masks
final static int CONTROL_FADE_TO_BLACK = 88;

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
final static int CONTROL_JESUS = 53;
final static int CONTROL_SNOW = 54; // amount
final static int CONTROL_STORM = 55; // amount of stormyness + double speed
final static int CONTROL_BACKGROUND = 59; // aid to see when drawing masks
final static int CONTROL_FADE_TO_BLACK = 60;
*/

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

int width = 700;
int height = 525;

PGraphics layer;
PGraphics blackOverlay;

PolygonMask wallMask;
PolygonMask jesusMask;

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

void setup()
{
  width = 1400;
  height = 1050;
  frame.setBackground(new java.awt.Color(0, 0, 0)); // startup color
  size(width, height, P2D);
  background(0);
  frameRate(60);

  MidiBus.list();
  // Open Midi input device
  // midi = new MidiBus(this, "MPK mini", -1);
  // midi = new MidiBus(this, 4, 4);
  midi = new MidiBus(this, 0, 0);

  for (int i=0; i<128; i++)
  {
    midiValues[i] = 0;
    midiState[i] = false;
  }

  messages = new ConcurrentLinkedQueue<MidiMessage>();
  
  wallMask = new PolygonMask("WallMask.txt", width, height, 20, true, 'w');
  jesusMask = new PolygonMask("JesusMask.txt", width, height, 5, false, 'j');
  
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
}

void draw()
{
  handleMidiMessages();
  
  float time = getTime();
  float dt = getDeltaTime(time);  
  
  layer.beginDraw();
  float backgroundGrey = midiValues[CONTROL_BACKGROUND];
  layer.background(backgroundGrey);
   
  layer.tint(255);
  layer.imageMode(CENTER);
  
  if ( (moviePlaying || moviePaused) && movieFrameReady)
    layer.image(movie, width / 2, height / 2, movieWidth, movieHeight);

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
  //particleSystem.stormyness = mouseX / 2;
  
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
  
  layer.tint(255, midiValues[CONTROL_JESUS] * tintScale);
  layer.image(jesusMask.mask, 0, 0);
  layer.tint(255, 255);

  if (midiValues[CONTROL_FADE_TO_BLACK] > 4)
  {
    layer.tint(255, midiValues[CONTROL_FADE_TO_BLACK]);
    layer.image(blackOverlay, 0, 0);
    layer.tint (255, 255);
  }

  layer.endDraw();

  if (demoMode)
  {
    // draw background image
    blendMode(BLEND);
    imageMode(CORNER);
    tint(255);
    image(wall, 0, 0, width, height);
    blendMode(MULTIPLY);
  }
  
  imageMode(CORNER);
  image(layer, 0, 0);

  if (demoMode)
  {
    // add some white on top
    blendMode(ADD);
    imageMode(CORNER);
    tint(60);
    image(layer, 0, 0);
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
  // println("Midi Controller - Channel: " + channel + ", number: " + number + ", value: " + value);
  midiValues[number] = floor((float)value *2.00787401574803); // Range: 0..255    (255/127)
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
    if (message.onOff)
      handleNoteOn(0, message.note, message.velocity);
    else
      handleNoteOff(0, message.note, message.velocity);

    message = messages.poll();
  }
}

void handleNoteOn(int channel, int note, int velocity) 
{
  //println("Note on: " + note);
  midiState[note] = true;
  
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
  for (int i = NOTE_BETLEHEM; i<= NOTE_CLEAR_SKYLINE; i++)
  {
    midi.sendNoteOn(0, i, 0);
    midi.sendNoteOff(0, i, 0);
    midiState[i] = false;
  }

  for (int i = CONTROL_SNOW; i<= CONTROL_FADE_TO_BLACK; i++)
  {
    midi.sendControllerChange(0, i, 0);
  }
}

void updateSkyline(boolean clearAllAndDropSnow)
{
  if (clearAllAndDropSnow)
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
    midiState[NOTE_BETLEHEM] = false;
    midiState[NOTE_SHEPHERDS] = false;
    midiState[NOTE_KINGS] = false;
    midiState[NOTE_FAMILY] = false;
    midiState[NOTE_PEOPLE] = false;
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
  println("9");

}

void keyPressed()
{
  if (key == 't')
  {
    print("t");
    skyline.beginDraw();
    skyline.tint(255);
    skyline.background(0);
    skyline.endDraw();
    // particleSystem.setSkyline(skyline, new PVector(0, 0));
    particleSystem.updateSkyline();
    particleSystem.unfreezeAll();  
  }
  if (key == 'y')
  {
    print("y");
    int h = (int)getHeightFromWidth(betlehem.width, betlehem.height, skyline.width) ;
    skyline.beginDraw();
    skyline.copy(betlehem, 0, 0, betlehem.width, betlehem.height, 0, 2*height/3 - h/2, skyline.width, h);
    skyline.endDraw();
    particleSystem.setSkyline(skyline, new PVector(0, 0));
  }
  if (key == 'm')
  {
    movieStartPause();
  }
  if (key == 's')
  {
    movieStop();
  }
}






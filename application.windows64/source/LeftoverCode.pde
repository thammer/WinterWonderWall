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

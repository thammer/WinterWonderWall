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
    updateSkyline();    
  }
  
  void updateSkyline()
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
  
  void draw()
  {
    imageMode(CENTER);
    for (Particle particle: particles)
    {
      if ( (!invisibleSnow) || (invisibleSnow && particle.frozen))
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
  
  private void applyForce(Particle particle)
  {
    //if (stormyness <= 4)
    //  return;
      
    float scale = (float)stormyness / 255.0;
    float sign = particle.position.z < 0 ? -1.0 : 1.0;

    float phase = 400.0 * sin (accumulatedTime / 5.0 * 2 * PI) + random(-30, 30);
    float amp = scale * 100.0;
    float wavelength = 600 + 400 * sin(accumulatedTime / 10.0 * 2 * PI);
    PVector f = new PVector(
      amp * sign * sin((particle.position.x + phase) / wavelength * 2 * PI), 
      amp * 0.5 * ( 0.2 + cos((particle.position.x + phase) / wavelength * 2 * PI)));
    particle.setForce(f);
    particle.velocityBlend = 1.0 - scale;
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
  
  boolean lessThan(PVector v1, PVector v2)
  {
    return (v1.x < v2.x) && (v1.y < v2.y);
  }
  
  boolean greaterThan(PVector v1, PVector v2)
  {
    return (v1.x > v2.x) && (v1.y > v2.y);
  }
}


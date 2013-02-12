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
  
  void setVelocity(PVector velocity)
  {
    this.velocity = velocity.get();
    this.initialVelocity = velocity.get();
  }
  
  void setForce(PVector force)
  {
    this.acceleration = force.get();
  }  
  
  void applyForce(PVector force)
  {
    this.acceleration.add(force);
  }
  
  void update(float dt)
  {
    if (frozen)
      return;
    // dp = v * dt
    PVector v = PVector.add( PVector.mult(initialVelocity, velocityBlend), PVector.mult(velocity, 1.0 - velocityBlend) );
    PVector dp = PVector.mult(v, dt);
    this.position.add(dp);
    // dv = a * dt
    PVector dv = PVector.mult(this.acceleration, dt);
    this.velocity.add(dv);
    //println("dt = " + dt + ", dp = " + dp + ", dv = " + dv);
    life = life - dt;
  }
  
  void draw()
  {
    // tint(life/100.0*255);
    layer.image(this.image, position.x, position.y);
  }
  
  boolean isDead()
  {
    if (useLife && (life <= 0))
      dead = true;
    return dead;
  }
  
  boolean isFrozen()
  {
    return frozen;
  }
}

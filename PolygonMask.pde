public class PolygonMask
{
  PGraphics mask;
  ArrayList<PVector> polygon;
  String filename;
  int width;
  int height;
  float blurRadius;
  boolean inverse;
  char settingsKey;
  
  boolean editing = false;
  
  PolygonMask(String filename, int width, int height, float blurRadius, boolean inverse, char settingsKey)
  {
    this.filename = filename;  
    this.width = width;
    this.height = height;
    this.blurRadius = blurRadius;
    this.inverse = inverse;
    this.settingsKey = settingsKey;
    
    mask = createGraphics(width, height);
    polygon = new ArrayList<PVector>();    
    
    registerMouseEvent(this);
    registerKeyEvent(this);
    registerDraw(this);
    
    loadPolygon();
    updateMask();
  }
  
  void savePolygon()
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
  
  boolean loadPolygon()
  {
    String[] lines = loadStrings(filename);
    if (lines == null)
      return false;
      
    for (int i=0; i<lines.length; i++)
    {
      String[] strings = split(lines[i], "\t");
      PVector vec = new PVector(float(strings[0]), float(strings[1]));
      polygon.add(vec);
    }
    
    return true;
  }
  
  void updateMask()
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
      mask.vertex(v.x, v.y);
    }
    mask.endShape();
  
    mask.endDraw();
    
    if (blurRadius > 0)
      mask.filter(BLUR, blurRadius);
    
    mask.loadPixels();
    for (int i=0; i<mask.pixels.length; i++)
    {
      color pixel = mask.pixels[i];
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
 
  void createEllipticalMask()
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
      color pixel = mask.pixels[i];
      mask.pixels[i] = color(0, 0, 0, 255 - red(pixel));
    }
    mask.updatePixels();
  }
  

  void mouseEvent(MouseEvent event)
  {
    if (event.getID() == MouseEvent.MOUSE_CLICKED)
    {
      if (editing)
      {
        polygon.add(new PVector(mouseX, mouseY));
      }
    }
  }
  
  void keyEvent(KeyEvent event)
  {
    if ( (event.getID() == KeyEvent.KEY_RELEASED) && (event.getKeyChar() == settingsKey) )
    {
      if (editing)
        endEditing();
      else
        startEditing();
    }
  }
  
  void startEditing()
  {
    editing = true;
    polygon.clear();
  }
  
  void endEditing()
  {
    editing = false;
    savePolygon();
    updateMask();  
  }
  
  void draw()
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

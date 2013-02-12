
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
  
  void wipeImage(float wipe)
  {
    wipedImage.beginDraw();
    wipedImage.image(image, 0, 0);
    wipedImage.fill(0);
    wipedImage.stroke(0);
    if (origin == ORIGIN_LEFT)
      wipedImage.rect(0, 0, wipe / 255.0 * image.width, image.height);
    else if (origin == ORIGIN_RIGHT)
      wipedImage.rect( (255 - wipe) / 255.0 * image.width, 0, image.width, image.height);
    else if (origin == ORIGIN_TOP)
      wipedImage.rect( 0, 0, image.width, wipe / 255.0 * image.height);
    else if (origin == ORIGIN_BOTTOM)
      wipedImage.rect( 0, (255 - wipe) / 255.0 * image.height, image.width, image.height);
    wipedImage.endDraw();
  }
  
  PImage getImage()
  {
    return wipedImage;
  }
}


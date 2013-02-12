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


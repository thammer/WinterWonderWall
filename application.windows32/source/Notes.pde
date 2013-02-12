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

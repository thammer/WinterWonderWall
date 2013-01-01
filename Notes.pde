/*

Next:
-v In present mode, use full screen size, but scale masks and images to 
  match actual resolution according to designWidth/designHeight,
  and position layer in the middle - effectively drawing over the
  "stop" text in lower left corner.
- Make masks resolution independant
  - Not sure about this. Images, like carpet, are not (and should not be) 
    scaled, and masks would then not match images.
  - Perhaps we should support resolution independence, but not aspect 
    ratio independence. This would work in development mode and in 
    present mode.
  - When defining mask, get position relative to layer, not relative to sketch 
    (in case width is different)
-x Support widescreen format
  - No, presentation should have the same aspect ratio independent of
    resolution.
- Control panel in second window
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


Controller library:
- easily create one value or one state which
  - can be controlled by midi, osc, keyboard and ControlP5 panel
- Study the P5 samples first!
  
*/

/*

Next:
- ikke skygge under konger v snow, kanskje egen knapp for dette
- fade inn stjerner
- fade inn andre figurer
  - familie
  - konger fra siden a la people left right
-v Midi support, fade in/out, snow more or less, etc
-v load alterteppe as background, for debugging
-v Mappe opp midi-controller BCF2000
-v playback video
  -v resize to 1400 x 1050 and don't resize in code
  -v check aspect ratio, original was 1920x1080 = 1.7777 : 1, 1400:1050 = 1.333:1
  -v start/stopp video fra MIDI-controller (eller taster)
-v Skyline on and off via MIDI, with different images
  -v alle de ulike figurene
  -x definere en baseline høyde som enkelt kan flyttes programmatisk, som figurene posisjoneres i forhold til ????
-v Snow
  -v midi controls snow amount
  -v snow storm
    -v when  snowyness approaches 0 again, speed should approach initial speed
  -x velocity jitter random perlin
  -v invisible snow
-v Jesus outline (polygon, but not inverse)
  -v file storage, define interactively
  -v fade in with MIDI
-v background dark grey when drawing polygon outlines
  (probably a separate fader or on/off button)
-x Flowers (series of points with x and y radius)
  -x file storage, define interactively
  -x fade in flowers with midi slider
  -> This didn't work so well, the flowers wern't that recognizable
-v Get scanned skyline + other stuff to snow on
-v scan 3 wise men
-v scan jesus, maria, joseph
-x Freezed snow flakes not looped over, freeze and unfreeze as methods on particle system
   This will improve memory usage.
- Stars tinkle
  - small stars
  - one big star
  - fader fades in small and big star
-x Snow on vertical lines
- Cross outline (lineset stored in text file)

-v betlehem lenger ned

-v Mitt hjerte video
  -v start video on cue (midi key start)
  -v stop video on cue
  -v restart possible
  -v last frame hold
  -x fade video (slider)
  -x perhaps fade up red heart, use polygonmask or a bitmap image that matches (probably better with image)
  -x or pulsate heart when button pressed, dunk-dunk at end ofbeat
  
Scaling of Mitt Hjerte video:
- 1920 x 1080 -> 1.777777 : 1
- 1400 x 1050 -> 1.333333 : 1


Intro
- bittelitt snø

Strålende, skinnende jul
- Snø, ikke storm

Nå vandrer fra hver en verdens krok
- mennesker fades freem gradvis fra midten

Joy to the world
- ikke noe

Det lyser i stille grender
- ikke noe

Når det lider mot jul
- Stjerner blinker

Mitt hjerte
- Video

Div

Jul, jul, strålande jul
- Betlehem begynner å snø frem på slutten

I denna natt
- snø på betlehem
- etterhvert på hyrder og så konger
- til slutt på familien

You'll never walk alone
- snøstorm
- til slutt stilner stormen og jesus lyser frem

  
*/

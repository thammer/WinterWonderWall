# WinterWonderWall #

![](http://thammer.net/wp-content/uploads/2013/02/www-slider-512.jpg)

WinterWonderWall is a live visual performance created by Kari Tonette Andreassen and [Thomas Hammer](http://www.thammer.net) for a Christmas concert with the [KorX](http://www.korx.net) in "Sondre Slagen Kirke" (Sondre Slagen Church, Tonsberg, Norway) December 2012.

The live visuals were projected on the end wall in the church, which is approximately 
20 meters wide and 20 meters tall, a white stone wall with a [beautiful woven altarpiece](https://www.google.com/search?hl=en&q=søndre+slagen+kirke&um=1&tbm=isch).

## Credits ##

- Hand-drawn images and animations by Kari Tonette Hammer
- Programming by Thomas Hammer
- Design and script by Kari Tonette and Thomas Hammer

## System requirements ##

The sketch requires [Processing v2.0b7](http://www.processing.org) and will not run on earlier versions of Processing.

The sketch has been tested on a laptop running Windows 7 x64 and on a MacBook Pro (early 2011) running OSX 10.6.

Before running the sketch from within the Processing environment, make sure you increase the memory allocated to the sketch, as the default 123 MB is too little.

The recommended memory to allocate is 512 MB. In the Processing environment, do File | Preferences | Increase maximum available memory to 512 MB.

## Usage ##

By default, the sketch runs in demo-mode, with one standard (not fullscreen) window showing the main sketch and one window with controllers. The light is projected on a picture of a vowen altar piece.

The sketch can also run in normal (presenter) mode, fullscreen, controlled either by a MIDI controller or by the keyboard. The image of the altar piece is not used when in this mode, as the altar piece is already on the wall IRL.

When setting up the performance for the first time, the masks needs to be set correctly according to the projector position in relation to the wall and the altar piece. Hit the "P" key to define the black outline wall mask, click around the outline of the wall, and hit "P" again to save the mask. Hit the "L" key to define the white overline mask (used for the light on Jesus on the altar piece), click around the outline of the Jesus figure, and hit "L" again to save the mask. When defining masks, it might be helpful to show a little bit of the global white light overlay (MIDI CC 87 or keyboard "6 Y H N").

## MIDI control ##

Continous controllers:

- CC 81   Snow amount
- CC 82   Storm amount
- CC 83   People fade in from center
- CC 86   White overlay (Jesus) fade in
- CC 87   Globel white overlay (for debugging)
- CC 88   Black fade in

Skylines (the snow falls on skylines):

- Note 61 Toggle Betlehem
- Note 62 Toggle Shepherds
- Note 63 Toggle Kings
- Note 64 Toggle Family
- Note 65 Toggle People
- Note 67 Toggle Invisible snow
- Note 68 On     Clear skyline and drop snow

Movie:

- Note 71 On Movie start / pause
- Note 72 On Movie stop

## Keyboard control ##

Continous controllers:

-  1 Q A Z   Snow amount, 1 = 255 (max), Q = increase value, A = decrease value, Z = 0 (min)
-  2 W S X   Storm amount
-  3 E D C   People fade in from center
-  4 R F V   White overlay (Jesus) fade in
-  5 T G B   Black fade in
-  6 Y H N   Global white overlay (for debugging)

Skylines (the snow falls on skylines):

-  F1   Betlehem
-  F2   Shepherds
-  F3   Kings
-  F4   Family
-  F5   People
-  F6   Invisible snow
-  F7   Clear skyline and drop snow

Movie:

-  F8   Movie start / pause
-  F9   Movie stop

Setup:

-  P   Define black wall mask
-  L   Define white overlay mask

## License ##

WinterWonderWall consists of hand-drawn images, a video, and source code (a "sketch") written in the [Processing programming language](http://www.processing.org).

You are free to use the sketch in public performances. If there is a natural place to give credits, during the performance or in a written program or similar, we would appreciate if you give credits to our work, for instance with a statement like "... based on WinterWonderWall by Kari Tonette and Thomas Hammer from www.thammer.net". We would also appreciate being informed of the performance. If you send us a few lines of text and a photo of the performance, we'll include it on the project page at www.thammer.net.  
 
The hand-drawn images and video, created by Kari Tonette Hammer, is licensed under a [Creative Commons Attribution-NonCommercial-NoDerivs 3.0 license](http://creativecommons.org/licenses/by-nc-nd/3.0/).

The sketch uses [themidibus](http://www.smallbutdigital.com/themidibus.php), which is licensed under a GPL license, and [controlP5](http://www.sojamo.de/libraries/controlP5/), which is licensed under a GNU LGPL license.

The source code for the sketch is licensed under a MIT license.

Copyright (C) 2012-2013 Thomas Hammer and Kari Tonette Hammer

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


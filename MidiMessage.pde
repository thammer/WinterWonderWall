class MidiMessage
{
  boolean onOff;
  int note;
  int velocity;
  
  MidiMessage(boolean onOff, int note, int velocity)
  {
    this.onOff = onOff;
    this.note = note;
    this.velocity = velocity;
  }
}


class MidiMessage
{
  boolean isNote;
  boolean isCC;
  
  boolean onOff;
  int note;
  int velocity;
  int cc;
  int ccValue;
  
  MidiMessage(boolean onOff, int note, int velocity)
  {
    this.isNote = true;
    this.isCC = false;
    this.onOff = onOff;
    this.note = note;
    this.velocity = velocity;
  }

  MidiMessage(int cc, int value)
  {
    this.isNote = false;
    this.isCC = true;
    this.cc = cc;
    this.ccValue = value;  
  }
}


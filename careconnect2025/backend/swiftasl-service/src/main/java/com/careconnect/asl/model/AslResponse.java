package com.careconnect.asl.model;
import java.util.List;

public class AslResponse {
  private boolean available;
  private String mode; // "video" or "fingerspell"
  private List<AslFrame> frames;
  private String caption;

  public AslResponse(){}
  public AslResponse(boolean available, String mode, List<AslFrame> frames, String caption){
    this.available=available; this.mode=mode; this.frames=frames; this.caption=caption;
  }
  public boolean isAvailable(){ return available; } public void setAvailable(boolean b){ this.available=b; }
  public String getMode(){ return mode; } public void setMode(String m){ this.mode=m; }
  public List<AslFrame> getFrames(){ return frames; } public void setFrames(List<AslFrame> f){ this.frames=f; }
  public String getCaption(){ return caption; } public void setCaption(String c){ this.caption=c; }
}

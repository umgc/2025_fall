package com.careconnect.asl.model;
public class AslFrame {
  private String type; // "sign"
  private String id;   // e.g., APPOINTMENT
  private String url;  // asset://asl/phrases/appointment.mp4
  public AslFrame(){}
  public AslFrame(String type,String id,String url){ this.type=type; this.id=id; this.url=url; }
  public String getType(){ return type; } public void setType(String s){ this.type=s; }
  public String getId(){ return id; } public void setId(String s){ this.id=s; }
  public String getUrl(){ return url; } public void setUrl(String s){ this.url=s; }
}

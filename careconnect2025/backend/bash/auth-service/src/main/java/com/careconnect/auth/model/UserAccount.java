package com.careconnect.auth.model;
import java.util.List;

public class UserAccount {
  public String email;
  public String passwordHash;
  public List<String> roles;
  public UserAccount(String email, String passwordHash, List<String> roles){
    this.email=email; this.passwordHash=passwordHash; this.roles=roles;
  }
}

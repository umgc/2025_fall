package com.careconnect.auth.model;
public class AuthDtos {
  public static class Register { public String email; public String password; }
  public static class Login { public String email; public String password; }
  public static class Tokens { public String accessToken; public String refreshToken; }
}

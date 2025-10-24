package com.careconnect.auth.core;

import com.careconnect.auth.model.UserAccount;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.util.*;

@Service
public class AuthService {
  private final PasswordEncoder encoder;
  private final Map<String, UserAccount> users = new HashMap<>();
  private final Map<String, String> refreshIndex = new HashMap<>(); // refreshId -> email

  public AuthService(PasswordEncoder encoder){ this.encoder = encoder; }

  public void register(String email, String rawPw, List<String> roles){
    if (users.containsKey(email)) throw new RuntimeException("exists");
    users.put(email, new UserAccount(email, encoder.encode(rawPw), roles));
  }

  public boolean verify(String email, String rawPw){
    var u = users.get(email);
    return u != null && encoder.matches(rawPw, u.passwordHash);
  }

  public List<String> roles(String email){ return users.get(email).roles; }

  public String newRefresh(String email){
    String id = UUID.randomUUID().toString();
    refreshIndex.put(id, email);
    return id;
  }

  public String rotateRefresh(String oldId){
    String email = refreshIndex.remove(oldId);
    if (email == null) throw new RuntimeException("invalid refresh");
    return newRefresh(email);
  }

  public void revokeRefresh(String id){ refreshIndex.remove(id); }

  public Optional<String> emailForRefresh(String id){ return Optional.ofNullable(refreshIndex.get(id)); }
}

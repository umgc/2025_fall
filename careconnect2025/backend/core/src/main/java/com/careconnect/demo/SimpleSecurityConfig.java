package com.careconnect.demo;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.NoOpPasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;

import java.util.List;

@Configuration
public class SimpleSecurityConfig {

  @Bean
  public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
      .csrf(csrf -> csrf.disable())
      .cors(cors -> cors.configurationSource(req -> {
        var c = new CorsConfiguration();
        c.setAllowedOrigins(List.of("*"));
        c.setAllowedMethods(List.of("GET","POST","OPTIONS"));
        c.setAllowedHeaders(List.of("*"));
        return c;
      }))
      .authorizeHttpRequests(auth -> auth
        .requestMatchers("/health", "/actuator/**").permitAll()
        .requestMatchers(HttpMethod.GET, "/auth/me").authenticated()
        .requestMatchers("/notes/**", "/triggers/**", "/pii/**").authenticated()
        .anyRequest().authenticated()
      )
      .httpBasic(Customizer.withDefaults());
    return http.build();
  }

  @SuppressWarnings("deprecation") // demo only
  @Bean
  public static NoOpPasswordEncoder passwordEncoder() {
    return (NoOpPasswordEncoder) NoOpPasswordEncoder.getInstance();
  }

  @Bean
  public UserDetailsService users() {
    return new InMemoryUserDetailsManager(
      User.withUsername("patient").password("pass").roles("PATIENT").build(),
      User.withUsername("caregiver").password("pass").roles("CAREGIVER").build()
    );
  }
}

package com.careconnect.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.NoOpPasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

  @Bean
  public UserDetailsService users() {
    // demo only – ok for milestone demo
    return new InMemoryUserDetailsManager(
        User.withUsername("patient").password("pass").roles("PATIENT").build(),
        User.withUsername("caregiver").password("pass").roles("CAREGIVER").build(),
        User.withUsername("admin").password("pass").roles("ADMIN").build()
    );
  }

  @Bean
  @SuppressWarnings("deprecation")
  public static NoOpPasswordEncoder passwordEncoder() {
    return (NoOpPasswordEncoder) NoOpPasswordEncoder.getInstance();
  }

  @Bean
  public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.csrf(csrf -> csrf.disable())
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/auth/**", "/actuator/**").permitAll()
            .anyRequest().authenticated())
        .httpBasic(basic -> {}); // simple for demo
    return http.build();
  }
}

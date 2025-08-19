package com.focusedai.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.client.SimpleClientHttpRequestFactory;

@Configuration
@ConfigurationProperties(prefix = "lambda")
public class ExecutionConfig {
    
    private String javaUrl;
    private String pythonUrl;
    private String javascriptUrl;
    private String cppUrl;
    private Timeout timeout = new Timeout();
    private Batch batch = new Batch();
    
    public static class Timeout {
        private int seconds = 90;
        
        public int getSeconds() { return seconds; }
        public void setSeconds(int seconds) { this.seconds = seconds; }
        
        public int getMilliseconds() { return seconds * 1000; }
    }
    
    public static class Batch {
        private Timeout timeout = new Timeout();
        
        public static class Timeout {
            private int seconds = 300;
            
            public int getSeconds() { return seconds; }
            public void setSeconds(int seconds) { this.seconds = seconds; }
            
            public int getMilliseconds() { return seconds * 1000; }
        }
        
        public Timeout getTimeout() { return timeout; }
        public void setTimeout(Timeout timeout) { this.timeout = timeout; }
    }
    
    @Bean("executionRestTemplate")
    public RestTemplate executionRestTemplate() {
        RestTemplate restTemplate = new RestTemplate();
        
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(timeout.getMilliseconds());
        factory.setReadTimeout(timeout.getMilliseconds());
        restTemplate.setRequestFactory(factory);
        
        return restTemplate;
    }
    
    // Getters and setters
    public String getJavaUrl() { return javaUrl; }
    public void setJavaUrl(String javaUrl) { this.javaUrl = javaUrl; }
    
    public String getPythonUrl() { return pythonUrl; }
    public void setPythonUrl(String pythonUrl) { this.pythonUrl = pythonUrl; }
    
    public String getJavascriptUrl() { return javascriptUrl; }
    public void setJavascriptUrl(String javascriptUrl) { this.javascriptUrl = javascriptUrl; }
    
    public String getCppUrl() { return cppUrl; }
    public void setCppUrl(String cppUrl) { this.cppUrl = cppUrl; }
    
    public Timeout getTimeout() { return timeout; }
    public void setTimeout(Timeout timeout) { this.timeout = timeout; }
    
    public Batch getBatch() { return batch; }
    public void setBatch(Batch batch) { this.batch = batch; }
}
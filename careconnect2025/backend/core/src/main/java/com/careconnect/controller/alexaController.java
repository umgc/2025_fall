package com.careconnect.controller;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/alexa")
public class alexaController {
    @GetMapping("/hello")
    public String hello(){
        return "Notification 1. Appointment at 9 A.M. Notification 2. Meds ready.";
    }
}

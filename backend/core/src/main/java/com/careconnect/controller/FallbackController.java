package com.careconnect.controller;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.boot.web.servlet.error.ErrorController;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class FallbackController implements ErrorController {

    @RequestMapping(value = "/error", produces = MediaType.TEXT_PLAIN_VALUE)
    public ResponseEntity<String> handleError(HttpServletRequest request) {
        Object statusAttr = request.getAttribute(RequestDispatcher.ERROR_STATUS_CODE);
        int status = (statusAttr instanceof Integer) ? (Integer) statusAttr : 404;

        String path = (String) request.getAttribute(RequestDispatcher.ERROR_REQUEST_URI);
        if (path == null) {
            path = request.getRequestURI();
        }

        if (status == HttpStatus.NOT_FOUND.value()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("No endpoint found for path: " + path);
        }
        return ResponseEntity.status(status).body("Error " + status + " for path: " + path);
    }
}

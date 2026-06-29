package com.djogana.ticketing.api.config;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import jakarta.servlet.http.HttpServletRequest;

import com.djogana.ticketing.api.contracts.Response;
import com.djogana.ticketing.api.service.FunctionalRollbackException;

@RestControllerAdvice
public class ApiExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ApiExceptionHandler.class);

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> handleNotReadable(HttpMessageNotReadableException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("status", HttpStatus.BAD_REQUEST.value());
        body.put("error", "Bad Request");
        body.put("message", "Corps JSON invalide ou incompatible. Utilisez : { \"data\": { ... } }.");
        Throwable cause = ex.getMostSpecificCause();
        if (cause != null && cause.getMessage() != null) {
            body.put("detail", cause.getMessage());
        }
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Map<String, Object>> handleMissingParam(MissingServletRequestParameterException ex, HttpServletRequest request) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", Instant.now().toString());
        body.put("status", HttpStatus.BAD_REQUEST.value());
        body.put("error", "Bad Request");
        body.put("path", request.getRequestURI());
        body.put("message", ex.getMessage());
        body.put("exception", ex.getClass().getName());
        body.put("parameterName", ex.getParameterName());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

  
    @ExceptionHandler(FunctionalRollbackException.class)
    public ResponseEntity<Response<?>> handleFunctionalRollback(FunctionalRollbackException ex) {
        Response<?> body = ex != null ? ex.getResponse() : null;
        HttpStatus status = (body != null && Boolean.TRUE.equals(body.isHasError()))
                ? HttpStatus.BAD_REQUEST
                : HttpStatus.OK;
        return ResponseEntity.status(status).body(body);
    }


    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleUncaught(Exception ex, HttpServletRequest request) {
        log.error("Unhandled exception for {}", request.getRequestURI(), ex);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", Instant.now().toString());
        body.put("status", HttpStatus.INTERNAL_SERVER_ERROR.value());
        body.put("error", "Internal Server Error");
        body.put("path", request.getRequestURI());
        String msg = ex.getMessage();
        body.put("message", msg != null && !msg.isEmpty() ? msg : ex.getClass().getSimpleName());
        body.put("exception", ex.getClass().getName());
        Throwable root = ex.getCause();
        if (root != null && root.getMessage() != null && !root.getMessage().equals(msg)) {
            body.put("cause", root.getMessage());
        }
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }
}

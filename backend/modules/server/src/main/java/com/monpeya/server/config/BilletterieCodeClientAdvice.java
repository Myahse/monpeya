package com.monpeya.server.config;

import java.lang.reflect.Type;

import org.springframework.core.MethodParameter;
import org.springframework.http.HttpInputMessage;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.RequestBodyAdviceAdapter;

import com.monpeya.shared.auth.CodeClientInjector;

@ControllerAdvice(basePackages = "com.djogana.ticketing")
public class BilletterieCodeClientAdvice extends RequestBodyAdviceAdapter {

    @Override
    public boolean supports(MethodParameter methodParameter, Type targetType,
            Class<? extends HttpMessageConverter<?>> converterType) {
        return true;
    }

    @Override
    public Object afterBodyRead(Object body, HttpInputMessage inputMessage, MethodParameter parameter,
            Type targetType, Class<? extends HttpMessageConverter<?>> converterType) {
        CodeClientInjector.injectFromRequest(body);
        return body;
    }
}

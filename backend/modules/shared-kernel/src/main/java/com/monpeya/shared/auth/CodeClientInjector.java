package com.monpeya.shared.auth;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

public final class CodeClientInjector {

    private CodeClientInjector() {
    }

    public static void injectFromRequest(Object body) {
        if (body == null) {
            return;
        }
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes == null) {
            return;
        }
        HttpServletRequest request = attributes.getRequest();
        Object codeClient = request.getAttribute(MonPeyaRequestAttributes.CODE_CLIENT);
        if (!(codeClient instanceof String resolved) || resolved.isBlank()) {
            return;
        }
        injectCodeClient(body, resolved);
    }

    private static void injectCodeClient(Object target, String codeClient) {
        if (target == null) {
            return;
        }
        if (trySetCodeClient(target, codeClient)) {
            return;
        }
        tryInjectNestedData(target, codeClient);
    }

    private static void tryInjectNestedData(Object target, String codeClient) {
        try {
            Method getData = target.getClass().getMethod("getData");
            Object data = getData.invoke(target);
            if (data != null) {
                injectCodeClient(data, codeClient);
            }
        } catch (ReflectiveOperationException ignored) {
            // not a Request<T> wrapper
        }
    }

    private static boolean trySetCodeClient(Object target, String codeClient) {
        try {
            Method getter = target.getClass().getMethod("getCodeClient");
            Object current = getter.invoke(target);
            if (current instanceof String existing && !existing.isBlank()) {
                return true;
            }
            Method setter = target.getClass().getMethod("setCodeClient", String.class);
            setter.invoke(target, codeClient);
            return true;
        } catch (ReflectiveOperationException ignored) {
            return trySetField(target, codeClient);
        }
    }

    private static boolean trySetField(Object target, String codeClient) {
        try {
            Field field = target.getClass().getDeclaredField("codeClient");
            field.setAccessible(true);
            Object current = field.get(target);
            if (current instanceof String existing && !existing.isBlank()) {
                return true;
            }
            field.set(target, codeClient);
            return true;
        } catch (ReflectiveOperationException ignored) {
            return false;
        }
    }
}

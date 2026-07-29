package com.monpeya.shared.auth;

import java.io.IOException;
import java.util.Set;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.springframework.http.MediaType;
import org.springframework.web.filter.OncePerRequestFilter;

import com.monpeya.backend.api.entity.MpSession;
import com.monpeya.backend.api.entity.MpUser;

public class MonPeyaBearerAuthFilter extends OncePerRequestFilter {

    private final MonPeyaSessionResolver sessionResolver;
    private final String pathPrefix;
    private final Set<String> publicPaths;

    public MonPeyaBearerAuthFilter(
            MonPeyaSessionResolver sessionResolver,
            String pathPrefix,
            Set<String> publicPaths) {
        this.sessionResolver = sessionResolver;
        this.pathPrefix = pathPrefix;
        this.publicPaths = publicPaths;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        if (!path.startsWith(pathPrefix)) {
            return true;
        }
        return publicPaths.contains(path);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        var session = sessionResolver.resolveBearer(request.getHeader("Authorization"));
        if (session.isEmpty()) {
            writeUnauthorized(response);
            return;
        }
        attachSession(request, session.get());
        filterChain.doFilter(request, response);
    }

    public static void attachSession(HttpServletRequest request, MpSession session) {
        request.setAttribute(MonPeyaRequestAttributes.SESSION, session);
        MpUser user = session.getUser();
        request.setAttribute(MonPeyaRequestAttributes.USER, user);
        if (user != null && user.getCodeClient() != null && !user.getCodeClient().isBlank()) {
            request.setAttribute(MonPeyaRequestAttributes.CODE_CLIENT, user.getCodeClient().trim());
        }
    }

    private static void writeUnauthorized(HttpServletResponse response) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write("""
                {"success":false,"message":"Session Mon Peya requise (Authorization: Bearer <token>)"}
                """);
    }
}

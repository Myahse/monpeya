package com.monpeya.server.config;

import java.util.Set;

import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;

import com.monpeya.shared.auth.MonPeyaBearerAuthFilter;
import com.monpeya.shared.auth.MonPeyaSessionResolver;

@Configuration
public class FilterConfig {

    private static final Set<String> IMMO_PUBLIC_PATHS = Set.of(
            "/api/immo/api/auth/login",
            "/api/immo/health");

    private static final Set<String> BILLETTERIE_PUBLIC_PATHS = Set.of(
            "/api/billetterie/v1/ping",
            "/api/billetterie/v1/events/public");

    @Bean
    FilterRegistrationBean<MonPeyaBearerAuthFilter> immoAuthFilter(MonPeyaSessionResolver sessionResolver) {
        FilterRegistrationBean<MonPeyaBearerAuthFilter> registration = new FilterRegistrationBean<>();
        registration.setFilter(new MonPeyaBearerAuthFilter(sessionResolver, "/api/immo/", IMMO_PUBLIC_PATHS) {
            @Override
            protected boolean shouldNotFilter(jakarta.servlet.http.HttpServletRequest request) {
                String path = request.getRequestURI();
                if (path.startsWith("/api/immo/api/biens/public/")) {
                    return true;
                }
                return super.shouldNotFilter(request);
            }
        });
        registration.addUrlPatterns("/api/immo/*");
        registration.setOrder(Ordered.HIGHEST_PRECEDENCE + 10);
        return registration;
    }

    @Bean
    FilterRegistrationBean<MonPeyaBearerAuthFilter> billetterieAuthFilter(MonPeyaSessionResolver sessionResolver) {
        FilterRegistrationBean<MonPeyaBearerAuthFilter> registration = new FilterRegistrationBean<>();
        registration.setFilter(new MonPeyaBearerAuthFilter(sessionResolver, "/api/billetterie/", BILLETTERIE_PUBLIC_PATHS));
        registration.addUrlPatterns("/api/billetterie/*");
        registration.setOrder(Ordered.HIGHEST_PRECEDENCE + 11);
        return registration;
    }
}

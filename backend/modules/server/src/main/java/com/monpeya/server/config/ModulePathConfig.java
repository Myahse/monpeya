package com.monpeya.server.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.PathMatchConfigurer;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class ModulePathConfig implements WebMvcConfigurer {

    @Value("${immo.upload.dir:uploads/immo}")
    private String uploadDir;

    @Override
    public void configurePathMatch(PathMatchConfigurer configurer) {
        configurer.addPathPrefix("/api/platform",
                clazz -> clazz.isAnnotationPresent(org.springframework.web.bind.annotation.RestController.class)
                        && clazz.getPackageName().startsWith("com.monpeya.backend"));
        configurer.addPathPrefix("/api/billetterie",
                clazz -> clazz.isAnnotationPresent(org.springframework.web.bind.annotation.RestController.class)
                        && clazz.getPackageName().startsWith("com.djogana.ticketing"));
        configurer.addPathPrefix("/api/immo",
                clazz -> clazz.isAnnotationPresent(org.springframework.web.bind.annotation.RestController.class)
                        && clazz.getPackageName().startsWith("com.monpeya.immo"));
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/api/immo/uploads/**")
                .addResourceLocations("file:" + uploadDir + "/");
    }
}

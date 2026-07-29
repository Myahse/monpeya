package com.monpeya.server;

import com.monpeya.backend.api.config.DotenvLoader;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.jdbc.autoconfigure.DataSourceAutoConfiguration;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;

import org.springframework.modulith.Modulith;

@SpringBootApplication(exclude = { DataSourceAutoConfiguration.class }, excludeName = {
        "org.springframework.boot.autoconfigure.session.SessionAutoConfiguration",
        "org.springframework.boot.r2dbc.autoconfigure.R2dbcAutoConfiguration",
        "org.springframework.boot.autoconfigure.data.r2dbc.R2dbcDataAutoConfiguration",
        "org.springframework.boot.autoconfigure.batch.BatchAutoConfiguration",
        "org.springframework.boot.batch.jdbc.autoconfigure.BatchJdbcAutoConfiguration",
        "org.springframework.boot.autoconfigure.ldap.LdapAutoConfiguration",
        "org.springframework.boot.autoconfigure.data.ldap.LdapRepositoriesAutoConfiguration"
})
@ComponentScan(basePackages = {
                "com.monpeya.backend",
                "com.djogana.ticketing",
                "com.monpeya.immo",
                "com.monpeya.shared",
                "com.monpeya.server" },
        excludeFilters = @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = {
                com.monpeya.backend.api.Application.class,
                com.djogana.ticketing.api.Application.class,
                com.monpeya.backend.api.config.SecurityConfig.class,
                com.djogana.ticketing.api.config.SecurityConfig.class,
                com.monpeya.backend.api.config.OpenApiConfig.class,
                com.djogana.ticketing.api.config.OpenApiConfig.class
        }))
@Modulith
public class MonPeyaServerApplication {

    public static void main(String[] args) {
        DotenvLoader.load();
        SpringApplication.run(MonPeyaServerApplication.class, args);
    }
}

package com.djogana.ticketing.api;

import com.djogana.ticketing.api.config.DotenvLoader;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(excludeName = {
	"org.springframework.boot.autoconfigure.session.SessionAutoConfiguration",
	"org.springframework.boot.r2dbc.autoconfigure.R2dbcAutoConfiguration",
	"org.springframework.boot.autoconfigure.data.r2dbc.R2dbcDataAutoConfiguration",
	"org.springframework.boot.autoconfigure.batch.BatchAutoConfiguration",
	"org.springframework.boot.batch.jdbc.autoconfigure.BatchJdbcAutoConfiguration",
	"org.springframework.boot.autoconfigure.ldap.LdapAutoConfiguration",
	"org.springframework.boot.autoconfigure.data.ldap.LdapRepositoriesAutoConfiguration"
})
public class Application {

	public static void main(String[] args) {
		DotenvLoader.load();
		SpringApplication.run(Application.class, args);
	}

}

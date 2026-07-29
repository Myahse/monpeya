package com.monpeya.backend.api;

import com.monpeya.backend.api.config.DotenvLoader;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {

	public static void main(String[] args) {
		DotenvLoader.load();
		SpringApplication.run(Application.class, args);
	}

}

package com.djogana.ticketing.api.config;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.github.cdimascio.dotenv.Dotenv;
import io.github.cdimascio.dotenv.DotenvEntry;

public final class DotenvLoader {

	private static final Logger log = LoggerFactory.getLogger(DotenvLoader.class);

	private DotenvLoader() {
	}

	public static void load() {
		Path envFile = resolveEnvFile();
		if (envFile == null) {
			log.info("No .env file found — using OS environment and application.properties only");
			return;
		}

		Dotenv dotenv = Dotenv.configure()
				.directory(envFile.getParent().toString())
				.filename(envFile.getFileName().toString())
				.ignoreIfMissing()
				.load();

		int applied = 0;
		for (DotenvEntry entry : dotenv.entries()) {
			String key = entry.getKey();
			String value = entry.getValue();
			if (key == null || key.isBlank() || value == null) {
				continue;
			}
			if (System.getenv(key) != null) {
				continue;
			}
			if (System.getProperty(key) != null) {
				continue;
			}
			System.setProperty(key, value);
			applied++;
		}
		log.info("Loaded {} entries from {}", applied, envFile.toAbsolutePath());
	}

	private static Path resolveEnvFile() {
		List<Path> candidates = List.of(
				Path.of(".env"),
				Path.of("ticketing", ".env"),
				Path.of("..", ".env"));
		for (Path candidate : candidates) {
			if (Files.isRegularFile(candidate)) {
				return candidate.normalize();
			}
		}
		return null;
	}
}

package com.monpeya.backend.api.config;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public final class DotenvLoader {

	private static final char DOUBLE_QUOTE = (char) 34;
	private static final char SINGLE_QUOTE = (char) 39;

	private static final Logger log = Logger.getLogger(DotenvLoader.class.getName());

	private DotenvLoader() {
	}

	public static void load() {
		Path envFile = resolveEnvFile();
		if (envFile == null) {
			log.info("No .env file found - using OS environment and application.properties only");
			return;
		}

		int applied = 0;
		try {
			List<String> lines = Files.readAllLines(envFile, StandardCharsets.UTF_8);
			for (String rawLine : lines) {
				String line = rawLine.trim();
				if (line.isEmpty() || line.startsWith("#")) {
					continue;
				}
				int eq = line.indexOf('=');
				if (eq <= 0) {
					continue;
				}
				String key = line.substring(0, eq).trim();
				String value = unquote(line.substring(eq + 1).trim());
				if (key.isEmpty() || value.isEmpty()) {
					continue;
				}
				// Prefer .env over blank OS env / blank system props (key may exist but be empty).
				String existingEnv = System.getenv(key);
				if (existingEnv != null && !existingEnv.isBlank()) {
					continue;
				}
				String existingProp = System.getProperty(key);
				if (existingProp != null && !existingProp.isBlank()) {
					continue;
				}
				System.setProperty(key, value);
				applied++;
			}
			// Mirror into Spring property names so @Value("peya.api.*") is not left empty
			// when ${PEYA_APP_ADMIN_*} resolved from a blank OS env var.
			copyIfPresent("PEYA_APP_ADMIN_USERNAME", "peya.api.admin-username");
			copyIfPresent("PEYA_APP_ADMIN_PASSWORD", "peya.api.admin-password");
			copyIfPresent("PEYA_API_BASE_URL", "peya.api.base-url");
			copyIfPresent("PEYA_CRYPTO_URL", "peya.api.crypto-url");
			copyIfPresent("PEYA_TOKEN_ENDPOINT", "peya.api.token-endpoint");
			copyIfPresent("PEYA_CODE_PAYS_RESIDENCE", "peya.api.code-pays-residence");
		} catch (IOException ex) {
			log.log(Level.WARNING, "Could not read " + envFile.toAbsolutePath() + ": " + ex.getMessage());
			return;
		}
		boolean hasAdmin = !isBlank(System.getProperty("peya.api.admin-username"))
				|| !isBlank(System.getProperty("PEYA_APP_ADMIN_USERNAME"));
		log.info("Loaded " + applied + " entries from " + envFile.toAbsolutePath()
				+ " (peya admin credentials " + (hasAdmin ? "present" : "MISSING") + ")");
	}

	private static void copyIfPresent(String fromKey, String toKey) {
		String value = System.getProperty(fromKey);
		if (isBlank(value)) {
			value = System.getenv(fromKey);
		}
		if (!isBlank(value)) {
			System.setProperty(toKey, value);
		}
	}

	private static boolean isBlank(String value) {
		return value == null || value.isBlank();
	}

	private static String unquote(String value) {
		if (value.length() < 2) {
			return value;
		}
		char first = value.charAt(0);
		char last = value.charAt(value.length() - 1);
		boolean doubleQuoted = first == DOUBLE_QUOTE && last == DOUBLE_QUOTE;
		boolean singleQuoted = first == SINGLE_QUOTE && last == SINGLE_QUOTE;
		if (doubleQuoted || singleQuoted) {
			return value.substring(1, value.length() - 1);
		}
		return value;
	}

	private static Path resolveEnvFile() {
		Path direct = Paths.get(".env");
		if (Files.isRegularFile(direct)) {
			return direct.normalize();
		}
		Path parentDir = Paths.get("..", ".env");
		if (Files.isRegularFile(parentDir)) {
			return parentDir.normalize();
		}
		return null;
	}
}

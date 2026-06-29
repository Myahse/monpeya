package com.djogana.ticketing.api.config;

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
                if (System.getenv(key) != null) {
                    continue;
                }
                if (System.getProperty(key) != null) {
                    continue;
                }
                System.setProperty(key, value);
                applied++;
            }
        } catch (IOException ex) {
            log.log(Level.WARNING, "Could not read " + envFile.toAbsolutePath() + ": " + ex.getMessage());
            return;
        }
        log.info("Loaded " + applied + " entries from " + envFile.toAbsolutePath());
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

package com.monpeya.immo.api.controller;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.monpeya.immo.api.contracts.ImmoEnvelope;

@RestController
@RequestMapping("/api/upload")
public class ImmoUploadController {

    private final Path uploadDir;

    public ImmoUploadController(@Value("${immo.upload.dir:uploads/immo}") String uploadDir) throws IOException {
        this.uploadDir = Path.of(uploadDir);
        Files.createDirectories(this.uploadDir);
    }

    @PostMapping(value = "/file", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, Object> upload(@RequestParam("file") MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            return ImmoEnvelope.error("Fichier requis");
        }
        String extension = extensionOf(file.getOriginalFilename());
        String filename = UUID.randomUUID() + extension;
        Path target = uploadDir.resolve(filename);
        Files.write(target, file.getBytes());
        String url = "/api/immo/uploads/" + filename;
        return ImmoEnvelope.item(Map.of("url", url, "item", url));
    }

    private static String extensionOf(String filename) {
        if (filename == null || !filename.contains(".")) {
            return ".jpg";
        }
        return filename.substring(filename.lastIndexOf('.'));
    }
}

package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Dto.SharedDto.ApiResponse;
import com.cloudinary.Cloudinary;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.UrlResource;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.*;
import java.util.*;

@RestController
@RequestMapping({"/api/Files", "/api/files"})
@Tag(name = "Archivos", description = "Upload y servicio de imágenes, audios y documentos de incidentes")
@SecurityRequirement(name = "bearerAuth")
public class FileUploadController {

    private static final Logger log = LoggerFactory.getLogger(FileUploadController.class);

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    @Value("${app.base-url:http://localhost:8080}")
    private String baseUrl;

    @Value("${CLOUDINARY_URL:}")
    private String cloudinaryUrl;

    private static final long MAX_SIZE_BYTES = 10L * 1024 * 1024; // 10MB

    private static final Set<String> ALLOWED_TYPES = Set.of(
            // Imágenes
            "image/jpeg", "image/png", "image/webp", "image/gif",
            // Audios de evidencia
            "audio/mpeg", "audio/mp3", "audio/wav", "audio/ogg", "audio/webm", "audio/mp4", "audio/x-m4a",
            // Documentos
            "application/pdf", "text/plain",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    );

    private Cloudinary initCloudinary() {
        String envUrl = System.getenv("CLOUDINARY_URL");
        if (envUrl != null && !envUrl.isBlank()) {
            return new Cloudinary(envUrl);
        }
        if (cloudinaryUrl != null && !cloudinaryUrl.isBlank()) {
            return new Cloudinary(cloudinaryUrl);
        }
        return null;
    }

    @PostMapping("/Upload")
    @Operation(summary = "Subir archivos de evidencia",
            description = "Sube hasta 5 archivos (imágenes, audios o docs). Almacena en Cloudinary (si está configurado) o en almacenamiento persistente local.")
    public ResponseEntity<ApiResponse<Map<String, Object>>> upload(
            @RequestParam("files") List<MultipartFile> files) throws IOException {

        if (files == null || files.isEmpty())
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Debes enviar al menos un archivo"));

        if (files.size() > 5)
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Máximo 5 archivos por incidente"));

        Path dir = Paths.get(uploadDir).toAbsolutePath().normalize();
        List<String> savedNames = new ArrayList<>();
        List<MultipartFile> acceptedFiles = new ArrayList<>();
        List<String> extensions = new ArrayList<>();
        for (MultipartFile file : files) {
            if (file.isEmpty()) continue;

            if (file.getSize() > MAX_SIZE_BYTES)
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("El archivo '" + file.getOriginalFilename() + "' supera los 10MB"));

            String contentType = file.getContentType();
            if (contentType == null || !ALLOWED_TYPES.contains(contentType))
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Tipo de archivo no permitido: " + contentType));

            if (!matchesContentType(file, contentType))
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("El contenido no coincide con su tipo de archivo"));

            acceptedFiles.add(file);
            extensions.add(extensionFor(contentType));
        }

        if (acceptedFiles.isEmpty())
            return ResponseEntity.badRequest().body(ApiResponse.error("No se recibieron archivos válidos"));

        Files.createDirectories(dir);
        List<String> urls = new ArrayList<>();
        Cloudinary cloudinary = initCloudinary();

        try {
            for (int i = 0; i < acceptedFiles.size(); i++) {
                MultipartFile file = acceptedFiles.get(i);
                boolean uploadedToCloud = false;

                if (cloudinary != null) {
                    try {
                        Map<?, ?> uploadResult = cloudinary.uploader().upload(
                                file.getBytes(),
                                Map.of(
                                        "folder", "cartagena_segura",
                                        "resource_type", "auto"
                                )
                        );
                        String secureUrl = (String) uploadResult.get("secure_url");
                        if (secureUrl != null && !secureUrl.isBlank()) {
                            urls.add(secureUrl);
                            uploadedToCloud = true;
                            log.info("Archivo almacenado en Cloudinary CDN: {}", secureUrl);
                        }
                    } catch (Exception cloudEx) {
                        log.warn("Fallo al subir a Cloudinary, usando almacenamiento local de respaldo: {}", cloudEx.getMessage());
                    }
                }

                // Fallback local si Cloudinary no está configurado o falló
                if (!uploadedToCloud) {
                    String savedName = UUID.randomUUID() + extensions.get(i);
                    try (InputStream input = file.getInputStream()) {
                        Files.copy(input, dir.resolve(savedName));
                    }
                    savedNames.add(savedName);
                    urls.add(baseUrl + "/api/Files/" + savedName);
                }
            }
        } catch (IOException error) {
            for (String savedName : savedNames) {
                Files.deleteIfExists(dir.resolve(savedName));
            }
            throw error;
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("urls", urls);
        result.put("count", urls.size());

        return ResponseEntity.ok(ApiResponse.ok("Archivos subidos correctamente", result));
    }

    private boolean matchesContentType(MultipartFile file, String contentType) throws IOException {
        byte[] header;
        try (InputStream input = file.getInputStream()) {
            header = input.readNBytes(12);
        }
        return switch (contentType) {
            case "image/jpeg" -> header.length >= 3
                    && (header[0] & 0xFF) == 0xFF && (header[1] & 0xFF) == 0xD8
                    && (header[2] & 0xFF) == 0xFF;
            case "image/png" -> header.length >= 8
                    && (header[0] & 0xFF) == 0x89 && header[1] == 0x50
                    && header[2] == 0x4E && header[3] == 0x47
                    && header[4] == 0x0D && header[5] == 0x0A
                    && header[6] == 0x1A && header[7] == 0x0A;
            case "image/webp" -> header.length >= 12
                    && new String(header, 0, 4, java.nio.charset.StandardCharsets.US_ASCII).equals("RIFF")
                    && new String(header, 8, 4, java.nio.charset.StandardCharsets.US_ASCII).equals("WEBP");
            case "image/gif" -> header.length >= 6
                    && (new String(header, 0, 6, java.nio.charset.StandardCharsets.US_ASCII).equals("GIF87a")
                    || new String(header, 0, 6, java.nio.charset.StandardCharsets.US_ASCII).equals("GIF89a"));
            case "audio/wav" -> header.length >= 12
                    && new String(header, 0, 4, java.nio.charset.StandardCharsets.US_ASCII).equals("RIFF")
                    && new String(header, 8, 4, java.nio.charset.StandardCharsets.US_ASCII).equals("WAVE");
            case "audio/ogg" -> header.length >= 4
                    && new String(header, 0, 4, java.nio.charset.StandardCharsets.US_ASCII).equals("OggS");
            case "audio/mpeg", "audio/mp3" -> header.length >= 3
                    && ((header[0] == 'I' && header[1] == 'D' && header[2] == '3')
                    || ((header[0] & 0xFF) == 0xFF && (header[1] & 0xE0) == 0xE0));
            case "audio/webm" -> header.length >= 4
                    && (header[0] & 0xFF) == 0x1A && (header[1] & 0xFF) == 0x45;
            case "audio/mp4", "audio/x-m4a" -> header.length >= 8
                    && new String(header, 4, 4, java.nio.charset.StandardCharsets.US_ASCII).equals("ftyp");
            case "application/pdf" -> header.length >= 5
                    && new String(header, 0, 5, java.nio.charset.StandardCharsets.US_ASCII).equals("%PDF-");
            case "application/msword" -> header.length >= 4
                    && (header[0] & 0xFF) == 0xD0 && (header[1] & 0xFF) == 0xCF
                    && (header[2] & 0xFF) == 0x11 && (header[3] & 0xFF) == 0xE0;
            case "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ->
                    header.length >= 4 && header[0] == 0x50 && header[1] == 0x4B;
            case "text/plain" -> !containsNullByte(file);
            default -> true;
        };
    }

    private boolean containsNullByte(MultipartFile file) throws IOException {
        try (InputStream input = file.getInputStream()) {
            byte[] buffer = new byte[4096];
            int read;
            while ((read = input.read(buffer)) != -1) {
                for (int i = 0; i < read; i++) {
                    if (buffer[i] == 0) return true;
                }
            }
            return false;
        }
    }

    private String extensionFor(String contentType) {
        return switch (contentType) {
            case "image/jpeg" -> ".jpg";
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            case "image/gif" -> ".gif";
            case "audio/mpeg", "audio/mp3" -> ".mp3";
            case "audio/wav" -> ".wav";
            case "audio/ogg" -> ".ogg";
            case "audio/webm" -> ".webm";
            case "audio/mp4", "audio/x-m4a" -> ".m4a";
            case "application/pdf" -> ".pdf";
            case "text/plain" -> ".txt";
            case "application/msword" -> ".doc";
            case "application/vnd.openxmlformats-officedocument.wordprocessingml.document" -> ".docx";
            default -> ".bin";
        };
    }

    @GetMapping("/{filename:.+}")
    @Operation(summary = "Servir archivo", description = "Retorna el archivo almacenado. No requiere autenticación.")
    public ResponseEntity<org.springframework.core.io.Resource> serveFile(
            @PathVariable String filename) throws IOException {

        Path filePath = Paths.get(uploadDir).toAbsolutePath().normalize()
                .resolve(filename).normalize();

        // Seguridad: evitar path traversal
        if (!filePath.startsWith(Paths.get(uploadDir).toAbsolutePath().normalize()))
            return ResponseEntity.badRequest().build();

        UrlResource resource = new UrlResource(filePath.toUri());
        if (!resource.exists() || !resource.isReadable())
            return ResponseEntity.notFound().build();

        String contentType = Files.probeContentType(filePath);
        if (contentType == null) contentType = "application/octet-stream";

        return ResponseEntity.ok()
                .header("Content-Type", contentType)
                .header("Cache-Control", "public, max-age=31536000")
                .header("Content-Disposition", "inline; filename=\"" + filename + "\"")
                .body(resource);
    }
}
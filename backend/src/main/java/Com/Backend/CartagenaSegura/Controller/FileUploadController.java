package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Dto.SharedDto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.UrlResource;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;
import java.util.*;

@RestController
@RequestMapping("/api/Files")
@Tag(name = "Archivos", description = "Upload y servicio de imágenes y documentos de incidentes")
@SecurityRequirement(name = "bearerAuth")
public class FileUploadController {

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    @Value("${app.base-url:http://localhost:8080}")
    private String baseUrl;

    private static final long MAX_SIZE_BYTES = 10L * 1024 * 1024; // 10MB

    private static final Set<String> ALLOWED_TYPES = Set.of(
            "image/jpeg", "image/png", "image/webp", "image/gif",
            "application/pdf", "text/plain",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    );

    @PostMapping("/Upload")
    @Operation(summary = "Subir archivos de evidencia",
            description = "Sube hasta 5 archivos (imágenes/docs) y retorna las URLs públicas para guardar en el incidente.")
    public ResponseEntity<ApiResponse<Map<String, Object>>> upload(
            @RequestParam("files") List<MultipartFile> files) throws IOException {

        if (files == null || files.isEmpty())
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Debes enviar al menos un archivo"));

        if (files.size() > 5)
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Máximo 5 archivos por incidente"));

        Path dir = Paths.get(uploadDir).toAbsolutePath().normalize();
        Files.createDirectories(dir);

        List<String> urls = new ArrayList<>();

        for (MultipartFile file : files) {
            if (file.isEmpty()) continue;

            if (file.getSize() > MAX_SIZE_BYTES)
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("El archivo '" + file.getOriginalFilename() + "' supera los 10MB"));

            String contentType = file.getContentType();
            if (contentType == null || !ALLOWED_TYPES.contains(contentType))
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Tipo de archivo no permitido: " + contentType));

            String originalName = Optional.ofNullable(file.getOriginalFilename()).orElse("file");
            String ext = originalName.contains(".")
                    ? originalName.substring(originalName.lastIndexOf('.'))
                    : "";

            String savedName = UUID.randomUUID() + ext;
            Files.copy(file.getInputStream(), dir.resolve(savedName), StandardCopyOption.REPLACE_EXISTING);

            urls.add(baseUrl + "/api/files/" + savedName);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("urls", urls);
        result.put("count", urls.size());

        return ResponseEntity.ok(ApiResponse.ok("Archivos subidos correctamente", result));
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
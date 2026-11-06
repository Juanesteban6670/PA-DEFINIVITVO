package Com.Backend.CartagenaSegura.Controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertEquals;

class FileUploadControllerTest {

    @TempDir
    Path uploadDirectory;

    private FileUploadController controller;

    @BeforeEach
    void setUp() {
        controller = new FileUploadController();
        ReflectionTestUtils.setField(controller, "uploadDir", uploadDirectory.toString());
        ReflectionTestUtils.setField(controller, "baseUrl", "https://example.test");
    }

    @Test
    void acceptsWebpWithRiffAndWebpSignatures() throws Exception {
        byte[] webpHeader = {
                'R', 'I', 'F', 'F', 0, 0, 0, 0, 'W', 'E', 'B', 'P'
        };
        MockMultipartFile webp = new MockMultipartFile(
                "files", "evidence.webp", "image/webp", webpHeader
        );

        assertEquals(200, controller.upload(java.util.List.of(webp)).getStatusCode().value());
        try (var files = Files.list(uploadDirectory)) {
            assertEquals(1, files.filter(path -> path.getFileName().toString().endsWith(".webp")).count());
        }
    }

    @Test
    void rejectsContentWhoseSignatureDoesNotMatchDeclaredType() throws Exception {
        MockMultipartFile spoofedPng = new MockMultipartFile(
                "files", "evidence.png", "image/png", "not a png".getBytes()
        );

        assertEquals(400, controller.upload(java.util.List.of(spoofedPng)).getStatusCode().value());
        try (var files = Files.list(uploadDirectory)) {
            assertEquals(0, files.count());
        }
    }

    @Test
    void rejectsFilesLargerThanTenMegabytes() throws Exception {
        MockMultipartFile oversized = new MockMultipartFile(
                "files", "evidence.png", "image/png", new byte[10 * 1024 * 1024 + 1]
        );

        assertEquals(400, controller.upload(java.util.List.of(oversized)).getStatusCode().value());
    }
}

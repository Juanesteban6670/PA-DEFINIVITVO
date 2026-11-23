package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Repository.IncidentRepository;
import Com.Backend.CartagenaSegura.Service.EvidenceAccess;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.test.util.ReflectionTestUtils;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;

class FileUploadControllerTest {

    @TempDir
    Path uploadDirectory;

    private FileUploadController controller;
    private final UserDetails owner = User.withUsername("owner").password("unused").roles("CITIZEN").build();

    @BeforeEach
    void setUp() {
        controller = new FileUploadController();
        ReflectionTestUtils.setField(controller, "uploadDir", uploadDirectory.toString());
        ReflectionTestUtils.setField(controller, "baseUrl", "https://example.test");
        ReflectionTestUtils.setField(controller, "evidenceAccess",
                new EvidenceAccess(mock(IncidentRepository.class), null, uploadDirectory.toString(), false));
    }

    @Test
    void acceptsWebpWithRiffAndWebpSignatures() throws Exception {
        byte[] webpHeader = {
                'R', 'I', 'F', 'F', 0, 0, 0, 0, 'W', 'E', 'B', 'P'
        };
        MockMultipartFile webp = new MockMultipartFile(
                "files", "evidence.webp", "image/webp", webpHeader
        );

        assertEquals(200, controller.upload(java.util.List.of(webp), owner).getStatusCode().value());
        try (var files = Files.list(uploadDirectory)) {
            assertEquals(1, files.filter(path -> path.getFileName().toString().endsWith(".webp")).count());
        }
    }

    @Test
    void rejectsContentWhoseSignatureDoesNotMatchDeclaredType() throws Exception {
        MockMultipartFile spoofedPng = new MockMultipartFile(
                "files", "evidence.png", "image/png", "not a png".getBytes()
        );

        assertEquals(400, controller.upload(java.util.List.of(spoofedPng), owner).getStatusCode().value());
        try (var files = Files.list(uploadDirectory)) {
            assertEquals(0, files.count());
        }
    }

    @Test
    void rejectsFilesLargerThanTenMegabytes() throws Exception {
        MockMultipartFile oversized = new MockMultipartFile(
                "files", "evidence.png", "image/png", new byte[10 * 1024 * 1024 + 1]
        );

        assertEquals(400, controller.upload(java.util.List.of(oversized), owner).getStatusCode().value());
    }

    @Test
    void servesPrivateEvidenceToOwnerAndAdminOnly() throws Exception {
        var upload = new MockMultipartFile("files", "evidence.txt", "text/plain", "test".getBytes());
        controller.upload(java.util.List.of(upload), owner);
        String filename;
        try (var files = Files.list(uploadDirectory)) {
            filename = files.filter(path -> path.toString().endsWith(".txt")).findFirst().orElseThrow()
                    .getFileName().toString();
        }
        var stranger = User.withUsername("stranger").password("unused").roles("CITIZEN").build();
        var admin = User.withUsername("admin").password("unused").roles("ADMIN").build();

        assertEquals(404, controller.serveFile(filename, null).getStatusCode().value());
        assertEquals(404, controller.serveFile(filename, stranger).getStatusCode().value());
        assertEquals(404, controller.serveFile(filename + ".owner", owner).getStatusCode().value());
        assertEquals("private, no-store", controller.serveFile(filename, owner).getHeaders().getCacheControl());
        assertEquals(200, controller.serveFile(filename, admin).getStatusCode().value());
    }
}

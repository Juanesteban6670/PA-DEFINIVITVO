package Com.Backend.CartagenaSegura.Controller;

import com.cloudinary.Cloudinary;
import com.cloudinary.Uploader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.IOException;
import java.nio.file.Files;
import java.util.List;
import java.util.Map;
import static org.mockito.Mockito.*;
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
    void doesNotUseLocalDiskWhenRequiredCloudIsMissing() throws Exception {
        var guarded = spy(controller);
        doReturn(null).when(guarded).initCloudinary();
        ReflectionTestUtils.setField(guarded, "requireCloud", true);
        assertEquals(503, guarded.upload(List.of(evidence())).getStatusCode().value());
        try (var files = Files.list(uploadDirectory)) {
            assertEquals(0, files.count());
        }
    }

    @Test
    void rollsBackPartialCloudUploadAndDoesNotConfirmIt() throws Exception {
        var guarded = spy(controller);
        var cloud = mock(Cloudinary.class);
        var uploader = mock(Uploader.class);
        doReturn(cloud).when(guarded).initCloudinary();
        when(cloud.uploader()).thenReturn(uploader);
        when(uploader.upload(any(byte[].class), anyMap()))
                .thenReturn(Map.of("public_id", "qa/first", "resource_type", "raw",
                        "secure_url", "https://example.test/first"))
                .thenThrow(new IOException("provider unavailable"));
        ReflectionTestUtils.setField(guarded, "requireCloud", true);

        assertEquals(503, guarded.upload(List.of(evidence(), evidence())).getStatusCode().value());
        verify(uploader).destroy("qa/first", Map.of("resource_type", "raw"));
        try (var files = Files.list(uploadDirectory)) {
            assertEquals(0, files.count());
        }
    }

    private MockMultipartFile evidence() {
        return new MockMultipartFile("files", "evidence.txt", "text/plain", new byte[]{65});
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

package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Service.IncidentService;
import Com.Backend.CartagenaSegura.Service.PdfReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

@RestController
@RequestMapping("/api/Reports")
@PreAuthorize("hasAnyRole('ADMIN', 'OFFICER')")
@Tag(name = "Reportes (PDF)", description = "Generación de informes ejecutivos oficiales y boletines en PDF")
@SecurityRequirement(name = "bearerAuth")
public class ReportController {

    private final IncidentService incidentService;
    private final PdfReportService pdfReportService;

    public ReportController(IncidentService incidentService, PdfReportService pdfReportService) {
        this.incidentService = incidentService;
        this.pdfReportService = pdfReportService;
    }

    @GetMapping("/Pdf")
    @Operation(summary = "Descargar Informe Ejecutivo PDF",
            description = "Genera y descarga un documento PDF oficial con membrete de la Alcaldía de Cartagena y estadísticas consolidadas.")
    public ResponseEntity<byte[]> downloadExecutivePdf(
            @AuthenticationPrincipal UserDetails userDetails) {

        String user = userDetails != null ? userDetails.getUsername() : "ADMIN";
        List<Incident> incidents = incidentService.getAll();
        byte[] pdfBytes = pdfReportService.generateExecutiveReport(incidents, user);

        String date = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String filename = "Informe_Seguridad_Cartagena_" + date + ".pdf";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_PDF_VALUE)
                .body(pdfBytes);
    }

    @GetMapping("/Incident/{id}/Pdf")
    @Operation(summary = "Descargar Ficha Técnica de Incidente en PDF",
            description = "Genera un boletín individual oficial para archivo judicial o policial.")
    public ResponseEntity<byte[]> downloadIncidentPdf(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {

        String user = userDetails != null ? userDetails.getUsername() : "ADMIN";
        Incident incident = incidentService.getById(id);
        byte[] pdfBytes = pdfReportService.generateExecutiveReport(List.of(incident), user);

        String filename = "Ficha_Incidente_" + id.substring(0, Math.min(8, id.length())) + ".pdf";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_PDF_VALUE)
                .body(pdfBytes);
    }
}

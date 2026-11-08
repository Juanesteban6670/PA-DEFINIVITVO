package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Model.Incident;
import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class PdfReportService {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    public byte[] generateExecutiveReport(List<Incident> incidents, String generatedBy) {
        Document document = new Document(PageSize.A4, 36, 36, 40, 40);
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        try {
            PdfWriter.getInstance(document, out);
            document.open();

            // Colores Institucionales de Cartagena (Amarillo, Rojo, Verde)
            Color cartagenaRed = new Color(192, 41, 43);
            Color headerDark = new Color(26, 37, 48);
            Color tableHeaderBg = new Color(41, 128, 185);
            Color lightGray = new Color(245, 247, 250);

            // Fuentes
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 15, cartagenaRed);
            Font subTitleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, headerDark);
            Font bodyFont = FontFactory.getFont(FontFactory.HELVETICA, 8, Color.BLACK);
            Font boldFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8, Color.BLACK);
            Font headerFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8, Color.WHITE);
            Font metaFont = FontFactory.getFont(FontFactory.HELVETICA, 8, Color.DARK_GRAY);

            // 1. Encabezado Oficial
            Paragraph header = new Paragraph("ALCALDÍA MAYOR DE CARTAGENA DE INDIAS", titleFont);
            header.setAlignment(Element.ALIGN_CENTER);
            document.add(header);

            Paragraph sub = new Paragraph("DISTRITO TURÍSTICO Y CULTURAL — DISTRISEGURIDAD\nOBSERVATORIO DE SEGURIDAD Y CONVIVENCIA CIUDADANA", subTitleFont);
            sub.setAlignment(Element.ALIGN_CENTER);
            sub.setSpacingAfter(10);
            document.add(sub);

            // Línea divisoria
            Paragraph line = new Paragraph("_________________________________________________________________________________", boldFont);
            line.setAlignment(Element.ALIGN_CENTER);
            line.setSpacingAfter(12);
            document.add(line);

            // 2. Metadatos del Informe
            PdfPTable metaTable = new PdfPTable(2);
            metaTable.setWidthPercentage(100);
            metaTable.setSpacingAfter(15);

            PdfPCell cell1 = new PdfPCell(new Phrase("INFORME EJECUTIVO DE INCIDENTES Y MONITOREO TERRITORIAL", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, Color.BLACK)));
            cell1.setBorder(Rectangle.NO_BORDER);
            cell1.setColspan(2);
            cell1.setPaddingBottom(6);
            metaTable.addCell(cell1);

            PdfPCell cEmision = new PdfPCell(new Phrase("Fecha de emisión: " + LocalDateTime.now().format(DATE_FORMATTER), metaFont));
            cEmision.setBorder(Rectangle.NO_BORDER);
            metaTable.addCell(cEmision);

            PdfPCell cGenerado = new PdfPCell(new Phrase("Funcionario Responsable: " + generatedBy, metaFont));
            cGenerado.setBorder(Rectangle.NO_BORDER);
            metaTable.addCell(cGenerado);

            PdfPCell cTotal = new PdfPCell(new Phrase("Total incidentes analizados: " + incidents.size(), metaFont));
            cTotal.setBorder(Rectangle.NO_BORDER);
            metaTable.addCell(cTotal);

            PdfPCell cSistema = new PdfPCell(new Phrase("Plataforma: Cartagena Segura (PA-DEFINITIVO)", metaFont));
            cSistema.setBorder(Rectangle.NO_BORDER);
            metaTable.addCell(cSistema);

            document.add(metaTable);

            // 3. Resumen Estadístico Rápido
            long pending = incidents.stream().filter(i -> i.getStatus() == Incident.Status.PENDING).count();
            long inProgress = incidents.stream().filter(i -> i.getStatus() == Incident.Status.IN_PROGRESS).count();
            long resolved = incidents.stream().filter(i -> i.getStatus() == Incident.Status.RESOLVED).count();
            long critical = incidents.stream().filter(i -> i.getPriority() == Incident.Priority.CRITICAL || i.getPriority() == Incident.Priority.HIGH).count();

            PdfPTable statsTable = new PdfPTable(4);
            statsTable.setWidthPercentage(100);
            statsTable.setSpacingAfter(15);

            addStatBox(statsTable, "PENDIENTES", String.valueOf(pending), new Color(243, 156, 18));
            addStatBox(statsTable, "EN PROCESO", String.valueOf(inProgress), new Color(52, 152, 219));
            addStatBox(statsTable, "RESUELTOS", String.valueOf(resolved), new Color(46, 204, 113));
            addStatBox(statsTable, "ALTA / CRÍTICA", String.valueOf(critical), new Color(231, 76, 60));

            document.add(statsTable);

            // 4. Tabla Detallada de Incidentes
            PdfPTable table = new PdfPTable(6);
            table.setWidthPercentage(100);
            table.setWidths(new float[]{12, 14, 30, 16, 14, 14});
            table.setSpacingAfter(25);

            addTableHeader(table, "ID / Tipo", tableHeaderBg, headerFont);
            addTableHeader(table, "Prioridad", tableHeaderBg, headerFont);
            addTableHeader(table, "Ubicación / Detalle", tableHeaderBg, headerFont);
            addTableHeader(table, "Reportado Por", tableHeaderBg, headerFont);
            addTableHeader(table, "Estado", tableHeaderBg, headerFont);
            addTableHeader(table, "Fecha", tableHeaderBg, headerFont);

            boolean alt = false;
            for (Incident inc : incidents) {
                Color bg = alt ? lightGray : Color.WHITE;
                alt = !alt;

                String type = inc.getType() != null ? inc.getType() : "GENERAL";
                String shortId = inc.getId() != null && inc.getId().length() > 6 ? inc.getId().substring(0, 6) : "N/A";
                addTableCell(table, shortId + "\n" + type, boldFont, bg);

                String prio = inc.getPriority() != null ? inc.getPriority().name() : "MEDIA";
                addTableCell(table, prio, bodyFont, bg);

                String loc = (inc.getLocation() != null ? inc.getLocation() : "Sin ubicación especificada");
                if (loc.length() > 40) loc = loc.substring(0, 37) + "...";
                addTableCell(table, loc, bodyFont, bg);

                String rep = inc.getReportedBy() != null ? inc.getReportedBy() : "Anónimo";
                addTableCell(table, rep, bodyFont, bg);

                String st = inc.getStatus() != null ? inc.getStatus().name() : "PENDING";
                addTableCell(table, st, boldFont, bg);

                String dateStr = inc.getCreatedAt() != null ? inc.getCreatedAt().format(DATE_FORMATTER) : "N/D";
                addTableCell(table, dateStr, metaFont, bg);
            }

            document.add(table);

            // 5. Pie de Firma Oficial
            PdfPTable signTable = new PdfPTable(2);
            signTable.setWidthPercentage(100);
            signTable.setKeepTogether(true);

            PdfPCell sign1 = new PdfPCell(new Paragraph("\n\n_____________________________________\nComisario Distrital de Cartagena\nSecretaría del Interior y Convivencia", metaFont));
            sign1.setBorder(Rectangle.NO_BORDER);
            sign1.setHorizontalAlignment(Element.ALIGN_CENTER);

            PdfPCell sign2 = new PdfPCell(new Paragraph("\n\n_____________________________________\nComandante Operativo de Cuadrante\nPolicía Metropolitana de Cartagena", metaFont));
            sign2.setBorder(Rectangle.NO_BORDER);
            sign2.setHorizontalAlignment(Element.ALIGN_CENTER);

            signTable.addCell(sign1);
            signTable.addCell(sign2);

            document.add(signTable);

            document.close();
        } catch (DocumentException e) {
            throw new RuntimeException("Error al generar el documento PDF", e);
        }

        return out.toByteArray();
    }

    private void addStatBox(PdfPTable table, String title, String value, Color color) {
        PdfPCell cell = new PdfPCell();
        cell.setBackgroundColor(new Color(248, 249, 250));
        cell.setBorderColor(color);
        cell.setBorderWidth(1.5f);
        cell.setPadding(8);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);

        Paragraph pTitle = new Paragraph(title, FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8, color));
        pTitle.setAlignment(Element.ALIGN_CENTER);
        Paragraph pValue = new Paragraph(value, FontFactory.getFont(FontFactory.HELVETICA_BOLD, 14, Color.BLACK));
        pValue.setAlignment(Element.ALIGN_CENTER);

        cell.addElement(pTitle);
        cell.addElement(pValue);
        table.addCell(cell);
    }

    private void addTableHeader(PdfPTable table, String title, Color bg, Font font) {
        PdfPCell cell = new PdfPCell(new Phrase(title, font));
        cell.setBackgroundColor(bg);
        cell.setPadding(6);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        table.addCell(cell);
    }

    private void addTableCell(PdfPTable table, String text, Font font, Color bg) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setBackgroundColor(bg);
        cell.setPadding(5);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        table.addCell(cell);
    }
}

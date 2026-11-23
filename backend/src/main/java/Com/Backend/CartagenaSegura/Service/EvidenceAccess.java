package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Repository.IncidentRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.mongodb.gridfs.GridFsTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.regex.Pattern;

import static org.springframework.data.mongodb.core.query.Criteria.where;
import static org.springframework.data.mongodb.core.query.Query.query;

@Service
public class EvidenceAccess {

    public static final Pattern FILENAME = Pattern.compile("[a-f0-9-]{36}\\.[a-z0-9]+");
    private static final Pattern MANAGED_PATH = Pattern.compile("(?i)^/api/files/(.+)$");
    private final IncidentRepository incidents;
    private final GridFsTemplate gridFs;
    private final Path directory;
    private final boolean useMongo;

    public EvidenceAccess(IncidentRepository incidents, GridFsTemplate gridFs,
                          @Value("${app.upload.dir:uploads}") String directory,
                          @Value("${EVIDENCE_STORE_MONGO:false}") boolean useMongo) {
        this.incidents = incidents;
        this.gridFs = gridFs;
        this.directory = Path.of(directory).toAbsolutePath().normalize();
        this.useMongo = useMongo;
    }

    public String localOwner(String filename) throws IOException {
        Path owner = directory.resolve(filename + ".owner");
        return Files.exists(owner) ? Files.readString(owner) : null;
    }

    public void checkAttachments(List<String> urls, UserDetails user) throws IOException {
        if (urls == null) return;
        for (String url : urls) {
            if (url == null) continue;
            String path;
            try {
                path = URI.create(url).getPath();
            } catch (IllegalArgumentException malformed) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Enlace de evidencia inválido");
            }
            if (path == null) continue;
            var match = MANAGED_PATH.matcher(path);
            if (!match.matches()) continue;
            String filename = match.group(1);
            if (!FILENAME.matcher(filename).matches() || !canAttach(filename, user)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La evidencia no pertenece a tu reporte");
            }
        }
    }

    private boolean canAttach(String filename, UserDetails user) throws IOException {
        if (Files.isRegularFile(directory.resolve(filename))) {
            return canDownload(filename, user, localOwner(filename));
        }
        if (!useMongo) return false;
        var file = gridFs.findOne(query(where("filename").is(filename)));
        if (file == null) return false;
        var metadata = file.getMetadata();
        return canDownload(filename, user, metadata == null ? null : metadata.getString("owner"));
    }

    public boolean canDownload(String filename, UserDetails user, String owner) {
        if (IncidentService.isAdmin(user) || user.getUsername().equals(owner)) return true;
        String pattern = "^(?:https?://[^/]+)?/api/[Ff]iles/" + Pattern.quote(filename) + "$";
        var reports = incidents.findByImageUrlsRegex(pattern);
        if (owner == null) {
            return !reports.isEmpty()
                    && reports.stream().allMatch(incident -> IncidentService.canReadDetails(incident, user));
        }
        return reports.stream().anyMatch(incident -> owner.equals(incident.getReportedBy())
                && user.getUsername().equals(incident.getAssignedTo()));
    }
}

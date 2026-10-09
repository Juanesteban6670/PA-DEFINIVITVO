package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Model.LogEntry;
import Com.Backend.CartagenaSegura.Repository.LogEntryRepository;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class LogService {

    private final LogEntryRepository logEntryRepository;

    public LogService(LogEntryRepository logEntryRepository) {
        this.logEntryRepository = logEntryRepository;
    }

    // Log simple
    public void log(String action, String user, String details, String entityType, String entityId) {
        LogEntry entry = new LogEntry();
        entry.setAction(action);
        entry.setUser(user);
        entry.setDetails(details);
        entry.setEntityType(entityType);
        entry.setEntityId(entityId);
        entry.setLevel(LogEntry.LogLevel.INFO);
        logEntryRepository.save(entry);
    }

    // Log completo con IP y userAgent
    public void logFull(String action, String user, String details,
                        String ipAddress, String userAgent,
                        String entityType, String entityId) {
        LogEntry entry = new LogEntry();
        entry.setAction(action);
        entry.setUser(user);
        entry.setDetails(details);
        entry.setIpAddress(ipAddress);
        entry.setUserAgent(userAgent);
        entry.setEntityType(entityType);
        entry.setEntityId(entityId);
        entry.setLevel(LogEntry.LogLevel.INFO);
        logEntryRepository.save(entry);
    }

    // Log de error
    public void logError(String action, String user, String details, String entityType, String entityId) {
        LogEntry entry = new LogEntry();
        entry.setAction(action);
        entry.setUser(user);
        entry.setDetails(details);
        entry.setEntityType(entityType);
        entry.setEntityId(entityId);
        entry.setLevel(LogEntry.LogLevel.ERROR);
        logEntryRepository.save(entry);
    }

    public List<LogEntry> getAllLogs() {
        return logEntryRepository.findAll();
    }

    public List<LogEntry> getLogsByUser(String user) {
        return logEntryRepository.findByUserOrderByTimestampDesc(user);
    }

    public List<LogEntry> getLogsByLevel(LogEntry.LogLevel level) {
        return logEntryRepository.findByLevel(level);
    }

    public List<LogEntry> getLogsByDateRange(LocalDateTime from, LocalDateTime to) {
        return logEntryRepository.findByTimestampBetween(from, to);
    }

    public List<LogEntry> getLogsByEntity(String entityType, String entityId) {
        return logEntryRepository.findByEntityTypeAndEntityId(entityType, entityId);
    }
}

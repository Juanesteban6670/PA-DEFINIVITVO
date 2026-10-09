package Com.Backend.CartagenaSegura.Repository;

import Com.Backend.CartagenaSegura.Model.LogEntry;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface LogEntryRepository extends MongoRepository<LogEntry, String> {
    List<LogEntry> findByUserOrderByTimestampDesc(String user);
    List<LogEntry> findByLevel(LogEntry.LogLevel level);
    List<LogEntry> findByEntityTypeAndEntityId(String entityType, String entityId);
    List<LogEntry> findByTimestampBetween(LocalDateTime from, LocalDateTime to);
    List<LogEntry> findByAction(String action);
}

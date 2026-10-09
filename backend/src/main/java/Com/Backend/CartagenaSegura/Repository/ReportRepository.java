package Com.Backend.CartagenaSegura.Repository;

import Com.Backend.CartagenaSegura.Model.Report;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReportRepository extends MongoRepository<Report, String> {
    List<Report> findByGeneratedByOrderByCreatedAtDesc(String generatedBy);
    List<Report> findByType(Report.ReportType type);
    List<Report> findByStatus(Report.ReportStatus status);
    List<Report> findAllByOrderByCreatedAtDesc();
}

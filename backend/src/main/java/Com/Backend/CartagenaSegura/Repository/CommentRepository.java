package Com.Backend.CartagenaSegura.Repository;

import Com.Backend.CartagenaSegura.Model.Comment;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommentRepository extends MongoRepository<Comment, String> {
    // false = comentarios publicos visibles para todos
    List<Comment> findByIncidentIdAndDeletedFalse(String incidentId);
    List<Comment> findByIncidentIdAndIsInternalAndDeletedFalse(String incidentId, boolean isInternal);
    List<Comment> findByUserId(String userId);
    long countByIncidentIdAndDeletedFalse(String incidentId);
}

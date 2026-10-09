package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Dto.SharedDto.CreateCommentRequest;
import Com.Backend.CartagenaSegura.Model.Comment;
import Com.Backend.CartagenaSegura.Repository.CommentRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class CommentService {

    private final CommentRepository commentRepository;
    private final LogService logService;

    public CommentService(CommentRepository commentRepository, LogService logService) {
        this.commentRepository = commentRepository;
        this.logService = logService;
    }

    public Comment create(String incidentId, CreateCommentRequest req, String userId, String username) {
        Comment comment = new Comment(incidentId, userId, username, req.content(), req.isInternal());
        Comment saved = commentRepository.save(comment);
        logService.log("CREATE_COMMENT", username, "Comentario en incidente: " + incidentId,
                "Incident", incidentId);
        return saved;
    }

    // Comentarios públicos (usuarios normales)
    public List<Comment> getPublicByIncident(String incidentId) {
        return commentRepository.findByIncidentIdAndIsInternalAndDeletedFalse(incidentId, false);
    }

    // Todos los comentarios incluyendo internos (admin/agentes)
    public List<Comment> getAllByIncident(String incidentId) {
        return commentRepository.findByIncidentIdAndDeletedFalse(incidentId);
    }

    public Comment update(String commentId, String newContent, String requestedBy) {
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new RuntimeException("Comentario no encontrado"));

        if (!comment.getUserId().equals(requestedBy)) {
            throw new RuntimeException("No tienes permiso para editar este comentario");
        }

        comment.setContent(newContent);
        comment.setUpdatedAt(LocalDateTime.now());
        return commentRepository.save(comment);
    }

    public void delete(String commentId, String requestedBy) {
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new RuntimeException("Comentario no encontrado"));

        // Soft delete
        comment.setDeleted(true);
        commentRepository.save(comment);
        logService.log("DELETE_COMMENT", requestedBy, "Comentario eliminado: " + commentId,
                "Comment", commentId);
    }
}


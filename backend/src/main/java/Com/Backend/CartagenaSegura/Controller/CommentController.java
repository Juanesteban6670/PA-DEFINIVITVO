package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Dto.SharedDto.*;
import Com.Backend.CartagenaSegura.Model.Comment;
import Com.Backend.CartagenaSegura.Service.CommentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/Incidents/{incidentId}/Comments")
@Tag(name = "Comentarios", description = "Comentarios en incidentes. Soporta comentarios internos (solo ADMIN) y públicos.")
@SecurityRequirement(name = "bearerAuth")
public class CommentController {

    private final CommentService commentService;

    public CommentController(CommentService commentService) {
        this.commentService = commentService;
    }

    @PostMapping
    @Operation(
            summary = "Agregar comentario",
            description = "Agrega un comentario al incidente. Si `isInternal` es `true`, solo lo verán admins y agentes."
    )
    @io.swagger.v3.oas.annotations.parameters.RequestBody(
            content = @Content(examples = @ExampleObject(value = """
            { "content": "Se envió patrulla al sector", "isInternal": false }
        """))
    )
    public ResponseEntity<ApiResponse<Comment>> create(
            @Parameter(description = "ID del incidente") @PathVariable String incidentId,
            @RequestBody CreateCommentRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        Comment comment = commentService.create(incidentId, request,
                userDetails.getUsername(), userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Comentario agregado", comment));
    }

    @GetMapping
    @Operation(summary = "Comentarios públicos", description = "Retorna solo los comentarios visibles para todos los usuarios.")
    public ResponseEntity<ApiResponse<List<Comment>>> getPublic(
            @Parameter(description = "ID del incidente") @PathVariable String incidentId) {
        return ResponseEntity.ok(ApiResponse.ok("OK", commentService.getPublicByIncident(incidentId)));
    }

    @GetMapping("/All")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Todos los comentarios", description = "**Solo ADMIN**. Incluye comentarios internos.")
    public ResponseEntity<ApiResponse<List<Comment>>> getAll(
            @PathVariable String incidentId) {
        return ResponseEntity.ok(ApiResponse.ok("OK", commentService.getAllByIncident(incidentId)));
    }

    @PutMapping("/{commentId}")
    @Operation(summary = "Editar comentario", description = "Solo el autor puede editar su propio comentario.")
    public ResponseEntity<ApiResponse<Comment>> update(
            @PathVariable String incidentId,
            @Parameter(description = "ID del comentario") @PathVariable String commentId,
            @RequestParam String content,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("Comentario actualizado",
                commentService.update(commentId, content, userDetails.getUsername())));
    }

    @DeleteMapping("/{commentId}")
    @Operation(summary = "Eliminar comentario", description = "Soft delete. Solo el autor puede eliminar su comentario.")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable String incidentId,
            @PathVariable String commentId,
            @AuthenticationPrincipal UserDetails userDetails) {
        commentService.delete(commentId, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Comentario eliminado", null));
    }
}

package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Dto.AuthDto.*;
import Com.Backend.CartagenaSegura.Dto.SharedDto.ApiResponse;
import Com.Backend.CartagenaSegura.Service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/Auth")
@Tag(name = "Autenticación", description = "Registro e inicio de sesión de usuarios")
@SecurityRequirements // Rutas públicas - sin token
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/Register")
    @Operation(
            summary = "Registrar nuevo usuario",
            description = "Crea una nueva cuenta con rol USER. Retorna JWT token listo para usar."
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Registro exitoso"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Username o email ya en uso")
    })
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Datos del nuevo usuario",
                    content = @Content(examples = @ExampleObject(value = """
                    {
                      "username": "juanperez",
                      "password": "Password123!",
                      "email": "juan@email.com",
                      "fullName": "Juan Pérez",
                      "phone": "3001234567"
                    }
                """))
            )
            @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(ApiResponse.ok("Registro exitoso", authService.register(request)));
    }

    @PostMapping("/Login")
    @Operation(
            summary = "Iniciar sesión",
            description = "Autentica al usuario. Copia el `token` de la respuesta y úsalo en el botón **Authorize** (formato: `Bearer <token>`)."
    )
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Login exitoso - retorna JWT token"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Credenciales incorrectas")
    })
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    content = @Content(examples = @ExampleObject(value = """
                    { "username": "juanperez", "password": "Password123!" }
                """))
            )
            @RequestBody LoginRequest request,
            HttpServletRequest httpRequest) {
        AuthResponse response = authService.login(request,
                httpRequest.getRemoteAddr(), httpRequest.getHeader("User-Agent"));
        return ResponseEntity.ok(ApiResponse.ok("Login exitoso", response));
    }

    @PostMapping("/ForgotPassword")
    @Operation(summary = "Solicitar restablecimiento de contraseña", description = "Envía un correo con un token de un solo uso.")
    public ResponseEntity<ApiResponse<Void>> forgotPassword(@RequestBody ForgotPasswordRequest request) {
        authService.forgotPassword(request);
        return ResponseEntity.ok(ApiResponse.ok("Se ha enviado un enlace de recuperación a tu correo", null));
    }

    @PostMapping("/ResetPassword")
    @Operation(summary = "Restablecer contraseña", description = "Usa el token recibido por correo para establecer una nueva contraseña.")
    public ResponseEntity<ApiResponse<Void>> resetPassword(@RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request);
        return ResponseEntity.ok(ApiResponse.ok("Tu contraseña ha sido restablecida con éxito", null));
    }
}

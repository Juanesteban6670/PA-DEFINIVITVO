package Com.Backend.CartagenaSegura.Dto;

public class AuthDto {

    // ---- REQUEST: Login ----
    public record LoginRequest(String username, String password) {}

    // ---- REQUEST: Registro ----
    public record RegisterRequest(
            String username,
            String password,
            String email,
            String fullName,
            String phone
    ) {}

    // ---- RESPONSE: Token JWT ----
    public record AuthResponse(
            String token,
            String username,
            String fullName,
            String email,
            String phone,
            java.util.Set<String> roles
    ) {}

    // ---- REQUEST: Olvidé mi contraseña ----
    public record ForgotPasswordRequest(String email) {}

    // ---- REQUEST: Restablecer contraseña ----
    public record ResetPasswordRequest(String token, String newPassword) {}

} 


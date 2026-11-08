package Com.Backend.CartagenaSegura.Service;
import Com.Backend.CartagenaSegura.Dto.AuthDto.*;
import Com.Backend.CartagenaSegura.Model.Role;
import Com.Backend.CartagenaSegura.Model.User;
import Com.Backend.CartagenaSegura.Repository.RoleRepository;
import Com.Backend.CartagenaSegura.Repository.UserRepository;
import Com.Backend.CartagenaSegura.Security.JwtUtil;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import java.time.LocalDateTime;
import java.util.UUID;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class AuthService {
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;
    private final LogService logService;
    private final EmailService emailService;
    @Value("${app.frontend-url:http://localhost:3000}")
    private String frontendUrl;

    public AuthService(UserRepository userRepository,
                       RoleRepository roleRepository,
                       PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil,
                       AuthenticationManager authenticationManager,
                       LogService logService,
                       EmailService emailService) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.authenticationManager = authenticationManager;
        this.logService = logService;
        this.emailService = emailService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.username())) {
            throw new IllegalArgumentException("El username ya esta en uso");
        }
        if (userRepository.existsByEmail(request.email())) {
            throw new IllegalArgumentException("El email ya esta en uso");
        }
        if (request.phone() != null && !request.phone().isBlank() &&
                userRepository.existsByPhone(request.phone())) {
            throw new IllegalArgumentException("El telefono ya esta en uso");
        }
        Role userRole = roleRepository.findByName("USER")
                .orElseGet(() -> roleRepository.save(new Role("USER", "Usuario estándar")));
        User user = new User(
                request.username(),
                passwordEncoder.encode(request.password()),
                request.email(),
                request.fullName(),
                request.phone()
        );
        user.setRoles(Set.of(userRole));
        userRepository.save(user);
        logService.log("REGISTER", request.username(), "Nuevo usuario registrado", "User", null);
        emailService.sendWelcomeEmail(user.getEmail(), user.getUsername(), user.getFullName());
        String token = jwtUtil.generateToken(user);
        Set<String> roles = user.getRoles().stream().map(Role::getName).collect(Collectors.toSet());
        return new AuthResponse(token, user.getUsername(), user.getFullName(), user.getEmail(), user.getPhone(), roles);
    }

    public AuthResponse login(LoginRequest request, String ipAddress, String userAgent) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.username(), request.password())
            );
        } catch (org.springframework.security.core.AuthenticationException ex) {
            logService.logFull("LOGIN_FAILED", request.username(),
                    "Intento de autenticación fallido: credenciales inválidas",
                    ipAddress, userAgent, "User", null, Com.Backend.CartagenaSegura.Model.LogEntry.LogLevel.WARN);
            throw ex;
        }

        User user = userRepository.findByUsername(request.username())
                .or(() -> userRepository.findByEmail(request.username()))
                .or(() -> userRepository.findByPhone(request.username()))
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));
        user.setLastLogin(LocalDateTime.now());
        userRepository.save(user);
        logService.logFull("LOGIN", request.username(), "Inicio de sesión exitoso",
                ipAddress, userAgent, "User", null);
        String token = jwtUtil.generateToken(user);
        Set<String> roles = user.getRoles().stream().map(Role::getName).collect(Collectors.toSet());
        return new AuthResponse(token, user.getUsername(), user.getFullName(), user.getEmail(), user.getPhone(), roles);
    }

    @Transactional
    public ProfileResponse updateProfile(String username, ProfileUpdateRequest request) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));
        String fullName = request.fullName() == null ? "" : request.fullName().trim();
        String email = request.email() == null ? "" : request.email().trim();
        String phone = request.phone() == null ? "" : request.phone().trim();
        if (!StringUtils.hasText(fullName)) {
            throw new IllegalArgumentException("El nombre completo es obligatorio");
        }
        if (!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) {
            throw new IllegalArgumentException("Ingresa un correo válido");
        }
        if (userRepository.existsByEmailAndUsernameNot(email, username)) {
            throw new IllegalArgumentException("El correo ya está en uso");
        }
        if (StringUtils.hasText(phone) && userRepository.existsByPhoneAndUsernameNot(phone, username)) {
            throw new IllegalArgumentException("El teléfono ya está en uso");
        }

        user.setFullName(fullName);
        user.setEmail(email);
        user.setPhone(phone.isEmpty() ? null : phone);
        User updated = userRepository.save(user);
        logService.log("UPDATE_PROFILE", username, "Perfil ciudadano actualizado", "User", null);
        return new ProfileResponse(updated.getUsername(), updated.getFullName(),
                updated.getEmail(), updated.getPhone());
    }

    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new IllegalArgumentException("No existe un usuario asociado a este correo"));

        String token = UUID.randomUUID().toString();
        user.setResetToken(token);
        user.setResetTokenExpiration(LocalDateTime.now().plusHours(1));
        userRepository.save(user);

        String resetUrl = frontendUrl + "/ResetPassword?token=" + token;

        emailService.sendPasswordResetEmail(user.getEmail(), user.getUsername(), resetUrl);
        
        logService.log("FORGOT_PASSWORD", user.getUsername(), "Solicitud de restablecimiento de contraseña", "User", null);
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        User user = userRepository.findByResetToken(request.token())
                .orElseThrow(() -> new IllegalArgumentException("El token de recuperación no es válido o ya fue usado"));

        if (user.getResetTokenExpiration().isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("El enlace ha expirado (validez de 60 min). Solicita uno nuevo.");
        }

        user.setPassword(passwordEncoder.encode(request.newPassword()));
        user.setResetToken(null);
        user.setResetTokenExpiration(null);
        userRepository.save(user);

        logService.log("RESET_PASSWORD", user.getUsername(), "Contraseña restablecida exitosamente", "User", null);
    }
}

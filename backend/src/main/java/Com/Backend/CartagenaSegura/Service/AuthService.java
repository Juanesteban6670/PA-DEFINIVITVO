package Com.Backend.CartagenaSegura.Service;
import Com.Backend.CartagenaSegura.Dto.AuthDto.*;
import Com.Backend.CartagenaSegura.Model.Role;
import Com.Backend.CartagenaSegura.Model.User;
import Com.Backend.CartagenaSegura.Repository.RoleRepository;
import Com.Backend.CartagenaSegura.Repository.UserRepository;
import Com.Backend.CartagenaSegura.Security.JwtUtil;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
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
    @Value("${app.frontend-url:https://cartagena-segura.vercel.app}")
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
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.username(), request.password())
        );
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
    public void forgotPassword(ForgotPasswordRequest request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new IllegalArgumentException("No existe un usuario asociado a este correo"));

        String token = UUID.randomUUID().toString();
        user.setResetToken(token);
        user.setResetTokenExpiration(LocalDateTime.now().plusHours(1));
        userRepository.save(user);

        String resetUrl = frontendUrl + "/ResetPassword?token=" + token;
        String localUrl = "http://localhost:3000/ResetPassword?token=" + token;
        
        // DEBUG: Imprimir en consola para pruebas locales
        System.out.println("\n=========================================================");
        System.out.println("RECOVERY LINK (DEBUG): " + localUrl);
        System.out.println("PRODUCTION LINK: " + resetUrl);
        System.out.println("=========================================================\n");

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

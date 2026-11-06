package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Dto.AuthDto.ProfileUpdateRequest;
import Com.Backend.CartagenaSegura.Model.User;
import Com.Backend.CartagenaSegura.Repository.RoleRepository;
import Com.Backend.CartagenaSegura.Repository.UserRepository;
import Com.Backend.CartagenaSegura.Security.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceProfileTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private RoleRepository roleRepository;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private JwtUtil jwtUtil;
    @Mock
    private AuthenticationManager authenticationManager;
    @Mock
    private LogService logService;
    @Mock
    private EmailService emailService;

    private AuthService service;

    @BeforeEach
    void setUp() {
        service = new AuthService(
                userRepository, roleRepository, passwordEncoder, jwtUtil,
                authenticationManager, logService, emailService
        );
    }

    @Test
    void updatesOnlyTheAuthenticatedUsersProfileAndAllowsAnEmptyPhone() {
        User user = new User("citizen", "hashed", "old@example.test", "Old Name", "3001234567");
        when(userRepository.findByUsername("citizen")).thenReturn(Optional.of(user));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        var result = service.updateProfile(
                "citizen",
                new ProfileUpdateRequest("  New Name ", " new@example.test ", " ")
        );

        assertEquals("citizen", result.username());
        assertEquals("New Name", result.fullName());
        assertEquals("new@example.test", result.email());
        assertNull(result.phone());
        verify(userRepository).save(user);
        verify(logService).log(
                "UPDATE_PROFILE", "citizen", "Perfil ciudadano actualizado", "User", null
        );
    }

    @Test
    void rejectsEmailAlreadyOwnedByAnotherAccount() {
        User user = new User("citizen", "hashed", "old@example.test", "Name", null);
        when(userRepository.findByUsername("citizen")).thenReturn(Optional.of(user));
        when(userRepository.existsByEmailAndUsernameNot("other@example.test", "citizen"))
                .thenReturn(true);

        assertThrows(
                IllegalArgumentException.class,
                () -> service.updateProfile(
                        "citizen",
                        new ProfileUpdateRequest("Name", "other@example.test", null)
                )
        );
        verify(userRepository, never()).save(any());
    }
}

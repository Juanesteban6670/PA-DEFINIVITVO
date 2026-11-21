package Com.Backend.CartagenaSegura.Repository;

import Com.Backend.CartagenaSegura.Model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    Optional<User> findByPhone(String phone);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
    boolean existsByEmailAndUsernameNot(String email, String username);
    boolean existsByPhone(String phone);
    boolean existsByPhoneAndUsernameNot(String phone, String username);
    Optional<User> findByResetToken(String resetToken);

    @Query("SELECT u FROM User u JOIN u.roles r WHERE UPPER(r.name) IN ('ADMIN', 'ROLE_ADMIN', 'OFFICER', 'ROLE_OFFICER')")
    List<User> findAllAdminsAndOfficers();
}

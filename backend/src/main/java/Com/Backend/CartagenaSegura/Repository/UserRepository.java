package Com.Backend.CartagenaSegura.Repository;

import Com.Backend.CartagenaSegura.Model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    @org.springframework.data.jpa.repository.Query(
            "select distinct u.username from User u join u.roles r where r.name in ('ADMIN', 'ROLE_ADMIN')")
    java.util.List<String> findAdministratorUsernames();

    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    Optional<User> findByPhone(String phone);
    boolean existsByUsername(String username);
    boolean existsByEmail(String email);
    boolean existsByEmailAndUsernameNot(String email, String username);
    boolean existsByPhone(String phone);
    boolean existsByPhoneAndUsernameNot(String phone, String username);
    Optional<User> findByResetToken(String resetToken);
}

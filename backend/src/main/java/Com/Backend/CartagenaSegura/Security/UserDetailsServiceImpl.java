package Com.Backend.CartagenaSegura.Security;

import Com.Backend.CartagenaSegura.Repository.UserRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository;

    public UserDetailsServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String identifier) throws UsernameNotFoundException {
        return userRepository.findByUsername(identifier)
            .or(() -> userRepository.findByEmail(identifier))
            .or(() -> userRepository.findByPhone(identifier))
            .orElseThrow(() -> new UsernameNotFoundException("Usuario no encontrado: " + identifier));
    }

}


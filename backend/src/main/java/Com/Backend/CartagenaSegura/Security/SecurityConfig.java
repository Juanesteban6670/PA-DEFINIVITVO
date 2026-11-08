package Com.Backend.CartagenaSegura.Security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.ArrayList;
import java.util.List;
import java.util.Arrays;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final UserDetailsServiceImpl userDetailsService;
    private final JwtAuthFilter jwtAuthFilter;

    @Value("${app.cors.allowed-origins}")
    private String allowedOrigins;

    public SecurityConfig(UserDetailsServiceImpl userDetailsService, JwtAuthFilter jwtAuthFilter) {
        this.userDetailsService = userDetailsService;
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // ===== Swagger / OpenAPI - publico =====
                        .requestMatchers(
                                "/swagger-ui.html",
                                "/swagger-ui/**",
                                "/api-docs",
                                "/api-docs/**",
                                "/v3/api-docs",
                                "/v3/api-docs/**"
                        ).permitAll()
                        // ===== Recursos estaticos y Flutter Web SPA - publico =====
                        .requestMatchers(
                                "/",
                                "/index.html",
                                "/Index.html",
                                "/*.ico",
                                "/*.png",
                                "/*.jpg",
                                "/*.jpeg",
                                "/*.svg",
                                "/*.js",
                                "/*.json",
                                "/*.wasm",
                                "/*.map",
                                "/canvaskit/**",
                                "/assets/**",
                                "/icons/**",
                                "/css/**",
                                "/js/**",
                                "/images/**",
                                "/error",
                                "/Login",
                                "/Register",
                                "/ForgotPassword",
                                "/ResetPassword",
                                "/App",
                                "/App/**",
                                "/Admin",
                                "/Admin/**"
                        ).permitAll()
                        // ===== Actuator y WebSockets - publico =====
                        .requestMatchers(
                                "/actuator",
                                "/actuator/**",
                                "/ws",
                                "/ws/**",
                                "/ws-sockjs",
                                "/ws-sockjs/**"
                        ).permitAll()
                        // ===== Auth - publico =====
                        .requestMatchers(HttpMethod.PUT, "/api/Auth/Profile").authenticated()
                        .requestMatchers("/api/Auth/**").permitAll()
                        
                        // ===== Estadisticas publicas para Landing Page (Solo GET) =====
                        .requestMatchers(HttpMethod.GET, "/api/Incidents").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/Zones").permitAll()

                        // ===== Archivos de evidencia - publico (solo GET) =====
                        .requestMatchers(HttpMethod.GET, "/api/Files/**", "/api/files/**").permitAll()
                        // ===== Contactos de emergencia - publico =====
                        .requestMatchers("/api/EmergencyContacts", "/api/EmergencyContacts/**").permitAll()
                        // ===== Solo ADMIN u OFFICER =====
                        .requestMatchers("/api/Admin/**").hasRole("ADMIN")
                        .requestMatchers("/api/Reports/**").hasAnyRole("ADMIN", "OFFICER")
                        .requestMatchers("/api/Logs/**").hasRole("ADMIN")
                        .requestMatchers("/api/Ai/Summary", "/api/Ai/Zones/Analysis", "/api/Ai/PatrolPlan", "/api/Ai/Anomalies").hasRole("ADMIN")
                        // ===== Todo lo demás requiere autenticación =====
                        .anyRequest().authenticated()
                )
                .authenticationProvider(authenticationProvider())
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        List<String> origins = new ArrayList<>(Arrays.stream(allowedOrigins.split(","))
                .map(String::trim)
                .filter(origin -> !origin.isEmpty())
                .toList());
        if (origins.isEmpty()) {
            throw new IllegalStateException("CORS_ALLOWED_ORIGINS debe incluir al menos un origen permitido");
        }
        // Permitir automáticamente los túneles Cloudflare y patrones si no están definidos
        if (!origins.contains("*")) {
            origins.add("https://*.trycloudflare.com");
            origins.add("http://*.trycloudflare.com");
        }
        config.setAllowedOriginPatterns(origins);
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}

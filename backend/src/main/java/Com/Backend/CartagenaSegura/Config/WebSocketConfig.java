package Com.Backend.CartagenaSegura.Config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * Configuración de WebSockets con STOMP para alertas y monitoreo en tiempo real
 * (SOS ciudadano, nuevos incidentes y actualizaciones de cuadrante).
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Habilita broker en memoria para tópicos públicos de difusión
        config.enableSimpleBroker("/topic", "/queue");
        // Prefijo para mensajes enviados desde los clientes hacia el servidor
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Endpoint nativo WebSocket STOMP
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*");

        // Endpoint alternativo con fallback SockJS para compatibilidad total de navegadores
        registry.addEndpoint("/ws-sockjs")
                .setAllowedOriginPatterns("*")
                .withSockJS();
    }
}

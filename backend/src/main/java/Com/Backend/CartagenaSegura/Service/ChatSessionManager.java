package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Dto.AiDto;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Gestor de sesiones conversacionales en memoria para el asistente de Cartagena Segura.
 * Permite mantener memoria de contexto multi-turno con cero costo y cero configuración externa.
 */
@Slf4j
@Component
public class ChatSessionManager {

    private static final long SESSION_EXPIRY_MS = 4 * 60 * 60 * 1000L; // 4 horas
    private static final int MAX_HISTORY_PER_SESSION = 12;

    private final Map<String, SessionState> sessions = new ConcurrentHashMap<>();

    @Data
    public static class SessionState {
        private String sessionId;
        private String activeTopic;       // TRAFFIC_ACCIDENT, THEFT_ROBBERY, MEDICAL_EMERGENCY, DOMESTIC_VIOLENCE, ZONE_QUERY, GENERAL_SAFETY
        private String subtopic;          // moto, carro, peatón, etc.
        private String lastMentionedZone; // ej: Centro, Bocagrande, Manga
        private int turnCount = 0;
        private long lastActivity = System.currentTimeMillis();
        private List<AiDto.MessageHistory> history = new ArrayList<>();

        public SessionState(String sessionId) {
            this.sessionId = sessionId;
        }

        public void touch() {
            this.lastActivity = System.currentTimeMillis();
        }

        public void addMessage(String role, String content) {
            this.history.add(new AiDto.MessageHistory(role, content));
            if (this.history.size() > MAX_HISTORY_PER_SESSION) {
                this.history.remove(0);
            }
        }
    }

    public SessionState getOrCreate(String sessionId) {
        cleanExpiredSessions();
        if (sessionId == null || sessionId.isBlank()) {
            sessionId = "anonymous-" + System.currentTimeMillis();
        }
        return sessions.computeIfAbsent(sessionId, SessionState::new);
    }

    public void recordTurn(String sessionId, String userMessage, String assistantReply, String topic, String subtopic, String zone) {
        if (sessionId == null || sessionId.isBlank()) return;
        SessionState state = sessions.computeIfAbsent(sessionId, SessionState::new);
        state.touch();
        state.setTurnCount(state.getTurnCount() + 1);

        if (topic != null && !topic.isBlank()) {
            state.setActiveTopic(topic);
        }
        if (subtopic != null && !subtopic.isBlank()) {
            state.setSubtopic(subtopic);
        }
        if (zone != null && !zone.isBlank()) {
            state.setLastMentionedZone(zone);
        }

        state.addMessage("user", userMessage);
        state.addMessage("assistant", assistantReply);
    }

    private void cleanExpiredSessions() {
        long now = System.currentTimeMillis();
        sessions.entrySet().removeIf(entry -> (now - entry.getValue().getLastActivity()) > SESSION_EXPIRY_MS);
    }
}

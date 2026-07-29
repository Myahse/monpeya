package com.monpeya.immo.api.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.monpeya.immo.api.contracts.ImmoEnvelope;
import com.monpeya.immo.api.entity.ImmoMessage;
import com.monpeya.immo.api.repository.ImmoMessageRepository;

@Service
@Transactional("immoTransactionManager")
public class ImmoMessageService {

    private final ImmoMessageRepository messageRepository;

    public ImmoMessageService(ImmoMessageRepository messageRepository) {
        this.messageRepository = messageRepository;
    }

    @Transactional(value = "immoTransactionManager", readOnly = true)
    public List<Map<String, Object>> listConversations(String userId) {
        List<ImmoMessage> messages = messageRepository.findByUserId(userId);
        Map<String, Map<String, Object>> conversations = new LinkedHashMap<>();

        for (ImmoMessage message : messages) {
            String otherUserId = userId.equals(message.getSenderId())
                    ? message.getReceiverId()
                    : message.getSenderId();
            conversations.computeIfAbsent(otherUserId, id -> {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("userId", id);
                row.put("userName", "Utilisateur " + id);
                row.put("lastMessage", message.getContent());
                row.put("lastMessageTime", message.getSentAt());
                row.put("unreadCount", 0);
                return row;
            });
        }
        return new ArrayList<>(conversations.values());
    }

    @Transactional(value = "immoTransactionManager", readOnly = true)
    public List<Map<String, Object>> listConversation(String user1Id, String user2Id) {
        return ImmoMapper.mapList(
                messageRepository.findConversation(user1Id, user2Id),
                item -> ImmoMapper.toMessageMap((ImmoMessage) item));
    }

    public Map<String, Object> send(Map<String, Object> body) {
        ImmoMessage message = new ImmoMessage();
        message.setMessagesId(UUID.randomUUID().toString());
        message.setSenderId(stringValue(body.get("senderId")));
        message.setReceiverId(stringValue(body.get("receiverId")));
        message.setContent(stringValue(body.get("content")));
        message.setMessageType(stringValue(body.get("messageType"), "TEXT"));
        message.setSentAt(LocalDateTime.now());
        message.setIsRead(false);
        ImmoMessage saved = messageRepository.save(message);
        return ImmoEnvelope.item(ImmoMapper.toMessageMap(saved));
    }

    private static String stringValue(Object value) {
        return value == null ? "" : value.toString();
    }

    private static String stringValue(Object value, String defaultValue) {
        if (value == null || value.toString().isBlank()) {
            return defaultValue;
        }
        return value.toString();
    }
}

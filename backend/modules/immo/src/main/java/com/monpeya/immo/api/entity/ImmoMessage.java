package com.monpeya.immo.api.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "MESSAGES")
public class ImmoMessage {

    @Id
    @Column(name = "MESSAGES_ID", length = 36)
    private String messagesId;

    @Column(name = "SENDER_ID", nullable = false, length = 50)
    private String senderId;

    @Column(name = "RECEIVER_ID", nullable = false, length = 50)
    private String receiverId;

    @Column(name = "CONTENT", nullable = false)
    private String content;

    @Column(name = "MESSAGE_TYPE", length = 20)
    private String messageType;

    @Column(name = "SENT_AT")
    private LocalDateTime sentAt;

    @Column(name = "IS_READ")
    private Boolean isRead;
}

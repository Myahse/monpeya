package com.monpeya.immo.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.monpeya.immo.api.entity.ImmoMessage;

public interface ImmoMessageRepository extends JpaRepository<ImmoMessage, String> {

    @Query("""
            SELECT m FROM ImmoMessage m
            WHERE (m.senderId = :userId OR m.receiverId = :userId)
            ORDER BY m.sentAt DESC
            """)
    List<ImmoMessage> findByUserId(@Param("userId") String userId);

    @Query("""
            SELECT m FROM ImmoMessage m
            WHERE (m.senderId = :user1 AND m.receiverId = :user2)
               OR (m.senderId = :user2 AND m.receiverId = :user1)
            ORDER BY m.sentAt ASC
            """)
    List<ImmoMessage> findConversation(
            @Param("user1") String user1,
            @Param("user2") String user2);
}

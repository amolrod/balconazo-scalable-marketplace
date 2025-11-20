package com.balconazo.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {
    private String userId;
    private String email;
    private String name;
    private String phone;
    private String profileImageUrl;
    private Boolean isHost;
    private Boolean isGuest;
    private Boolean active;
    private LocalDateTime createdAt;
}


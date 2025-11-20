package com.balconazo.catalog_microservice.dto;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDTO {
    private UUID id;
    private String email;
    private String name;
    private String phone;
    private String profileImageUrl;
    private Boolean isHost;
    private Boolean isGuest;
    private Integer trustScore;
    private Boolean active;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

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
    private String role;
    private Integer trustScore;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

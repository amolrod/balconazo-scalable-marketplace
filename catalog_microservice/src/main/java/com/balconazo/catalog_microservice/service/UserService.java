package com.balconazo.catalog_microservice.service;

import com.balconazo.catalog_microservice.dto.CreateUserDTO;
import com.balconazo.catalog_microservice.dto.UserDTO;
import java.util.List;
import java.util.UUID;

public interface UserService {
    UserDTO createUser(CreateUserDTO dto);
    UserDTO getUserById(UUID id);
    UserDTO getUserByEmail(String email);
    List<UserDTO> getUsersByRole(String role);
    UserDTO updateTrustScore(UUID id, Integer score);
    UserDTO suspendUser(UUID id);
    UserDTO activateUser(UUID id);
}


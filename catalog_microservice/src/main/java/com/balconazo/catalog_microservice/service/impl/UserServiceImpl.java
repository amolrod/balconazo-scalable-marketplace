package com.balconazo.catalog_microservice.service.impl;

import com.balconazo.catalog_microservice.dto.*;
import com.balconazo.catalog_microservice.entity.UserEntity;
import com.balconazo.catalog_microservice.exception.*;
import com.balconazo.catalog_microservice.mapper.UserMapper;
import com.balconazo.catalog_microservice.repository.UserRepository;
import com.balconazo.catalog_microservice.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.stream.Collectors;
import static com.balconazo.catalog_microservice.constants.CatalogConstants.*;

@Service
@RequiredArgsConstructor
@Transactional
public class UserServiceImpl implements UserService {
    private final UserRepository repo;
    private final UserMapper mapper;
    private final BCryptPasswordEncoder encoder;

    public UserDTO createUser(CreateUserDTO dto) {
        // DEPRECATED: Catalog Service no debe crear usuarios - usar Auth Service
        throw new UnsupportedOperationException("Use Auth Service to create users");
    }

    @Transactional(readOnly = true)
    public UserDTO getUserById(UUID id) {
        return mapper.toDTO(repo.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Usuario", id)));
    }

    @Transactional(readOnly = true)
    public UserDTO getUserByEmail(String email) {
        return mapper.toDTO(repo.findByEmail(email)
            .orElseThrow(() -> new ResourceNotFoundException("Usuario con email: " + email)));
    }

    @Transactional(readOnly = true)
    public List<UserDTO> getAllUsers() {
        return repo.findAll().stream()
            .map(mapper::toDTO)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<UserDTO> getUsersByRole(String role) {
        // Convertir role antiguo a nuevo modelo
        Boolean isHost = "HOST".equals(role);
        return repo.findByIsHostAndActive(isHost, true).stream()
            .map(mapper::toDTO).collect(Collectors.toList());
    }

    public UserDTO updateTrustScore(UUID id, Integer score) {
        var user = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Usuario", id));
        user.setTrustScore(score);
        return mapper.toDTO(repo.save(user));
    }

    public UserDTO suspendUser(UUID id) {
        var user = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Usuario", id));
        user.setActive(false);
        return mapper.toDTO(repo.save(user));
    }

    public UserDTO activateUser(UUID id) {
        var user = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Usuario", id));
        user.setActive(true);
        return mapper.toDTO(repo.save(user));
    }
}


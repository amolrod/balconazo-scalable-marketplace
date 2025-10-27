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
        if (repo.existsByEmail(dto.getEmail()))
            throw new DuplicateResourceException("Usuario", "email", dto.getEmail());
        var user = UserEntity.builder()
            .email(dto.getEmail())
            .passwordHash(encoder.encode(dto.getPassword()))
            .role(dto.getRole())
            .trustScore(0)
            .status(STATUS_ACTIVE)
            .build();
        return mapper.toDTO(repo.save(user));
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
    public List<UserDTO> getUsersByRole(String role) {
        return repo.findByRoleAndStatus(role, STATUS_ACTIVE).stream()
            .map(mapper::toDTO).collect(Collectors.toList());
    }

    public UserDTO updateTrustScore(UUID id, Integer score) {
        var user = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Usuario", id));
        user.setTrustScore(score);
        return mapper.toDTO(repo.save(user));
    }

    public UserDTO suspendUser(UUID id) {
        var user = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Usuario", id));
        user.setStatus(STATUS_SUSPENDED);
        return mapper.toDTO(repo.save(user));
    }

    public UserDTO activateUser(UUID id) {
        var user = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Usuario", id));
        user.setStatus(STATUS_ACTIVE);
        return mapper.toDTO(repo.save(user));
    }
}


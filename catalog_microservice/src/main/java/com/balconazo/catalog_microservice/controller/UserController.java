package com.balconazo.catalog_microservice.controller;

import com.balconazo.catalog_microservice.dto.*;
import com.balconazo.catalog_microservice.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/catalog/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService service;

    @PostMapping
    public ResponseEntity<UserDTO> create(@Valid @RequestBody CreateUserDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createUser(dto));
    }

    @GetMapping("/{id}")
    public UserDTO getById(@PathVariable UUID id) {
        return service.getUserById(id);
    }

    @GetMapping("/email/{email}")
    public UserDTO getByEmail(@PathVariable String email) {
        return service.getUserByEmail(email);
    }

    @GetMapping
    public List<UserDTO> getUsers(@RequestParam(required = false) String role) {
        if (role != null && !role.isEmpty()) {
            return service.getUsersByRole(role);
        }
        return service.getAllUsers();
    }

    @PatchMapping("/{id}/trust-score")
    public UserDTO updateTrust(@PathVariable UUID id, @RequestParam Integer score) {
        return service.updateTrustScore(id, score);
    }

    @PostMapping("/{id}/suspend")
    public UserDTO suspend(@PathVariable UUID id) {
        return service.suspendUser(id);
    }

    @PostMapping("/{id}/activate")
    public UserDTO activate(@PathVariable UUID id) {
        return service.activateUser(id);
    }
}


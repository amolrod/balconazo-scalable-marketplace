package com.balconazo.catalog_microservice.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.transaction.annotation.EnableTransactionManagement;

@Configuration
@EnableJpaRepositories(basePackages = "com.balconazo.catalog_microservice.repository")
@EnableTransactionManagement
public class JpaConfig {
}


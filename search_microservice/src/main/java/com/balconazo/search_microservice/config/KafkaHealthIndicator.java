package com.balconazo.search_microservice.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.DescribeClusterResult;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.kafka.core.KafkaAdmin;
import org.springframework.stereotype.Component;

import java.util.concurrent.TimeUnit;

@Component
@RequiredArgsConstructor
@Slf4j
public class KafkaHealthIndicator implements HealthIndicator {

    private final KafkaAdmin kafkaAdmin;

    @Override
    public Health health() {
        try {
            AdminClient adminClient = AdminClient.create(kafkaAdmin.getConfigurationProperties());

            DescribeClusterResult clusterResult = adminClient.describeCluster();
            String clusterId = clusterResult.clusterId().get(5, TimeUnit.SECONDS);
            int nodeCount = clusterResult.nodes().get(5, TimeUnit.SECONDS).size();

            adminClient.close();

            log.debug("Kafka health check OK - ClusterId: {}, Nodes: {}", clusterId, nodeCount);

            return Health.up()
                    .withDetail("clusterId", clusterId)
                    .withDetail("nodeCount", nodeCount)
                    .withDetail("bootstrapServers", kafkaAdmin.getConfigurationProperties().get("bootstrap.servers"))
                    .build();

        } catch (Exception e) {
            log.error("Kafka health check failed: {}", e.getMessage());
            return Health.down()
                    .withDetail("error", e.getMessage())
                    .withDetail("bootstrapServers", kafkaAdmin.getConfigurationProperties().get("bootstrap.servers"))
                    .build();
        }
    }
}


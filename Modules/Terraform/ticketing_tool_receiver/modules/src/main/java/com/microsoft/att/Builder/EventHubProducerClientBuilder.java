package com.microsoft.att.Builder;

import com.azure.core.amqp.AmqpTransportType;
import com.azure.identity.DefaultAzureCredential;
import com.azure.messaging.eventhubs.EventHubClientBuilder;
import com.azure.messaging.eventhubs.EventHubProducerClient;

public class EventHubProducerClientBuilder {
    String fullyQualifiedNamespace;
    String eventHubName;
    DefaultAzureCredential tokenCredential;
    String connectionString;
    boolean useConnectionString = false;

    public EventHubProducerClientBuilder withFullyQualifiedNamespace(String fullyQualifiedNamespace) {
        this.fullyQualifiedNamespace = fullyQualifiedNamespace;
        return this;
    }

    public EventHubProducerClientBuilder withEventHubName(String eventHubName) {
        this.eventHubName = eventHubName;
        return this;
    }

    public EventHubProducerClientBuilder withCredentials(DefaultAzureCredential credential) {
        tokenCredential = credential;
        return this;
    }

    public EventHubProducerClientBuilder withConnectionString(String connectionString) {
        this.connectionString = connectionString;
        return this;
    }

    public EventHubProducerClientBuilder useConnectionString(boolean useConnectionString) {
        this.useConnectionString = useConnectionString;
        return this;
    }

    public EventHubProducerClient build() {
        EventHubClientBuilder eventHubBuilder = new EventHubClientBuilder()
        .transportType(AmqpTransportType.AMQP_WEB_SOCKETS);

        if (useConnectionString) {
            return eventHubBuilder
            .connectionString(connectionString, eventHubName)
            .buildProducerClient();
        }

        return eventHubBuilder
                .credential(fullyQualifiedNamespace, eventHubName, tokenCredential)
                .buildProducerClient();
    }
}

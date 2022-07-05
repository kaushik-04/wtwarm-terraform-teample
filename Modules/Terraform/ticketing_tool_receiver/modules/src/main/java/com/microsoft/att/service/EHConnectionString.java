package com.microsoft.att.service;

import com.microsoft.att.Builder.EventHubProducerClientBuilder;

public class EHConnectionString extends EventHubSender {

    public EHConnectionString(String connectionString, String eventHubName) {
        super(new EventHubProducerClientBuilder()
        .withEventHubName(eventHubName)
        .useConnectionString(true)
        .withConnectionString(connectionString));
    }
    
}

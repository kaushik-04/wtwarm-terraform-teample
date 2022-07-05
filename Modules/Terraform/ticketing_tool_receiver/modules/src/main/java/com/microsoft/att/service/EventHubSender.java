package com.microsoft.att.service;

import com.azure.messaging.eventhubs.EventData;
import com.azure.messaging.eventhubs.EventDataBatch;
import com.azure.messaging.eventhubs.EventHubProducerClient;
import com.microsoft.att.Builder.EventHubProducerClientBuilder;

public abstract class EventHubSender {
    protected final EventHubProducerClientBuilder eventHubProducerClientBuilder;

    public EventHubSender(EventHubProducerClientBuilder eventHubProducerClientBuilder) {
        this.eventHubProducerClientBuilder = eventHubProducerClientBuilder;
    }

    public void sendAlert(String alert) {
        EventHubProducerClient eventHubClient = eventHubProducerClientBuilder.build();
        EventDataBatch batch = eventHubClient.createBatch();
        batch.tryAdd(new EventData(alert));
        eventHubClient.send(batch);
        eventHubClient.close();
    }
}

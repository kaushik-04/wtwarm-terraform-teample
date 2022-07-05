package com.microsoft.att.service;

import com.azure.identity.DefaultAzureCredentialBuilder;
import com.microsoft.att.Builder.EventHubProducerClientBuilder;

public class EHManagedIdentity extends EventHubSender {
    private static final String EH_FULLY_QUALIFIED_NAME = "%s.servicebus.windows.net";

    public EHManagedIdentity(String eventHubNamespace, String eventHubName) {
        super(new EventHubProducerClientBuilder()
        .withEventHubName(eventHubName)
        .withFullyQualifiedNamespace(String.format(EH_FULLY_QUALIFIED_NAME, eventHubNamespace))
        .withCredentials(new DefaultAzureCredentialBuilder().build()));
    }


}

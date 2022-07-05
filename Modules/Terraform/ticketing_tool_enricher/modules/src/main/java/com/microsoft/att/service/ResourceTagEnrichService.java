package com.microsoft.att.service;

import com.microsoft.att.builder.AzureBuilder;
import com.microsoft.att.model.AzureAlert;
import com.microsoft.azure.management.Azure;
import com.microsoft.azure.management.resources.GenericResource;
import org.apache.http.client.HttpClient;

import java.util.Map;

public class ResourceTagEnrichService extends EnrichService {

    public ResourceTagEnrichService(HttpClient httpClient) {
        super(httpClient);
    }

    @Override
    public Map<String, String> getAdditionalData(AzureBuilder azureBuilder, AzureAlert azureAlert) throws Exception {
        Azure azure = azureBuilder
                .withSubscriptionId(azureAlert.getSubscriptionId())
                .build();

        if (azureAlert.getResourceId() == null) {
            return null;
        }

        GenericResource resource = azure.genericResources().getById(azureAlert.getResourceId());
        return resource.tags();
    }
    
}

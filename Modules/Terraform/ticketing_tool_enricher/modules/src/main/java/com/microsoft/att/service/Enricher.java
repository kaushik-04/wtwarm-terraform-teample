package com.microsoft.att.service;

import java.util.Map;
import com.microsoft.att.builder.AzureBuilder;
import com.microsoft.att.model.AzureAlert;


/*
 * Implement this interface to extend the additional data append process, 
 * You may also use tne EnrichService abstract if you require calls to the Azure API to retrieve
 * information from Azure resources. 
 */
public interface Enricher {
    Map<String, String> getAdditionalData(AzureBuilder azureBuilder, AzureAlert azureAlert) throws Exception;
}

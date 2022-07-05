package com.microsoft.att.service;

import com.microsoft.att.builder.AzureBuilder;
import com.microsoft.att.model.AzureAlert;

import org.apache.http.client.HttpClient;

import java.util.HashMap;
import java.util.Map;

/* 
 * FOR DISPLAY ONLY
 * this function implements the EnricherService to add additional data retrieved from the function app settings
 * you can add tags as TAG1:VALUE1|TAG2:VALUE2...
 * Including this class in the EnrichFunction constructor will perform the getAdditionalData method and run it.
 * if no data is found in ALERT_CUSTOM_TAGS setting then nothing is appended and the application moves on to the next enricher.
*/
public class AppSettingsEnrichService extends EnrichService {
    private static final String ALERT_CUSTOM_TAGS_KEY = "ALERT_CUSTOM_TAGS";
    private static final String CUSTOM_TAGS_SEPARATOR = "|";
    private static final String TAG_NAMEVALUE_SEPARATOR = ":";

    public AppSettingsEnrichService(HttpClient httpClient) {
        super(httpClient);
    }

    @Override
    public Map<String, String> getAdditionalData(
            AzureBuilder azureBuilder, AzureAlert azureAlert) throws Exception {

        String tagsString = System.getenv(ALERT_CUSTOM_TAGS_KEY);
        if (tagsString == null){
            return null;
        }
        
        String[] tags = tagsString.split(CUSTOM_TAGS_SEPARATOR);
        return createHashMapFromString(tags);
    }

    //////

    private Map<String, String> createHashMapFromString(String[] tags) {
        Map<String, String> results = new HashMap<>();
        for( String tag : tags) {
            String[] retval = tag.split(TAG_NAMEVALUE_SEPARATOR);
            results.put(retval[0], retval[1]);
        }

        return results;
    }
    
}

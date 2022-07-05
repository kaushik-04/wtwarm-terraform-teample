package com.microsoft.att.service;

import java.io.IOException;
import java.util.Map;

import com.microsoft.att.builder.AzureBuilder;
import com.microsoft.att.builder.AzureSubscriptionBuilder;
import com.microsoft.att.model.AzureAlert;
import com.microsoft.att.model.AzureSubscription;
import com.microsoft.azure.credentials.AppServiceMSICredentials;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.auth.InvalidCredentialsException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;

public class SubscriptionEnrichService extends EnrichService {
    private static final String AZURE_API_URL_FORMAT = "%s/subscriptions/%s?api-version=2020-01-01";

    public SubscriptionEnrichService(HttpClient httpClient) {
        super(httpClient);
    }

    @Override
    public Map<String, String> getAdditionalData(AzureBuilder azureBuilder, AzureAlert azureAlert)
            throws InvalidCredentialsException, IOException {
        String authToken = getAuthToken(azureBuilder);
        final HttpResponse subscriptionResponse = getSubscriptionFromAPI(authToken, azureAlert.getSubscriptionId());
        final AzureSubscription subscription = parseSubscriptionResponse(subscriptionResponse);

        if (subscription == null) {
            return null;
        }

        return subscription.getTags();
    }

    //////

    private String getAuthToken(AzureBuilder azureBuilder) throws InvalidCredentialsException, IOException {
        AppServiceMSICredentials credentials = azureBuilder.getAppServiceMSICredentials();
        if (credentials == null) {
            throw new InvalidCredentialsException("could not retrieve valid MSI Credentials");
        }

        return azureBuilder.getAppServiceMSICredentials().getToken(System.getenv("AzureUrlAPI"));
    }

    private HttpResponse getSubscriptionFromAPI(final String authToken, final String subscriptionId) throws IOException {

        HttpClient client = getHttpClient();
        final String url = String.format(AZURE_API_URL_FORMAT, System.getenv("AzureUrlAPI"), subscriptionId);
        final HttpGet getRequest = new HttpGet(url);

        getRequest.addHeader("authorization", String.join(" ", "Bearer", authToken));
        return client.execute(getRequest);
    }

    private AzureSubscription parseSubscriptionResponse(HttpResponse response) throws IOException {
        final int statusCode = response.getStatusLine().getStatusCode();
        if (statusCode != 200) {
            return null;
        }

        final HttpEntity httpEntity = response.getEntity();
        return new AzureSubscriptionBuilder()
            .withHttpEntity(httpEntity)
            .build();
    }
}

package com.microsoft.att;

import com.azure.core.util.logging.ClientLogger;
import com.microsoft.att.builder.AzureBuilder;
import com.microsoft.att.builder.LoggerBuilder;
import com.microsoft.att.model.AzureAlert;
import com.microsoft.att.service.AppSettingsEnrichService;
import com.microsoft.att.service.Enricher;
import com.microsoft.att.service.ResourceTagEnrichService;
import com.microsoft.att.service.SubscriptionEnrichService;
import com.microsoft.azure.functions.*;
import com.microsoft.azure.functions.annotation.AuthorizationLevel;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.HttpTrigger;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.ResponseHandler;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.HttpHeaders;

import java.io.IOException;
import java.net.URL;
import java.util.*;

/**
 * Loops through all classes that inherit from the Enricher interface and
 * attaches the additional data HashMap returned from those classes into the
 * additionalData attribute.
 * 
 * @author Microsoft Services
 * @version 1.0.0 9/9/2020
 * 
 */
public class EnrichFunction {
    private final HttpClient httpClient;
    private Enricher[] enrichers;
    private AzureBuilder azureBuilder;

    /* 
     * Use this constructor to attach the Enricher classes to use for appending additional data.
     * ResourceTagEnrichService: retrieves tags from the resource that generated the alert
     * SubscriptionEnrichService: retrieves tags from the resource subscription
    */
    public EnrichFunction(final HttpClient httpClient, AzureBuilder azureBuilder) {
        this(
            httpClient, 
            azureBuilder
            ,new ResourceTagEnrichService(httpClient)
            ,new SubscriptionEnrichService(httpClient) 
            ,new AppSettingsEnrichService(httpClient)
            );
    }

    public EnrichFunction(final HttpClient httpClient, AzureBuilder azureBuilder, Enricher... enrichers) {
        this.httpClient = httpClient;
        this.azureBuilder = azureBuilder;
        this.enrichers = enrichers;        
    }
    
    // Default Constructor
    public EnrichFunction() throws IOException {
        this(HttpClientBuilder.create().build(), 
        new AzureBuilder());
    }

    @FunctionName("webhook")
    public HttpResponseMessage webhook(@HttpTrigger(name = "req", methods = {
            HttpMethod.POST }, authLevel = AuthorizationLevel.ANONYMOUS) final HttpRequestMessage<Optional<AzureAlert>> request,
            final ExecutionContext context) throws IOException {

        final ClientLogger logger = new LoggerBuilder(EnrichFunction.class).build();
        try {
            AzureAlert azureAlert = request.getBody().get();
            final Map<String, String> additionalData = getAdditionalData(azureAlert, logger);
            if (additionalData.size() > 0) {
                azureAlert = appendAdditionalData(additionalData, azureAlert);
            }

            ResponseHandler<String> responseHandler = createCustomHttpHandler(logger);
            submitAlertToAPI(azureAlert, responseHandler, logger);
            return request.createResponseBuilder(HttpStatus.OK)
            .body(azureAlert).build();
        } catch (final IllegalArgumentException e) {
            logger.info("enter illegal argument exception");
            logger.error(e.toString());
            return request.createResponseBuilder(HttpStatus.BAD_REQUEST).body(e).build();
        } catch (final Exception e) {
            logger.error(e.toString());
            return request.createResponseBuilder(HttpStatus.INTERNAL_SERVER_ERROR).body(e).build();
        }
    }

    //////

    private Map<String, String> getAdditionalData(AzureAlert azureAlert, ClientLogger logger) {
        final Map<String, String> additionalData = new HashMap<>();        

        for (final Enricher enricher : enrichers) {
            final Map<String, String> tags = processEnricher(enricher, azureAlert, logger);
            if (tags != null) {
                additionalData.putAll(tags);
            }
        }
        return additionalData;
    }

    private Map<String, String> processEnricher(final Enricher enricher, final AzureAlert azureAlert,
            final ClientLogger logger) {
        try {
            return enricher.getAdditionalData(azureBuilder, azureAlert);
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
            return null;
        }
    }

    private AzureAlert appendAdditionalData(final Map<String, String> additionalData, AzureAlert azureAlert) {
        for (final Map.Entry<String, String> tag : additionalData.entrySet()) {
            azureAlert.setAdditionalData(tag.getKey(), tag.getValue());
        }

        return azureAlert;
    }

    private void submitAlertToAPI(final AzureAlert azureAlert, ResponseHandler<String> responseHandler, ClientLogger logger) throws IOException {
        final String forwardAlertUrl = System.getenv("ForwardAlertAPI");
        
        logger.info("Validating receiver URL from settings");
        if (forwardAlertUrl == null || forwardAlertUrl.isEmpty()) {
            throw new IllegalArgumentException("The receiver API URL is not setup in settings");
        }

        URL receiverUrl = new URL(forwardAlertUrl);
        final HttpPost post = new HttpPost(receiverUrl.toString());

        logger.info("Getting authorization token for receiver API");
        //String scope = String.format("%s://%s", receiverUrl.getProtocol(), receiverUrl.getHost());
        String scope = System.getenv("ReceiverResourceId");
        String authToken = azureBuilder.getAppServiceMSICredentials().getToken(scope);

        //TokenRequestContext req = new TokenRequestContext().addScopes(System.getenv("ReceiverResourceId"));
        //String authToken = // "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImtnMkxZczJUMENUaklmajRydDZKSXluZW4zOCIsImtpZCI6ImtnMkxZczJUMENUaklmajRydDZKSXluZW4zOCJ9.eyJhdWQiOiJlNWNhNWUzYS1hZWVkLTQ4NDMtOGU1ZC05OGY4MDBlZTJkNTAiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC83MmY5ODhiZi04NmYxLTQxYWYtOTFhYi0yZDdjZDAxMWRiNDcvIiwiaWF0IjoxNjA1Mjk5NTk3LCJuYmYiOjE2MDUyOTk1OTcsImV4cCI6MTYwNTM4NjI5NywiYWlvIjoiRTJSZ1lOQngzZk42T29PcXk1dldmN1dYWmx6OUNRQT0iLCJhcHBpZCI6IjllYTc4Yjk1LTVkZmItNGM5Ni1hNTc3LTkxNzIwOWE5ZTIxNSIsImFwcGlkYWNyIjoiMSIsImlkcCI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0LzcyZjk4OGJmLTg2ZjEtNDFhZi05MWFiLTJkN2NkMDExZGI0Ny8iLCJvaWQiOiIyN2NmODQwMy05NmMwLTQ4MzYtYjY0Ny04NmFkYmFjMWM0ZmMiLCJyaCI6IjAuQVJvQXY0ajVjdkdHcjBHUnF5MTgwQkhiUjVXTHA1NzdYWlpNcFhlUmNnbXA0aFVhQUFBLiIsInJvbGVzIjpbInN1Ym1pdGFsZXJ0cyJdLCJzdWIiOiIyN2NmODQwMy05NmMwLTQ4MzYtYjY0Ny04NmFkYmFjMWM0ZmMiLCJ0aWQiOiI3MmY5ODhiZi04NmYxLTQxYWYtOTFhYi0yZDdjZDAxMWRiNDciLCJ1dGkiOiJyODMtVWFmVXRrQ2Zmdk80SFBBZkFBIiwidmVyIjoiMS4wIn0.pontVLlgCxg5fAaFHopXlZetmUYIcAttTY6lgRVWY3Oetan9PmQ0sJJ6WcSyvGyKgTPG53CC4sAuwO8dIALUsqn634O4WIUjEZ_ZMkIGWSoLSbJDGJ6VDiZnWzlGNXGgkbBVrNGpFAczP66Bn2SfNJzuoizCHqO5Lx5Yp9XgURGagjLhW59_YdCa4k1pEm7OBc7oWWV0tZRWLAChld7_YD3CCjG2FxZQgZmO97qnVjZQmcPmV-qqXk-7S3riQNTep0_VaASlzSS4yQG4F0q_rc2vuv7Osr0BGJX7ZeQmFGZExMyLw-qcURBtFdVFVlEXY7bqoTWt5NPHYO5isPH7dQ";
        //        new DefaultAzureCredentialBuilder().build()
        //        .getToken(req)
        //        .block().getToken();


        logger.info("Posting alert to receiver API");
        post.addHeader(HttpHeaders.AUTHORIZATION, String.join(" ", "Bearer", authToken));
        final StringEntity entity = new StringEntity(azureAlert.toJsonString());
        post.setEntity(entity);
        httpClient.execute(post, responseHandler);
        logger.info("Alert successfully posted");
    }

    private ResponseHandler<String> createCustomHttpHandler(ClientLogger logger) {
        logger.verbose("Create a custom response handler");
        return response -> {
           int status = response.getStatusLine().getStatusCode();
           if (status < 200 || status > 300) {
               logger.error(response.getEntity().getContent().toString());
               throw new ClientProtocolException("Unexpected response communicating with the receiver, got status: " + status);
           }

           return null;
       };
    }


}

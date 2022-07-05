package com.microsoft.att;

import java.net.MalformedURLException;
import java.net.URL;
import java.nio.file.AccessDeniedException;
import java.security.interfaces.RSAPublicKey;
import java.util.Date;
import java.util.Map;
import java.util.Optional;

import com.auth0.jwk.Jwk;
import com.auth0.jwk.JwkException;
import com.auth0.jwk.JwkProvider;
import com.auth0.jwk.UrlJwkProvider;
import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.azure.core.util.logging.ClientLogger;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.microsoft.att.Builder.EventHubProducerClientBuilder;
import com.microsoft.att.Builder.LoggerBuilder;
import com.microsoft.att.Builder.SettingsBuilder;
import com.microsoft.att.service.EHConnectionString;
import com.microsoft.att.service.EventHubSender;
import com.microsoft.att.service.EHManagedIdentity;

import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.HttpMethod;
import com.microsoft.azure.functions.HttpRequestMessage;
import com.microsoft.azure.functions.HttpResponseMessage;
import com.microsoft.azure.functions.HttpStatus;
import com.microsoft.azure.functions.annotation.AuthorizationLevel;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.HttpTrigger;
import org.apache.http.HttpHeaders;
import org.jetbrains.annotations.NotNull;

public class AlertPublisherFunction {
    private static final String ALERT_SUCCESSFULLY_SUBMITTED_TO_EVENT_HUB_MESSAGE = "Alert successfully submitted to event hub";
    private static final String NO_ALERT_RECEIVED_MESSAGE = "No alert received";
    private static final String MS_AAD_ACCESS_TOKEN_HEADER = "X-MS-TOKEN-AAD-ACCESS-TOKEN";
    private static final String EH_FULLY_QUALIFIED_NAME = "%s.servicebus.windows.net";
        
    private EventHubSender eventHubService;

    public AlertPublisherFunction(EventHubSender eventHubService) {

        this.eventHubService = eventHubService;
    }

    public AlertPublisherFunction(){
    }

    @FunctionName("alertpublisher")
    public HttpResponseMessage postAlert(
        @HttpTrigger(
            name = "req",
            methods = { HttpMethod.POST },
            authLevel = AuthorizationLevel.ANONYMOUS
        ) HttpRequestMessage<Optional<String>> request,
        final ExecutionContext context
    )  {
        ClientLogger logger = new LoggerBuilder().build();
        logger.info("Starting alert publisher call");

        logger.verbose("reading configuration settings");
        final SettingsBuilder settings = new SettingsBuilder().build();
        
        try {
            if (settings.getValidateAuthorization()) {
                logger.info("Validating authorization");
                String aadToken = getTokenFromAuthorizationHeader(request.getHeaders(), logger);
                DecodedJWT jwt = retrieveAccessToken(logger, aadToken);
                validateTokenClaims(logger, settings, jwt);
            } else {
                logger.info("Authorization is NOT being validated");
            }

            final String alert = extractAlertFromBody(request.getBody(), logger);
            if (eventHubService == null) {
                eventHubService = getEventHubPublisher(settings, logger);
            }
            sendAlertToEventHub(logger, alert);

            logger.info(ALERT_SUCCESSFULLY_SUBMITTED_TO_EVENT_HUB_MESSAGE);
            return request.createResponseBuilder(HttpStatus.OK)
                    .body(ALERT_SUCCESSFULLY_SUBMITTED_TO_EVENT_HUB_MESSAGE)
                    .build();
        }
        catch (AccessDeniedException ex) {
            logger.error(ex.getMessage(), ex);
            return request.createResponseBuilder(HttpStatus.UNAUTHORIZED)
                    .body(ex)
                    .build();
        }
        catch(MalformedURLException | JwkException | IllegalArgumentException ex) {
            logger.error(ex.getMessage(),ex);
            return request.createResponseBuilder(HttpStatus.BAD_REQUEST)
                    .body(ex)
                    .build();
        }
    }

    private void validateTokenClaims(ClientLogger logger, SettingsBuilder settings, DecodedJWT jwt) throws AccessDeniedException {
        logger.info("validating role exist for:" + settings.getSubmitAlertRole());
        Date today = new Date();
        if (jwt.getClaim("exp").asDate().compareTo(today) < 0) {
            throw new AccessDeniedException("The access token has expired");
        }
        if (jwt.getClaim("roles").isNull() || !jwt.getClaim("roles").asList(String.class).contains(settings.getSubmitAlertRole())) {
            throw new AccessDeniedException("The role to submit alerts was not found in the token roles claim");
        }

        logger.info("access found roles:" + jwt.getClaim("roles").asList(String.class).size());
    }

    private EventHubSender getEventHubPublisher(SettingsBuilder settings, ClientLogger logger) {
        if (settings.getUseConnectionString()) {
            logger.verbose("Building Event Hub client with Connection string");
            return new EHConnectionString(
                    settings.getConnectionString(), settings.getEventHubName());
        }

        logger.verbose("Building Event Hub client with Managed Identity");
        return new EHManagedIdentity(settings.getEventHubNamespace(), settings.getEventHubName());
    }

    @NotNull
    private String extractAlertFromBody(Optional<String> body, ClientLogger logger) {
        // Check request body
        if (body == null || !body.isPresent()) {
            throw new IllegalArgumentException(NO_ALERT_RECEIVED_MESSAGE);
        }

        logger.verbose("extracting alert from the request");
        return body.get();
    }

    private void sendAlertToEventHub(ClientLogger logger, String alert) {
        logger.verbose("Sending alert to Event Hub");
        eventHubService.sendAlert(alert);
        logger.verbose("Alert sent to event hub");
    }

    @NotNull
    private DecodedJWT retrieveAccessToken(ClientLogger logger, String aadToken) throws MalformedURLException, JwkException {
        DecodedJWT jwt = JWT.decode(aadToken);
        logger.verbose("aad token key id:" + jwt.getKeyId());

        JwkProvider provider = new UrlJwkProvider(new URL("https://login.microsoftonline.com/common/discovery/keys"));
        Jwk jwk = provider.get(jwt.getKeyId());
        Algorithm algorithm = Algorithm.RSA256((RSAPublicKey)jwk.getPublicKey(), null);
        algorithm.verify(jwt);
        return jwt;
    }

    private String getTokenFromAuthorizationHeader(Map<String, String> headers, ClientLogger logger) throws AccessDeniedException {
        if (headers.get(MS_AAD_ACCESS_TOKEN_HEADER) != null) {
            logger.verbose("Found AAD Access Token Header");
            return headers.get(MS_AAD_ACCESS_TOKEN_HEADER);
        }
        
        String authorization = headers.get(HttpHeaders.AUTHORIZATION);
        authorization = authorization == null
                ? headers.get(HttpHeaders.AUTHORIZATION.toLowerCase())
                : authorization;

        if (authorization == null || !authorization.startsWith("Bearer")) {
            throw new AccessDeniedException("Invalid authorization header parameters");
        }

        return authorization.substring("Bearer".length()).trim();
    }
}

package com.microsoft.att.service;

import com.microsoft.att.Constants;
import com.microsoft.att.builder.AzureBuilder;
import com.microsoft.att.model.AzureAlert;
import com.microsoft.azure.AzureEnvironment;
import com.microsoft.azure.credentials.AppServiceMSICredentials;
import com.microsoft.azure.functions.HttpRequestMessage;

import org.apache.http.HttpEntity;
import org.apache.http.StatusLine;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

public class AzureSubscriptionServiceTest {
    private SubscriptionEnrichService sut;
    private CloseableHttpClient httpClientStub;
    private CloseableHttpResponse responseStub;
    private StatusLine statusLineStub;
    private HttpEntity fakeEntity;
    private HttpRequestMessage<Optional<String>> requestStub;
    private Logger loggerStub;
    private AzureBuilder azureBuilderStub;

    @BeforeEach
    @SuppressWarnings("unchecked")
    void setUp() throws IOException {
        httpClientStub = mock(CloseableHttpClient.class);
        responseStub = mock(CloseableHttpResponse.class);
        statusLineStub = mock(StatusLine.class);
        fakeEntity = mock(HttpEntity.class);
        requestStub = mock(HttpRequestMessage.class);
        loggerStub = mock(Logger.class);
        azureBuilderStub = mock(AzureBuilder.class);

        sut = new SubscriptionEnrichService(httpClientStub);
    }

    @Test
    public void testGetTagsShouldReturnData() throws Exception {
        // arrange
        fakeWebResponse();
        Map<String, String> expected = new HashMap<>();
        expected.put("appid", "12345");
        AzureAlert alertStub = mock(AzureAlert.class);
        when(alertStub.getSubscriptionId()).thenReturn("fake");
        when(alertStub.getResourceId()).thenReturn("fake");
        when(azureBuilderStub.getAppServiceMSICredentials())
            .thenReturn(mock(AppServiceMSICredentials.class));
        
        // act
        Map<String, String> actual = sut.getAdditionalData(azureBuilderStub, alertStub);

        // assert
        assertEquals(expected, actual);
    }

    //////

    private void fakeWebResponse() throws IOException {
        when(fakeEntity.getContent()).thenReturn(new ByteArrayInputStream(Constants.FAKE_SUBSCRIPTION.getBytes()));
        when(responseStub.getEntity()).thenReturn(fakeEntity);
        when(statusLineStub.getStatusCode()).thenReturn(200);
        when(responseStub.getStatusLine()).thenReturn(statusLineStub);
        when(httpClientStub.execute(any(HttpGet.class))).thenReturn(responseStub);
        when(requestStub.getBody()).thenReturn(Optional.of(Constants.FAKE_ALERT));
        doNothing().when(loggerStub).log(any(Level.class), any(String.class), any(Object.class));
        doNothing().when(loggerStub).info(any(String.class));
    }
}

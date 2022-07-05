package com.microsoft.att;

import com.microsoft.att.builder.AzureAlertBuilder;
import com.microsoft.att.builder.AzureBuilder;
import com.microsoft.att.model.AzureAlert;
import com.microsoft.att.service.Enricher;
import com.microsoft.azure.functions.*;
import com.microsoft.azure.management.Azure;
import junit.framework.TestCase;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.impl.client.CloseableHttpClient;

import java.util.*;
import java.util.logging.Logger;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

public class EnrichFunctionTest extends TestCase {
    private HttpRequestMessage<Optional<AzureAlert>> req;
    private ExecutionContext context;
    private Enricher enricherStub;
    private CloseableHttpClient httpClientStub;
    private AzureBuilder azureStub;

    @BeforeEach
    public void setUp() {
        buildFakeContext();
    }

    @Test
    public void testWebHookShouldReturn200() throws Exception {
        // arrange
        doReturn(Logger.getGlobal()).when(context).getLogger();
        //final AzureSubscriptionService subscriptionServiceStub = mock(AzureSubscriptionService.class);
        httpClientStub = mock(CloseableHttpClient.class);
        enricherStub = mock(Enricher.class);
        azureStub = mock(AzureBuilder.class);
        when(httpClientStub.execute(any(HttpUriRequest.class)));        
                
        // act        
        final HttpResponseMessage ret = new EnrichFunction(
                httpClientStub, azureStub, enricherStub)
        .webhook(req, context);

        // assert
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, ret.getStatus());
    }

    //////

    @SuppressWarnings("unchecked")
    private void buildFakeContext() {
        req = mock(HttpRequestMessage.class);

        final Optional<AzureAlert> queryBody = Optional.of(new AzureAlertBuilder(Constants.FAKE_ALERT).createAzureAlert());
        when(req.getBody()).thenReturn(queryBody);

        doAnswer(new Answer<HttpResponseMessage.Builder>() {
            @Override
            public HttpResponseMessage.Builder answer(final InvocationOnMock invocation) {
                final HttpStatus status = (HttpStatus) invocation.getArguments()[0];
                return new HttpResponseMessageMock.HttpResponseMessageBuilderMock().status(status);
            }
        }).when(req).createResponseBuilder(any(HttpStatus.class));

        context = mock(ExecutionContext.class);
    }
}
 
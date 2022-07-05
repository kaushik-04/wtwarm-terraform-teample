package com.microsoft.att;

import com.auth0.jwk.JwkException;
import com.microsoft.att.service.EventHubSender;
import com.microsoft.azure.functions.*;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;

import java.net.MalformedURLException;
import java.nio.file.AccessDeniedException;
import java.util.*;
import java.util.logging.Logger;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit test for Function class.
 */
public class AlertPublisherFunctionTest {
    private EventHubSender eventHubSvcStub;

    @BeforeEach
    public void setUp() {
        eventHubSvcStub = mock(EventHubSender.class);
        doNothing().when(eventHubSvcStub).sendAlert(any(String.class));
    }

    @Test
    public void testPostEventHubWithNoAlertReturnsBADRequest()  {
        // arrange
        Optional<String> emptyBody = Optional.empty();
        final HttpRequestMessage<Optional<String>> req = fakeHttpRequestMessage(emptyBody);
        final ExecutionContext context = mock(ExecutionContext.class);
        doReturn(Logger.getGlobal()).when(context).getLogger();
        
        // act        
        HttpResponseMessage response = new AlertPublisherFunction(eventHubSvcStub)
        .postAlert(req, context);

        // assert
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatus());
    }

    //////

    private HttpRequestMessage<Optional<String>> fakeHttpRequestMessage(Optional<String> body) {
        // Setup
        @SuppressWarnings("unchecked")
        final HttpRequestMessage<Optional<String>> req = mock(HttpRequestMessage.class);

        final Optional<String> queryBody = body;
        doReturn(queryBody).when(req).getBody();

        doAnswer(new Answer<HttpResponseMessage.Builder>() {
            @Override
            public HttpResponseMessage.Builder answer(InvocationOnMock invocation) {
                HttpStatus status = (HttpStatus) invocation.getArguments()[0];
                return new HttpResponseMessageMock.HttpResponseMessageBuilderMock().status(status);
            }
        }).when(req).createResponseBuilder(any(HttpStatus.class));
        return req;
    }
}

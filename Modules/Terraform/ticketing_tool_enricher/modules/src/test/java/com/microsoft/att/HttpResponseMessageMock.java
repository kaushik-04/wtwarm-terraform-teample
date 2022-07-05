package com.microsoft.att;

import com.microsoft.azure.functions.*;

import java.util.Map;
import java.util.HashMap;

/**
 * The mock for HttpResponseMessage, can be used in unit tests to verify if the
 * returned response by HTTP trigger function is correct or not.
 */
public class HttpResponseMessageMock implements HttpResponseMessage {
    private final int httpStatusCode;
    private final HttpStatusType httpStatus;
    private final Object body;
    private final Map<String, String> headers;

    public HttpResponseMessageMock(final HttpStatusType status, final Map<String, String> headers, final Object body) {
        this.httpStatus = status;
        this.httpStatusCode = status.value();
        this.headers = headers;
        this.body = body;
    }

    @Override
    public HttpStatusType getStatus() {
        return this.httpStatus;
    }

    @Override
    public int getStatusCode() {
        return httpStatusCode;
    }

    @Override
    public String getHeader(final String key) {
        return this.headers.get(key);
    }

    @Override
    public Object getBody() {
        return this.body;
    }

    public static class HttpResponseMessageBuilderMock implements HttpResponseMessage.Builder {
        private Object body;
        
        private final Map<String, String> headers = new HashMap<>();
        private HttpStatusType httpStatus;

        public Builder status(final HttpStatus status) {
            status.value();
            this.httpStatus = status;
            return this;
        }

        @Override
        public Builder status(final HttpStatusType httpStatusType) {
            httpStatusType.value();
            this.httpStatus = httpStatusType;
            return this;
        }

        @Override
        public HttpResponseMessage.Builder header(final String key, final String value) {
            this.headers.put(key, value);
            return this;
        }

        @Override
        public HttpResponseMessage.Builder body(final Object body) {
            this.body = body;
            return this;
        }

        @Override
        public HttpResponseMessage build() {
            return new HttpResponseMessageMock(this.httpStatus, this.headers, this.body);
        }
    }
}

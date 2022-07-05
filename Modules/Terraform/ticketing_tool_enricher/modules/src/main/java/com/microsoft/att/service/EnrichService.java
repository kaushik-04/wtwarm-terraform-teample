package com.microsoft.att.service;

import org.apache.http.client.HttpClient;


public abstract class EnrichService implements Enricher {
    private final HttpClient httpClient;

    public EnrichService(HttpClient httpClient) {
        this.httpClient = httpClient;
    }
    public HttpClient getHttpClient() {
        return httpClient;
    }
}

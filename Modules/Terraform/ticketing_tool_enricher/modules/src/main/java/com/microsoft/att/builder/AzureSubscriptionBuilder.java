package com.microsoft.att.builder;

import java.io.IOException;

import com.google.gson.Gson;
import com.microsoft.att.model.AzureSubscription;

import org.apache.http.HttpEntity;
import org.apache.http.util.EntityUtils;

public class AzureSubscriptionBuilder {
    private HttpEntity httpEntity;

    public AzureSubscriptionBuilder withHttpEntity(HttpEntity httpEntity) {
        this.httpEntity = httpEntity;
        return this;
    }

    public AzureSubscription build() throws IOException {
        final String apiOutput = EntityUtils.toString(httpEntity);
        final Gson gson = new Gson();
        return gson.fromJson(apiOutput, AzureSubscription.class);
   }
}

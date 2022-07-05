package com.microsoft.att.builder;

import com.microsoft.azure.AzureEnvironment;
import com.microsoft.azure.credentials.AppServiceMSICredentials;
import com.microsoft.azure.management.Azure;

public class AzureBuilder {
    private String subscriptionId;
    private AppServiceMSICredentials appServiceMSICredentials;

    public String getSubscriptionId() {
        return subscriptionId;
    }

    public AppServiceMSICredentials getAppServiceMSICredentials() {
        if (appServiceMSICredentials == null) {
            appServiceMSICredentials = new AppServiceMSICredentials(AzureEnvironment.AZURE);
        }

        return appServiceMSICredentials;
    }

    public void setSubscriptionId(String subscriptionId) {
        this.subscriptionId = subscriptionId;
    }

    public AzureBuilder withSubscriptionId(String subscriptionId) {
        setSubscriptionId(subscriptionId);
        return this;
    }

    public Azure build() {
        return Azure
                .authenticate(getAppServiceMSICredentials())
                .withSubscription(getSubscriptionId());
    }
}

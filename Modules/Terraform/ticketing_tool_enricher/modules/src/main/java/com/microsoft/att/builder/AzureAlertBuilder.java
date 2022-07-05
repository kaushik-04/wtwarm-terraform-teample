package com.microsoft.att.builder;

import com.google.gson.Gson;
import com.microsoft.att.model.AzureAlert;

public class AzureAlertBuilder {
    private String requestBody;

    public static final String ILLEGAL_ARGUMENT_MESSAGE ="the specified alert is not valid for processing";
    public final String SCHEMA_ID = "azureMonitorCommonAlertSchema";

    public AzureAlertBuilder(String requestBody) throws IllegalArgumentException {
        if (requestBody == null) throw new IllegalArgumentException(ILLEGAL_ARGUMENT_MESSAGE);
        this.requestBody = requestBody;
    }

    public AzureAlert createAzureAlert() {
         Gson gson = new Gson();
        AzureAlert webhook = gson.fromJson(requestBody, AzureAlert.class);
        validateSerializedAlert(webhook);
        return webhook;
    }

    //////

    private void validateSerializedAlert(AzureAlert webhook) {
        if (!webhook.getSchemaId().contains(SCHEMA_ID)
                || webhook.getData() == null || webhook.getData().getEssentials() == null
                || webhook.getData().getEssentials().getAlertTargetIDs() == null
        ) {
            throw new IllegalArgumentException(ILLEGAL_ARGUMENT_MESSAGE);
        }
    }
}

package com.microsoft.att.model;

import com.google.gson.Gson;
import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class AzureAlert {

    @SerializedName("schemaId")
    @Expose
    private String schemaId;
    @SerializedName("data")
    @Expose
    private Data data;
    @SerializedName("additionalData")
    @Expose
    private Map<String, String> additionalData;

    private String subscriptionId;
    private String resourceId;

    public AzureAlert() {
        additionalData = new HashMap<>();
    }

    public String getSubscriptionId() {
        if (subscriptionId == null) {
            parseSubscriptionId();
        }

        return subscriptionId;
    }

    public String getResourceId() {
        if (resourceId == null) {
            parseResourceId();
        }

        return resourceId;
    }

    public AzureAlert(String schemaId, Data data, Map<String, String> additionalData) {
        this.schemaId = schemaId;
        this.data = data;
        this.additionalData = additionalData;
    }

    public void setAdditionalData(String key, String data) {
        additionalData.put(key, data);
    }

    public Map<String, String> getAdditionalData() {
        return this.additionalData;
    }

    public String getSchemaId() {
        return schemaId;
    }

    public void setSchemaId(String schemaId) {
        this.schemaId = schemaId;
    }

    public Data getData() {
        return data;
    }

    public void setData(Data data) {
        this.data = data;
    }

    public String toJsonString() {
        Gson gson = new Gson();
        return gson.toJson(this);
    }

    //////

    private void parseSubscriptionId() {
        if (data == null || data.getEssentials() == null ||
        data.getEssentials().getAlertTargetIDs().isEmpty() ){
            subscriptionId = null;
        } 

        final Pattern pattern = Pattern.compile("^\\/subscriptions\\/(?<guid>[A-Z0-9\\-]{36})\\/",
                Pattern.CASE_INSENSITIVE);
        String src = data.getEssentials().getAlertTargetIDs().get(0);
        final Matcher match = pattern.matcher(src);
        final boolean matchFound = match.find();
        subscriptionId = matchFound ? match.group("guid") : null;
    }

    private void parseResourceId() {
        boolean noData = getData() == null || getData().getAlertContext() == null;
        boolean noDataConditions = noData || getData().getAlertContext().getCondition() == null;
        boolean noDataAllOf = noDataConditions || getData().getAlertContext().getCondition().getAllOf().isEmpty();
        boolean noDimensions =  noDataAllOf || getData().getAlertContext().getCondition().getAllOf().get(0).getDimensions().isEmpty();
        boolean noResourceIdInfo = noDimensions || getData().getAlertContext()
            .getCondition().getAllOf().get(0).getDimensions().get(0).getValue() == null;

        if (noResourceIdInfo) {
            return;
        }

        resourceId = getData().getAlertContext().getCondition().getAllOf().get(0).getDimensions()
                .get(0).getValue();
    }
}


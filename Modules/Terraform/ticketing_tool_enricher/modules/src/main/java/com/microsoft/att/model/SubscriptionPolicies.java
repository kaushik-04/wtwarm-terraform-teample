package com.microsoft.att.model;

public class SubscriptionPolicies {
    private String locationPlacementId;

    private String quotaId;

    private String spendingLimit;

    public void setLocationPlacementId(String locationPlacementId){
        this.locationPlacementId = locationPlacementId;
    }
    public String getLocationPlacementId(){
        return this.locationPlacementId;
    }
    public void setQuotaId(String quotaId){
        this.quotaId = quotaId;
    }
    public String getQuotaId(){
        return this.quotaId;
    }
    public void setSpendingLimit(String spendingLimit){
        this.spendingLimit = spendingLimit;
    }
    public String getSpendingLimit(){
        return this.spendingLimit;
    }
}

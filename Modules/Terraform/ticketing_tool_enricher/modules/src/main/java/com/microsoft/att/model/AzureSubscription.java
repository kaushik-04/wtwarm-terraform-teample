package com.microsoft.att.model;

import java.util.List;
import java.util.Map;

public class AzureSubscription {
    private String id;

    private String subscriptionId;

    private String tenantId;

    private String displayName;

    private String state;

    private SubscriptionPolicies subscriptionPolicies;

    private String authorizationSource;

    private List<ManagedByTenants> managedByTenants;

    private Map<String, String> tags;

    public void setId(String id){
        this.id = id;
    }
    public String getId(){
        return this.id;
    }
    public void setSubscriptionId(String subscriptionId){
        this.subscriptionId = subscriptionId;
    }
    public String getSubscriptionId(){
        return this.subscriptionId;
    }
    public void setTenantId(String tenantId){
        this.tenantId = tenantId;
    }
    public String getTenantId(){
        return this.tenantId;
    }
    public void setDisplayName(String displayName){
        this.displayName = displayName;
    }
    public String getDisplayName(){
        return this.displayName;
    }
    public void setState(String state){
        this.state = state;
    }
    public String getState(){
        return this.state;
    }
    public void setSubscriptionPolicies(SubscriptionPolicies subscriptionPolicies){
        this.subscriptionPolicies = subscriptionPolicies;
    }
    public SubscriptionPolicies getSubscriptionPolicies(){
        return this.subscriptionPolicies;
    }
    public void setAuthorizationSource(String authorizationSource){
        this.authorizationSource = authorizationSource;
    }
    public String getAuthorizationSource(){
        return this.authorizationSource;
    }
    public void setManagedByTenants(List<ManagedByTenants> managedByTenants){
        this.managedByTenants = managedByTenants;
    }
    public List<ManagedByTenants> getManagedByTenants(){
        return this.managedByTenants;
    }
    public void setTags(Map<String, String> tags){
        this.tags = tags;
    }
    public Map<String, String> getTags(){
        return this.tags;
    }
}

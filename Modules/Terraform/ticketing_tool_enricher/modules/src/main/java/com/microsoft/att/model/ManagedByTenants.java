package com.microsoft.att.model;

public class ManagedByTenants {
    private String tenantId;

    public void setTenantId(String tenantId){
        this.tenantId = tenantId;
    }
    public String getTenantId(){
        return this.tenantId;
    }
}

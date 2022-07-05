package com.microsoft.att.model;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

public class Data {

    @SerializedName("essentials")
    @Expose
    private Essential essentials;
    @SerializedName("alertContext")
    @Expose
    private AlertContext alertContext;

    public Data () {

    }

    public Data(Essential essentials, AlertContext alertContext){
        this.essentials = essentials;
        this.alertContext = alertContext;
    }

    public Essential getEssentials() {
        return essentials;
    }

    public void setEssentials(Essential essentials) {
        this.essentials = essentials;
    }

    public AlertContext getAlertContext() {
        return alertContext;
    }

    public void setAlertContext(AlertContext alertContext) {
        this.alertContext = alertContext;
    }

}

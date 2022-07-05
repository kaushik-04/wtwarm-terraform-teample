package com.microsoft.att.model;

import java.util.List;
import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

public class Essential {

    @SerializedName("alertId")
    @Expose
    private String alertId;
    @SerializedName("alertRule")
    @Expose
    private String alertRule;
    @SerializedName("severity")
    @Expose
    private String severity;
    @SerializedName("signalType")
    @Expose
    private String signalType;
    @SerializedName("monitorCondition")
    @Expose
    private String monitorCondition;
    @SerializedName("monitoringService")
    @Expose
    private String monitoringService;
    @SerializedName("alertTargetIDs")
    @Expose
    private List<String> alertTargetIDs = null;
    @SerializedName("originAlertId")
    @Expose
    private String originAlertId;
    @SerializedName("firedDateTime")
    @Expose
    private String firedDateTime;
    @SerializedName("resolvedDateTime")
    @Expose
    private String resolvedDateTime;
    @SerializedName("description")
    @Expose
    private String description;
    @SerializedName("essentialsVersion")
    @Expose
    private String essentialsVersion;
    @SerializedName("alertContextVersion")
    @Expose
    private String alertContextVersion;

    public String getAlertId() {
        return alertId;
    }

    public void setAlertId(String alertId) {
        this.alertId = alertId;
    }

    public String getAlertRule() {
        return alertRule;
    }

    public void setAlertRule(String alertRule) {
        this.alertRule = alertRule;
    }

    public String getSeverity() {
        return severity;
    }

    public void setSeverity(String severity) {
        this.severity = severity;
    }

    public String getSignalType() {
        return signalType;
    }

    public void setSignalType(String signalType) {
        this.signalType = signalType;
    }

    public String getMonitorCondition() {
        return monitorCondition;
    }

    public void setMonitorCondition(String monitorCondition) {
        this.monitorCondition = monitorCondition;
    }

    public String getMonitoringService() {
        return monitoringService;
    }

    public void setMonitoringService(String monitoringService) {
        this.monitoringService = monitoringService;
    }

    public List<String> getAlertTargetIDs() {
        return alertTargetIDs;
    }

    public void setAlertTargetIDs(List<String> alertTargetIDs) {
        this.alertTargetIDs = alertTargetIDs;
    }

    public String getOriginAlertId() {
        return originAlertId;
    }

    public void setOriginAlertId(String originAlertId) {
        this.originAlertId = originAlertId;
    }

    public String getFiredDateTime() {
        return firedDateTime;
    }

    public void setFiredDateTime(String firedDateTime) {
        this.firedDateTime = firedDateTime;
    }

    public String getResolvedDateTime() {
        return resolvedDateTime;
    }

    public void setResolvedDateTime(String resolvedDateTime) {
        this.resolvedDateTime = resolvedDateTime;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getEssentialsVersion() {
        return essentialsVersion;
    }

    public void setEssentialsVersion(String essentialsVersion) {
        this.essentialsVersion = essentialsVersion;
    }

    public String getAlertContextVersion() {
        return alertContextVersion;
    }

    public void setAlertContextVersion(String alertContextVersion) {
        this.alertContextVersion = alertContextVersion;
    }

}
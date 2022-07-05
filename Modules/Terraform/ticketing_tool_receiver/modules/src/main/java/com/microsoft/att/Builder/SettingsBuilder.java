package com.microsoft.att.Builder;

public class SettingsBuilder {
    private static final String EVENT_HUB_NAME_KEY = "EventHubName";
    private static final String EVENT_HUB_NAMESPACE_KEY = "EventHubNamespace";
    private static final String EVENT_HUB_CONNECTION_STRING_KEY = "EventHubConnectionString";
    private static final String USE_CONNECTION_STRING_KEY = "UseConnectionString";
    private static final String SUBMIT_ALERT_ROLE_KEY = "SubmitAlertRole";
    private static final String VALIDATE_AUTHORIZATION_KEY = "ValidateAuthorization";
    
    String connectionString;
    String eventHubNamespace;
    String eventHubName;
    boolean useConnectionString;
    String submitAlertRole;
    boolean validateAuthorization;

    public boolean getUseConnectionString() {
        return useConnectionString;
    }

    public String getConnectionString() {
        return connectionString;
    }

    public String getEventHubNamespace() {
        return eventHubNamespace;
    }

    public String getEventHubName() {
        return eventHubName;
    }

    public String getSubmitAlertRole() {
        return submitAlertRole;
    }

    public boolean getValidateAuthorization() {
        return validateAuthorization;
    }

    public SettingsBuilder build() {
        useConnectionString = Boolean.parseBoolean(System.getenv(USE_CONNECTION_STRING_KEY));
        connectionString  = System.getenv(EVENT_HUB_CONNECTION_STRING_KEY);
        eventHubNamespace  = System.getenv(EVENT_HUB_NAMESPACE_KEY);
        eventHubName  = System.getenv(EVENT_HUB_NAME_KEY);
        submitAlertRole = System.getenv(SUBMIT_ALERT_ROLE_KEY);
        validateAuthorization = Boolean.parseBoolean(System.getenv(VALIDATE_AUTHORIZATION_KEY));
        return this;
    }


}

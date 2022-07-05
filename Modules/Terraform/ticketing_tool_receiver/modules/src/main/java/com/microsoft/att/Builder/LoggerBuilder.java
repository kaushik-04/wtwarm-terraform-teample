package com.microsoft.att.Builder;

import com.azure.core.util.logging.ClientLogger;
import com.microsoft.applicationinsights.log4j.v1_2.ApplicationInsightsAppender;
import org.apache.log4j.BasicConfigurator;

public class LoggerBuilder {
    private ClientLogger logger;

    public LoggerBuilder() {
        logger = new ClientLogger("$ClassName");
    }

    public ClientLogger build() {
        ApplicationInsightsAppender aiAppender = new ApplicationInsightsAppender();
        aiAppender.setInstrumentationKey(System.getenv("APPINSIGHTS_INSTRUMENTATIONKEY"));

        BasicConfigurator.configure(aiAppender);

        return logger;
    }
}

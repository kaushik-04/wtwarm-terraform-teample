package com.microsoft.att.factory;

import com.microsoft.att.Constants;
import com.microsoft.att.builder.AzureAlertBuilder;
import com.microsoft.att.model.AzureAlert;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class AzureAlertFactoryTest {
    private AzureAlertBuilder sut;

    @Test
    public void testCreateNullDataFails() {
        assertThrows(IllegalArgumentException.class, () ->{
            sut = new AzureAlertBuilder(null);
            AzureAlert actual = sut.createAzureAlert();
            assertNull(actual);
        });
    }

    @Test
    public void testCreateBadDataFails() {
        assertThrows(IllegalArgumentException.class, () ->{
            String data = "{'schemaId': 'azureMonitorCommonAlertSchema'}";
            sut = new AzureAlertBuilder(data);
            AzureAlert actual = sut.createAzureAlert();
            assertNull(actual);
        });
    }

    @Test
    public void testCreateShouldReturnObject() {
        // arrange
        String data = Constants.FAKE_ALERT;
        sut = new AzureAlertBuilder(data);

        // act
        AzureAlert actual = sut.createAzureAlert();

        // assert
        assertNotNull(actual);
    }
}
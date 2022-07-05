package com.microsoft.att.service;

import com.microsoft.att.Constants;
import com.microsoft.att.model.AzureAlert;
import com.microsoft.att.model.Data;
import com.microsoft.att.model.Essential;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.ArrayList;
import java.util.List;

public class SubscriptionParserServiceTest {
    private AzureAlert sut;

    @BeforeEach
    public void setUp() {
        sut = new AzureAlert();
    }

    @Test
    public void testExecuteShouldReturnId() {
        // arrange
        List<String> resourceId = new ArrayList<>();
        resourceId.add(Constants.FAKE_SUBSCRIPTION_URL);        
        String expected = "0fb21625-3946-4f04-8934-f62e93621e1a";
        Essential fakeEssentials= new Essential();
        fakeEssentials.setAlertTargetIDs(resourceId);
        Data fakeData = new Data();
        fakeData.setEssentials(fakeEssentials);                

        // act
        sut.setData(fakeData);
        String actual = sut.getSubscriptionId();

        // expected
        assertEquals(actual, expected);
    }
}

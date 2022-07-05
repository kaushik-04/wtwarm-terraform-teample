package com.microsoft.att.model;

import java.util.List;

public class Condition {
    private List<AllOf> allOf;

    public List<AllOf> getAllOf() {
        return allOf;
    }

    public void setAllOf(List<AllOf> allOf) {
        this.allOf = allOf;
    }
}
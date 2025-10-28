package com.careconnect.model;

public record ActionLinks(String track, String redelivery, String dashboard) {
    public static ActionLinks defaults(String trackUrl) {
        return new ActionLinks(
                trackUrl,
                "https://tools.usps.com/redelivery.htm",
                "https://informeddelivery.usps.com/"
        );
    }
}
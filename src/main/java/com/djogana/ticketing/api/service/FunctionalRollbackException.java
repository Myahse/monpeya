package com.djogana.ticketing.api.service;

import com.djogana.ticketing.api.contracts.Response;

public class FunctionalRollbackException extends RuntimeException {

    private final Response<?> response;

    public FunctionalRollbackException(Response<?> response) {
        super("Functional rollback");
        this.response = response;
    }

    public Response<?> getResponse() {
        return response;
    }
}


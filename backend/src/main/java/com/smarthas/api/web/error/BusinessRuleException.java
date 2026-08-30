package com.smarthas.api.web.error;

/** Violacao de regra de negocio: traduzida para HTTP 422. */
public class BusinessRuleException extends RuntimeException {

    public BusinessRuleException(String message) {
        super(message);
    }
}

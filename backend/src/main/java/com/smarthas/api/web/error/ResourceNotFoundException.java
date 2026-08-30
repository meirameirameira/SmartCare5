package com.smarthas.api.web.error;

/** Recurso inexistente: traduzido para HTTP 404. */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String resource, Object id) {
        super(resource + " nao encontrado(a) para o identificador " + id + ".");
    }

    public ResourceNotFoundException(String message) {
        super(message);
    }
}

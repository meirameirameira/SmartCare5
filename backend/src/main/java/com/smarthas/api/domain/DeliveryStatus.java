package com.smarthas.api.domain;

/** Estagios da entrega de medicamentos (AI Logistics Extension). */
public enum DeliveryStatus {

    CONFIRMED(0),
    PREPARING(1),
    IN_TRANSIT(2),
    DELIVERED(3),
    CANCELLED(-1);

    private final int step;

    DeliveryStatus(int step) {
        this.step = step;
    }

    /** Indice do passo correspondente na trilha exibida no app. */
    public int step() {
        return step;
    }

    /**
     * Regra de negocio do fluxo logistico: so avanca um passo por vez, e um
     * pedido entregue ou cancelado e terminal.
     */
    public boolean canTransitionTo(DeliveryStatus next) {
        if (this == DELIVERED || this == CANCELLED) {
            return false;
        }
        if (next == CANCELLED) {
            return true;
        }
        return next.step == this.step + 1;
    }
}

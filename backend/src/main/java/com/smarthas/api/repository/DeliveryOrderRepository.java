package com.smarthas.api.repository;

import com.smarthas.api.domain.DeliveryOrder;
import com.smarthas.api.domain.DeliveryStatus;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface DeliveryOrderRepository extends JpaRepository<DeliveryOrder, Long> {

    List<DeliveryOrder> findByPatientIdOrderByCreatedAtDesc(Long patientId);

    Optional<DeliveryOrder> findByOrderCode(String orderCode);

    boolean existsByOrderCode(String orderCode);

    long countByStatus(DeliveryStatus status);

    /**
     * Agregacao feita no banco (e nao em memoria) para alimentar o painel:
     * uma linha por status com a respectiva contagem.
     */
    @Query("select d.status, count(d) from DeliveryOrder d group by d.status")
    List<Object[]> countGroupedByStatus();

    @Query("select d from DeliveryOrder d join fetch d.patient order by d.createdAt desc")
    List<DeliveryOrder> findRecentWithPatient(Pageable pageable);
}

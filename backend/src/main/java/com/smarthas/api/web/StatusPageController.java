package com.smarthas.api.web;

import com.smarthas.api.service.AnalyticsService;
import com.smarthas.api.service.DeliveryService;
import com.smarthas.api.service.PatientService;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Painel administrativo renderizado no servidor com Spring MVC + Thymeleaf.
 *
 * <p>Complementa a API JSON: a equipe de operacao acompanha a plataforma pelo
 * navegador, sem depender do app nem do dashboard Angular.</p>
 */
@Controller
public class StatusPageController {

    private static final DateTimeFormatter FORMATTER =
            DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");

    private final AnalyticsService analyticsService;
    private final PatientService patientService;
    private final DeliveryService deliveryService;

    public StatusPageController(AnalyticsService analyticsService, PatientService patientService,
                                DeliveryService deliveryService) {
        this.analyticsService = analyticsService;
        this.patientService = patientService;
        this.deliveryService = deliveryService;
    }

    @GetMapping({"/", "/painel"})
    public String painel(Model model) {
        model.addAttribute("generatedAt", LocalDateTime.now().format(FORMATTER));
        model.addAttribute("overview", analyticsService.overview());
        model.addAttribute("recentPatients", patientService.recent(8));
        model.addAttribute("recentDeliveries", deliveryService.recent(8));
        return "painel";
    }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const _team = [
    (name: 'Felipe Meira Macedo', rm: 'RM 555789', role: 'Dev Android / Flutter'),
    (name: 'Flávio Fujita', rm: 'RM 555085', role: 'Dev Backend / IA'),
    (name: 'Guilherme do Amaral', rm: 'RM 556376', role: 'UX / Product'),
    (name: 'Gustavo Serafim', rm: 'RM 558538', role: 'Infra / DevOps'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 20, 24, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [SmartCareTheme.primaryGreen, SmartCareTheme.primaryGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Text('🏥', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                const Text('SmartCare 5.0',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700)),
                const Text('SmartCare 5.0 — Enterprise Challenge 2026',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Mentorado pela Leroy Merlin',
                      style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EQUIPE',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          letterSpacing: 1.2, color: Colors.grey)),
                  const SizedBox(height: 12),
                  ..._team.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: SmartCareTheme.primaryGreenLight,
                            child: Text(m.name[0],
                                style: const TextStyle(
                                    color: SmartCareTheme.primaryGreen,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(m.rm,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: SmartCareTheme.primaryGreenLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(m.role,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: SmartCareTheme.primaryGreen)),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),
                  const Text('STACK TÉCNICA',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          letterSpacing: 1.2, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: const [
                      'Flutter 3.x', 'Dart', 'Provider', 'Firebase FCM',
                      'Google Maps', 'Open-Meteo API', 'HTTP/REST',
                      'MVVM-like', 'Material Design 3',
                    ].map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: SmartCareTheme.primaryGreenLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(tag,
                          style: const TextStyle(
                              fontSize: 12,
                              color: SmartCareTheme.primaryGreen)),
                    )).toList(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: SmartCareTheme.primaryGreen),
                        foregroundColor: SmartCareTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Voltar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

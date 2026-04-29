const PptxGenJS = require("pptxgenjs");

const pres = new PptxGenJS();
pres.layout = "LAYOUT_16x9";
pres.author = "SmartCare Team";
pres.title = "SmartCare 5.0 - AI Logistics Extension";

// ── Color palette ──────────────────────────────────────────────
const C = {
  primary:   "028090",  // teal trust
  secondary: "00A896",  // mid teal
  accent:    "02C39A",  // bright teal
  dark:      "021B2B",  // deep navy
  darkMid:   "0A3044",  // card bg
  white:     "FFFFFF",
  offWhite:  "F0F8F8",
  lightGray: "E0EFF0",
  textDark:  "0D2C3A",
  textMid:   "1E5060",
  textLight: "5A8A96",
};

// ── Screenshot paths ───────────────────────────────────────────
const IMG = {
  home:       "C:/Users/User/Pictures/Screenshots/app img/Screenshot 2026-04-16 162414.png",
  consultas:  "C:/Users/User/Pictures/Screenshots/app img/Screenshot 2026-04-16 162423.png",
  dashboard:  "C:/Users/User/Pictures/Screenshots/app img/Screenshot 2026-04-16 162429.png",
  iaChat:     "C:/Users/User/Pictures/Screenshots/app img/Screenshot 2026-04-16 162448.png",
};

// ── Reusable helpers ───────────────────────────────────────────
const makeShadow = () => ({ type: "outer", blur: 8, offset: 3, angle: 135, color: "000000", opacity: 0.12 });
const makeCardShadow = () => ({ type: "outer", blur: 12, offset: 4, angle: 135, color: "000000", opacity: 0.10 });
const makeImgShadow = () => ({ type: "outer", blur: 14, offset: 5, angle: 135, color: "000000", opacity: 0.22 });

// Slide footer bar (light slides)
function addFooter(slide, label) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 5.35, w: 10, h: 0.275,
    fill: { color: C.primary },
    line: { color: C.primary }
  });
  slide.addText("SmartCare 5.0  |  AI Logistics Extension  |  Enterprise Challenge – Leroy Merlin", {
    x: 0.2, y: 5.355, w: 7, h: 0.25,
    fontSize: 7, color: C.white, bold: false, valign: "middle", margin: 0
  });
  if (label) {
    slide.addText(label, {
      x: 7.8, y: 5.355, w: 2, h: 0.25,
      fontSize: 7, color: C.white, bold: false, align: "right", valign: "middle", margin: 0
    });
  }
}

// Dark slide footer bar
function addDarkFooter(slide) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 5.35, w: 10, h: 0.275,
    fill: { color: C.accent, transparency: 30 },
    line: { color: C.accent, transparency: 30 }
  });
  slide.addText("Enterprise Challenge  |  Leroy Merlin  |  2024", {
    x: 0.2, y: 5.355, w: 9.6, h: 0.25,
    fontSize: 7, color: C.white, bold: false, align: "center", valign: "middle", margin: 0
  });
}

// Section pill / tag
function addTag(slide, text, x, y) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x, y, w: text.length * 0.085 + 0.3, h: 0.24,
    fill: { color: C.accent, transparency: 15 },
    line: { color: C.accent },
    rectRadius: 0.05
  });
  slide.addText(text, {
    x: x + 0.05, y: y + 0.01, w: text.length * 0.085 + 0.2, h: 0.22,
    fontSize: 7.5, color: C.dark, bold: true, valign: "middle", margin: 0
  });
}

// Stat callout box
function addStatBox(slide, value, label, x, y, w, h) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x, y, w, h,
    fill: { color: C.darkMid },
    line: { color: C.accent, width: 1.5 },
    shadow: makeCardShadow()
  });
  // accent left bar
  slide.addShape(pres.shapes.RECTANGLE, {
    x, y, w: 0.07, h,
    fill: { color: C.accent },
    line: { color: C.accent }
  });
  slide.addText(value, {
    x: x + 0.15, y: y + 0.1, w: w - 0.2, h: h * 0.52,
    fontSize: 22, color: C.accent, bold: true, align: "center", valign: "middle", margin: 0
  });
  slide.addText(label, {
    x: x + 0.1, y: y + h * 0.55, w: w - 0.15, h: h * 0.4,
    fontSize: 8.5, color: C.lightGray, align: "center", valign: "top", margin: 0
  });
}

// White card for light slides
function addCard(slide, x, y, w, h, accentColor) {
  const col = accentColor || C.primary;
  slide.addShape(pres.shapes.RECTANGLE, {
    x, y, w, h,
    fill: { color: C.white },
    line: { color: col, width: 0 },
    shadow: makeCardShadow()
  });
  slide.addShape(pres.shapes.RECTANGLE, {
    x, y, w: 0.06, h,
    fill: { color: col },
    line: { color: col }
  });
}

// Circle icon placeholder
function addCircleIcon(slide, letter, cx, cy, r, bgColor, textColor) {
  const bg = bgColor || C.primary;
  const tc = textColor || C.white;
  slide.addShape(pres.shapes.OVAL, {
    x: cx - r, y: cy - r, w: r * 2, h: r * 2,
    fill: { color: bg },
    line: { color: bg }
  });
  slide.addText(letter, {
    x: cx - r, y: cy - r, w: r * 2, h: r * 2,
    fontSize: r * 30, color: tc, bold: true, align: "center", valign: "middle", margin: 0
  });
}

// Phone frame: white rect behind image + subtle shadow
function addPhoneFrame(slide, x, y, w, h) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x: x - 0.07, y: y - 0.07, w: w + 0.14, h: h + 0.14,
    fill: { color: C.white },
    line: { color: "D0E8EA", width: 1 },
    shadow: makeImgShadow()
  });
}

// ══════════════════════════════════════════════════════════════
// SLIDE 1 – Title / Group Intro
// ══════════════════════════════════════════════════════════════
(function slide1() {
  const s = pres.addSlide();
  s.background = { color: C.dark };

  // Left decorative band
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.45, h: 5.625,
    fill: { color: C.accent },
    line: { color: C.accent }
  });

  // Top decorative strip
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.45, y: 0, w: 9.55, h: 0.08,
    fill: { color: C.secondary },
    line: { color: C.secondary }
  });

  // Brand pill
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.75, y: 0.35, w: 2.2, h: 0.32,
    fill: { color: C.accent, transparency: 20 },
    line: { color: C.accent }
  });
  s.addText("ENTERPRISE CHALLENGE", {
    x: 0.8, y: 0.37, w: 2.1, h: 0.28,
    fontSize: 7.5, color: C.white, bold: true, charSpacing: 2, align: "center", valign: "middle", margin: 0
  });

  // Main title
  s.addText("SmartCare 5.0", {
    x: 0.75, y: 0.82, w: 8.8, h: 0.85,
    fontSize: 48, fontFace: "Georgia", color: C.white, bold: true,
    margin: 0
  });

  // Subtitle
  s.addText("Extensão de Logística com Inteligência Artificial", {
    x: 0.75, y: 1.68, w: 8.8, h: 0.5,
    fontSize: 19, fontFace: "Georgia", color: C.accent,
    bold: false, italic: true, margin: 0
  });

  // Separator line
  s.addShape(pres.shapes.LINE, {
    x: 0.75, y: 2.28, w: 5.5, h: 0,
    line: { color: C.secondary, width: 1.5 }
  });

  // Leroy Merlin mentor label
  s.addText("Mentorado por  LEROY MERLIN", {
    x: 0.75, y: 2.4, w: 5, h: 0.3,
    fontSize: 10, color: C.lightGray, bold: false, charSpacing: 1, margin: 0
  });

  // Team section label
  s.addText("EQUIPE", {
    x: 0.75, y: 2.92, w: 1.5, h: 0.22,
    fontSize: 8, color: C.accent, bold: true, charSpacing: 3, margin: 0
  });
  s.addShape(pres.shapes.LINE, {
    x: 0.75, y: 3.14, w: 8.8, h: 0,
    line: { color: C.darkMid, width: 0.75 }
  });

  // Team members – two columns of 2
  const members = [
    { name: "Felipe Meira Macedo",  rm: "RM 555789" },
    { name: "Flávio Fujita",        rm: "RM 555085" },
    { name: "Guilherme do Amaral",  rm: "RM 556376" },
    { name: "Gustavo Serafim",      rm: "RM 558538" },
  ];

  const cols = [0.75, 5.2];
  const rows = [3.22, 4.05];

  members.forEach((m, i) => {
    const col = i % 2;
    const row = Math.floor(i / 2);
    const x = cols[col];
    const y = rows[row];

    // Avatar circle
    addCircleIcon(s, m.name[0], x + 0.28, y + 0.28, 0.28, C.primary, C.white);

    // Name
    s.addText(m.name, {
      x: x + 0.65, y: y + 0.05, w: 3.8, h: 0.32,
      fontSize: 12, fontFace: "Georgia", color: C.white, bold: true, valign: "middle", margin: 0
    });
    s.addText(m.rm, {
      x: x + 0.65, y: y + 0.34, w: 3.8, h: 0.22,
      fontSize: 9, color: C.textLight, valign: "middle", margin: 0
    });
  });

  addDarkFooter(s);
})();

// ══════════════════════════════════════════════════════════════
// SLIDE 2 – Contexto e Problema
// ══════════════════════════════════════════════════════════════
(function slide2() {
  const s = pres.addSlide();
  s.background = { color: C.offWhite };

  // Header bar
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 0.9,
    fill: { color: C.dark },
    line: { color: C.dark }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.35, h: 0.9,
    fill: { color: C.accent },
    line: { color: C.accent }
  });
  s.addText("CONTEXTO & PROBLEMA", {
    x: 0.55, y: 0.05, w: 8, h: 0.42,
    fontSize: 20, fontFace: "Georgia", color: C.white, bold: true, valign: "bottom", margin: 0
  });
  s.addText("O que o SmartCare resolve — e por que isso importa agora", {
    x: 0.55, y: 0.47, w: 8.5, h: 0.3,
    fontSize: 10, color: C.lightGray, italic: true, valign: "top", margin: 0
  });

  // Left column – context text
  s.addText("Sociedade 5.0", {
    x: 0.4, y: 1.08, w: 4.5, h: 0.3,
    fontSize: 13, fontFace: "Georgia", color: C.primary, bold: true, margin: 0
  });
  s.addText([
    { text: "A Sociedade 5.0 propõe um modelo ", options: { breakLine: false } },
    { text: "centrado no ser humano", options: { bold: true, breakLine: false } },
    { text: ", onde IA, dados e conectividade resolvem desafios sociais reais — saúde, bem-estar e qualidade de vida.", options: { breakLine: false } }
  ], {
    x: 0.4, y: 1.42, w: 4.45, h: 0.8,
    fontSize: 10.5, color: C.textDark, valign: "top", margin: 0
  });

  // Problem bullets
  s.addText("O problema atual:", {
    x: 0.4, y: 2.32, w: 4.5, h: 0.28,
    fontSize: 12, fontFace: "Georgia", color: C.primary, bold: true, margin: 0
  });
  const problems = [
    "Baixa adesão a rotinas de autocuidado e prevenção",
    "Dificuldade de acompanhar sinais do próprio corpo",
    "Falta de suporte no momento certo",
    "Sobrecarga dos serviços de atendimento de saúde",
    "Ausência de visibilidade sobre filas e tempos de espera",
  ];
  s.addText(problems.map((p, i) => ({
    text: p,
    options: { bullet: true, breakLine: i < problems.length - 1, fontSize: 10, color: C.textDark }
  })), {
    x: 0.4, y: 2.65, w: 4.5, h: 1.8,
    fontSize: 10, color: C.textDark, valign: "top", margin: 0
  });

  // Right column – stat boxes
  const stats = [
    { v: "73%",  l: "das pessoas não seguem rotinas\nde saúde preventiva" },
    { v: "2.4h", l: "tempo médio de espera\nem unidades de saúde" },
    { v: "5.0",  l: "Society – tecnologia a\nserviço da humanidade" },
  ];
  stats.forEach((st, i) => {
    addStatBox(s, st.v, st.l, 5.25, 1.1 + i * 1.42, 4.35, 1.2);
  });

  addFooter(s, "02 / 09");
})();

// ══════════════════════════════════════════════════════════════
// SLIDE 3 – SmartCare Solution  (REDESIGNED with screenshots)
// ══════════════════════════════════════════════════════════════
(function slide3() {
  const s = pres.addSlide();
  s.background = { color: C.offWhite };

  // Header
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 0.9,
    fill: { color: C.dark },
    line: { color: C.dark }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.35, h: 0.9,
    fill: { color: C.secondary },
    line: { color: C.secondary }
  });
  s.addText("SMARTCARE 5.0 — A SOLUÇÃO", {
    x: 0.55, y: 0.05, w: 8, h: 0.42,
    fontSize: 20, fontFace: "Georgia", color: C.white, bold: true, valign: "bottom", margin: 0
  });
  s.addText("Aplicativo mobile Kotlin de apoio ao autocuidado e prevenção em saúde", {
    x: 0.55, y: 0.47, w: 8.5, h: 0.3,
    fontSize: 10, color: C.lightGray, italic: true, valign: "top", margin: 0
  });

  // ── LEFT HALF: description + Kotlin badge + 6 feature cards (2 rows × 3) ──
  // Left content zone: x=0.38 to ~5.6" (width ~5.2")
  const leftW = 5.2;

  // Description block (compact, 1 line)
  s.addText(
    "App Android (Kotlin) para rotinas, monitoramento de hábitos e insights de saúde. " +
    "Foco em prevenção, autonomia e experiência 5.0.",
    {
      x: 0.38, y: 1.0, w: 3.85, h: 0.55,
      fontSize: 9.5, color: C.textDark, valign: "middle", margin: 0
    }
  );

  // Kotlin badge — right of description, same row
  s.addShape(pres.shapes.RECTANGLE, {
    x: 4.3, y: 1.03, w: 1.55, h: 0.28,
    fill: { color: C.primary },
    line: { color: C.accent }
  });
  s.addText("Kotlin · Android", {
    x: 4.3, y: 1.04, w: 1.55, h: 0.26,
    fontSize: 8.5, color: C.white, bold: true, align: "center", valign: "middle", margin: 0
  });

  // Feature cards – 2 rows × 3 cols, narrower to fit left half
  const features = [
    { icon: "R", title: "Rotinas & Lembretes", desc: "Hidratação, pausas, sono e atividade" },
    { icon: "C", title: "Check-ins Diários",   desc: "Registro de hábitos, sintomas e estado" },
    { icon: "P", title: "Painel de Evolução",  desc: "Gráficos semanais/mensais de progresso" },
    { icon: "A", title: "Alertas Preventivos", desc: "Detecção de padrões de baixa regularidade" },
    { icon: "G", title: "Agenda Pessoal",       desc: "Consultas, exames e metas unificadas" },
    { icon: "I", title: "Insights com IA",      desc: "Recomendações baseadas nos dados do usuário" },
  ];

  const cardW = 1.68;
  const cardH = 1.08;
  const cardGapX = 0.12;
  const cardGapY = 0.14;
  const cardsStartX = 0.38;
  const cardsStartY = 1.65;

  features.forEach((f, i) => {
    const col = i % 3;
    const row = Math.floor(i / 3);
    const x = cardsStartX + col * (cardW + cardGapX);
    const y = cardsStartY + row * (cardH + cardGapY);

    // Card background
    s.addShape(pres.shapes.RECTANGLE, {
      x, y, w: cardW, h: cardH,
      fill: { color: C.white },
      line: { color: C.lightGray, width: 1 },
      shadow: makeCardShadow()
    });
    // Top accent
    s.addShape(pres.shapes.RECTANGLE, {
      x, y, w: cardW, h: 0.05,
      fill: { color: (i < 3 ? C.primary : C.secondary) },
      line: { color: (i < 3 ? C.primary : C.secondary) }
    });
    // Icon circle (smaller to fit narrow card)
    addCircleIcon(s, f.icon, x + 0.23, y + 0.37, 0.17, (i < 3 ? C.primary : C.secondary), C.white);
    // Title
    s.addText(f.title, {
      x: x + 0.48, y: y + 0.1, w: cardW - 0.55, h: 0.26,
      fontSize: 7.8, color: C.textDark, bold: true, valign: "middle", margin: 0
    });
    // Desc
    s.addText(f.desc, {
      x: x + 0.48, y: y + 0.36, w: cardW - 0.55, h: 0.62,
      fontSize: 7.5, color: C.textMid, valign: "top", margin: 0
    });
  });

  // ── RIGHT HALF: 2 phone screenshots side by side ──
  // Right zone: x=5.85 to 9.95 (~4.1" wide), y=0.95 to 5.3 (~4.35" tall)
  // Place 2 images SIDE BY SIDE — each ~1.85" wide × 3.9" tall
  const rightZoneX = 5.85;
  const rightZoneW = 3.95;
  const imgW = 1.82;
  const imgH = 3.85;
  const imgGap = 0.14;
  // Center the pair horizontally in right zone
  const pairTotalW = imgW * 2 + imgGap;
  const pairStartX = rightZoneX + (rightZoneW - pairTotalW) / 2;
  const imgY = 1.0;

  // LEFT screenshot: Home screen
  const leftImgX = pairStartX;
  addPhoneFrame(s, leftImgX, imgY, imgW, imgH);
  s.addImage({
    path: IMG.home,
    x: leftImgX, y: imgY, w: imgW, h: imgH,
  });
  s.addText("Início · Score de Saúde", {
    x: leftImgX - 0.05, y: imgY + imgH + 0.1, w: imgW + 0.1, h: 0.2,
    fontSize: 6.5, color: C.primary, bold: true, align: "center", margin: 0
  });

  // RIGHT screenshot: Dashboard Clínico
  const rightImgX = pairStartX + imgW + imgGap;
  addPhoneFrame(s, rightImgX, imgY, imgW, imgH);
  s.addImage({
    path: IMG.dashboard,
    x: rightImgX, y: imgY, w: imgW, h: imgH,
  });
  s.addText("Dashboard Clínico", {
    x: rightImgX - 0.05, y: imgY + imgH + 0.1, w: imgW + 0.1, h: 0.2,
    fontSize: 6.5, color: C.primary, bold: true, align: "center", margin: 0
  });

  addFooter(s, "03 / 09");
})();

// ══════════════════════════════════════════════════════════════
// SLIDE 4 – AI Logistics Extension Proposal
// ══════════════════════════════════════════════════════════════
(function slide4() {
  const s = pres.addSlide();
  s.background = { color: C.dark };

  // Left accent band
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.45, h: 5.625,
    fill: { color: C.accent },
    line: { color: C.accent }
  });

  // Title area
  s.addText("PROPOSTA", {
    x: 0.65, y: 0.2, w: 8.5, h: 0.28,
    fontSize: 9, color: C.accent, bold: true, charSpacing: 4, margin: 0
  });
  s.addText("Extensão de Logística com IA", {
    x: 0.65, y: 0.48, w: 8.5, h: 0.65,
    fontSize: 30, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });
  s.addText("Uma nova camada inteligente sobre o SmartCare — focada em experiência 5.0", {
    x: 0.65, y: 1.13, w: 8.5, h: 0.32,
    fontSize: 11, color: C.lightGray, italic: true, margin: 0
  });

  // Separator
  s.addShape(pres.shapes.LINE, {
    x: 0.65, y: 1.55, w: 9, h: 0,
    line: { color: C.darkMid, width: 1 }
  });

  // Pillars – 4 dark cards
  const pillars = [
    { icon: "⏱", title: "IA Preditiva", desc: "Modelos ML preveem o tempo de atendimento com base em histórico, hora do dia e volume de pacientes" },
    { icon: "📍", title: "Patient Tracking", desc: "Acompanhamento em tempo real da jornada do paciente: filas, exames, consultas e saída" },
    { icon: "🔔", title: "Notificações Proativas", desc: "Alertas personalizados: \"Você será atendido em 12 min\" — elimina incerteza e reduz ansiedade" },
    { icon: "✅", title: "Experiência 5.0", desc: "Healthcare-as-a-Service: transparente, eficiente e centrado no paciente como cidadão digital" },
  ];

  pillars.forEach((p, i) => {
    const x = 0.55 + i * 2.35;
    const y = 1.72;
    const w = 2.22;
    const h = 3.35;

    s.addShape(pres.shapes.RECTANGLE, {
      x, y, w, h,
      fill: { color: C.darkMid },
      line: { color: C.accent, width: 1 },
      shadow: makeCardShadow()
    });
    // top accent bar
    s.addShape(pres.shapes.RECTANGLE, {
      x, y, w, h: 0.07,
      fill: { color: C.accent },
      line: { color: C.accent }
    });

    // Icon circle
    addCircleIcon(s, p.icon, x + w / 2, y + 0.55, 0.32, C.primary, C.white);

    // Title
    s.addText(p.title, {
      x: x + 0.1, y: y + 1.0, w: w - 0.2, h: 0.38,
      fontSize: 11, fontFace: "Georgia", color: C.accent, bold: true, align: "center", valign: "middle", margin: 0
    });

    // Desc
    s.addText(p.desc, {
      x: x + 0.12, y: y + 1.42, w: w - 0.24, h: 1.7,
      fontSize: 9, color: C.lightGray, align: "center", valign: "top", margin: 0
    });
  });

  addDarkFooter(s);
  s.addText("04 / 09", {
    x: 8.5, y: 5.355, w: 1.3, h: 0.25,
    fontSize: 7, color: C.white, bold: false, align: "right", valign: "middle", margin: 0
  });
})();

// ══════════════════════════════════════════════════════════════
// SLIDE 5 – Tracking + AI Predictions  (REDESIGNED with screenshot)
// ══════════════════════════════════════════════════════════════
(function slide5() {
  const s = pres.addSlide();
  s.background = { color: C.offWhite };

  // Header
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 0.9,
    fill: { color: C.dark },
    line: { color: C.dark }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.35, h: 0.9,
    fill: { color: C.accent },
    line: { color: C.accent }
  });
  s.addText("TRACKING & PREDIÇÕES COM IA", {
    x: 0.55, y: 0.05, w: 8, h: 0.42,
    fontSize: 20, fontFace: "Georgia", color: C.white, bold: true, valign: "bottom", margin: 0
  });
  s.addText("Visibilidade completa da jornada do paciente — do registro ao atendimento", {
    x: 0.55, y: 0.47, w: 8.5, h: 0.3,
    fontSize: 10, color: C.lightGray, italic: true, valign: "top", margin: 0
  });

  // ── LEFT 60%: Journey flow + AI input cards ──
  const leftW = 6.0;

  // Journey flow — 5 steps connected, fit within left 6"
  const steps = [
    { label: "Check-in Digital",   icon: "C" },
    { label: "Fila Inteligente",   icon: "F" },
    { label: "Exames Tracking",    icon: "E" },
    { label: "Consulta Agendada",  icon: "A" },
    { label: "Alta & Feedback",    icon: "V" },
  ];
  const stepW = 1.08;
  const startX = 0.38;
  const stepY = 0.98;

  steps.forEach((st, i) => {
    const x = startX + i * (stepW + 0.12);
    addCircleIcon(s, st.icon, x + stepW / 2, stepY + 0.3, 0.26, C.primary, C.white);
    s.addText(st.label, {
      x: x, y: stepY + 0.62, w: stepW, h: 0.28,
      fontSize: 7, color: C.textDark, align: "center", bold: true, valign: "top", margin: 0
    });
    if (i < steps.length - 1) {
      s.addShape(pres.shapes.RECTANGLE, {
        x: x + stepW + 0.02, y: stepY + 0.26, w: 0.08, h: 0.08,
        fill: { color: C.accent },
        line: { color: C.accent }
      });
    }
  });

  // AI model heading
  s.addText("Como a IA Prediz o Tempo de Atendimento", {
    x: 0.38, y: 2.02, w: leftW - 0.2, h: 0.3,
    fontSize: 11, fontFace: "Georgia", color: C.primary, bold: true, margin: 0
  });

  // Three input cards — narrower to fit left 60%
  const inputs = [
    { title: "Dados de Entrada", items: ["Histórico de atendimentos", "Volume atual de pacientes", "Horário e dia da semana", "Tipo de consulta/exame"] },
    { title: "Modelo ML",        items: ["Random Forest / XGBoost", "Treinado em dados reais", "Atualização contínua", "Precisão monitorada"] },
    { title: "Output",           items: ["Tempo estimado (min)", "Margem de confiança (%)", "Alerta ao paciente (app)", "Dashboard p/ gestores"] },
  ];

  const cardW3 = 1.87;
  inputs.forEach((inp, i) => {
    const x = 0.38 + i * (cardW3 + 0.14);
    const y = 2.4;
    const cardHeight = 2.6;
    addCard(s, x, y, cardW3, cardHeight, [C.primary, C.secondary, C.accent][i]);
    s.addText(inp.title, {
      x: x + 0.13, y: y + 0.1, w: cardW3 - 0.18, h: 0.3,
      fontSize: 9.5, color: C.textDark, bold: true, fontFace: "Georgia", margin: 0
    });
    s.addText(inp.items.map((it, j) => ({
      text: it,
      options: { bullet: true, breakLine: j < inp.items.length - 1, fontSize: 8.5, color: C.textMid }
    })), {
      x: x + 0.13, y: y + 0.45, w: cardW3 - 0.18, h: 2.1,
      fontSize: 8.5, color: C.textMid, valign: "top", margin: 0
    });

    // Arrow between cards
    if (i < inputs.length - 1) {
      s.addShape(pres.shapes.RECTANGLE, {
        x: x + cardW3 + 0.02, y: y + 1.2, w: 0.1, h: 0.1,
        fill: { color: C.accent },
        line: { color: C.accent }
      });
    }
  });

  // ── RIGHT 40%: Consultas & Agenda screenshot ──
  const imgW = 2.2;
  const imgH = 3.5;
  const rightZoneX = 6.25;
  const imgX = rightZoneX + (10 - rightZoneX - imgW) / 2; // centered in right zone
  const imgY = 0.95;

  addPhoneFrame(s, imgX, imgY, imgW, imgH);
  s.addImage({
    path: IMG.consultas,
    x: imgX, y: imgY, w: imgW, h: imgH,
  });

  // Label below screenshot
  s.addText("Fila Inteligente em tempo real", {
    x: imgX - 0.1, y: imgY + imgH + 0.12, w: imgW + 0.2, h: 0.24,
    fontSize: 7.5, color: C.primary, bold: true, align: "center", margin: 0
  });

  addFooter(s, "05 / 09");
})();

// ══════════════════════════════════════════════════════════════
// SLIDE 6 – Proactive Communication  (REDESIGNED with IA chat screenshot)
// ══════════════════════════════════════════════════════════════
(function slide6() {
  const s = pres.addSlide();
  s.background = { color: C.dark };

  // Left accent band
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.45, h: 5.625,
    fill: { color: C.secondary },
    line: { color: C.secondary }
  });

  // Title area
  s.addText("COMUNICAÇÃO PROATIVA", {
    x: 0.65, y: 0.2, w: 8.5, h: 0.28,
    fontSize: 9, color: C.secondary, bold: true, charSpacing: 4, margin: 0
  });
  s.addText("Notificações Inteligentes em Tempo Real", {
    x: 0.65, y: 0.48, w: 5.5, h: 0.55,
    fontSize: 17.5, fontFace: "Georgia", color: C.white, bold: true, margin: 0
  });

  // ── LEFT 55%: notification mockup + benefits ──
  const leftContentW = 5.2;

  // Notification mockup card
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.65, y: 1.2, w: leftContentW, h: 1.5,
    fill: { color: C.darkMid },
    line: { color: C.accent, width: 2 },
    shadow: makeCardShadow()
  });
  // notification icon
  addCircleIcon(s, "🔔", 1.15, 1.67, 0.28, C.accent, C.dark);
  s.addText("SmartCare", {
    x: 1.55, y: 1.27, w: 1.8, h: 0.26,
    fontSize: 9, color: C.accent, bold: true, margin: 0
  });
  s.addText("agora", {
    x: 4.5, y: 1.27, w: 1.2, h: 0.26,
    fontSize: 8, color: C.textLight, align: "right", margin: 0
  });
  s.addText('"Você será atendido em 12 min"', {
    x: 0.75, y: 1.52, w: leftContentW - 0.2, h: 0.44,
    fontSize: 14, fontFace: "Georgia", color: C.white, bold: true, italic: true,
    align: "center", margin: 0
  });
  s.addText("Dr. Silva está pronto. Dirija-se à recepção.", {
    x: 0.75, y: 1.96, w: leftContentW - 0.2, h: 0.28,
    fontSize: 9, color: C.lightGray, align: "center", margin: 0
  });

  // Benefits – 4 cards in 2×2 grid on left half
  const benefits = [
    { icon: "Z",  title: "Zero Incerteza",      desc: "Sabe exatamente quando será atendido" },
    { icon: "P",  title: "Personalização Total", desc: "Mensagem adaptada ao tipo de consulta" },
    { icon: "T",  title: "Tempo Real",           desc: "Atualização dinâmica conforme a situação" },
    { icon: "E",  title: "Experiência 5.0",      desc: "Saúde transparente e centrada no paciente" },
  ];

  benefits.forEach((b, i) => {
    const col = i % 2;
    const row = Math.floor(i / 2);
    const cardW = 2.48;
    const x = 0.65 + col * (cardW + 0.14);
    const y = 2.9 + row * 0.84;

    s.addShape(pres.shapes.RECTANGLE, {
      x, y, w: cardW, h: 0.72,
      fill: { color: C.darkMid },
      line: { color: C.darkMid },
      shadow: makeCardShadow()
    });
    s.addShape(pres.shapes.RECTANGLE, {
      x, y, w: 0.06, h: 0.72,
      fill: { color: C.secondary },
      line: { color: C.secondary }
    });
    addCircleIcon(s, b.icon, x + 0.38, y + 0.36, 0.22, C.primary, C.white);
    s.addText(b.title, {
      x: x + 0.68, y: y + 0.06, w: cardW - 0.78, h: 0.26,
      fontSize: 9.5, color: C.white, bold: true, fontFace: "Georgia", margin: 0
    });
    s.addText(b.desc, {
      x: x + 0.68, y: y + 0.32, w: cardW - 0.78, h: 0.3,
      fontSize: 8.5, color: C.lightGray, margin: 0
    });
  });

  // ── RIGHT 45%: IA SmartCare Chat screenshot ──
  const imgW = 2.2;
  const imgH = 3.5;
  const rightZoneX = 6.25;
  const imgX = rightZoneX + (10 - rightZoneX - imgW) / 2;
  const imgY = 1.15;

  addPhoneFrame(s, imgX, imgY, imgW, imgH);
  s.addImage({
    path: IMG.iaChat,
    x: imgX, y: imgY, w: imgW, h: imgH,
  });

  // Label below screenshot
  s.addText("Assistente IA SmartCare", {
    x: imgX - 0.1, y: imgY + imgH + 0.12, w: imgW + 0.2, h: 0.24,
    fontSize: 7.5, color: C.secondary, bold: true, align: "center", margin: 0
  });

  addDarkFooter(s);
  s.addText("06 / 09", {
    x: 8.5, y: 5.355, w: 1.3, h: 0.25,
    fontSize: 7, color: C.white, bold: false, align: "right", valign: "middle", margin: 0
  });
})();

// ══════════════════════════════════════════════════════════════
// SLIDE 7 – Technology Stack + AI/Data Science
// ══════════════════════════════════════════════════════════════
(function slide7() {
  const s = pres.addSlide();
  s.background = { color: C.offWhite };

  // Header
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 0.9,
    fill: { color: C.dark },
    line: { color: C.dark }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.35, h: 0.9,
    fill: { color: C.primary },
    line: { color: C.primary }
  });
  s.addText("STACK TECNOLÓGICO & IA", {
    x: 0.55, y: 0.05, w: 8, h: 0.42,
    fontSize: 20, fontFace: "Georgia", color: C.white, bold: true, valign: "bottom", margin: 0
  });
  s.addText("Arquitetura moderna, escalável e orientada a dados", {
    x: 0.55, y: 0.47, w: 8.5, h: 0.3,
    fontSize: 10, color: C.lightGray, italic: true, valign: "top", margin: 0
  });

  // Left column – Mobile + Backend
  const leftSections = [
    {
      title: "Mobile (Android)",
      color: C.primary,
      items: ["Kotlin + Jetpack Compose", "MVVM Architecture", "Room DB (local)", "Retrofit / OkHttp", "Firebase Push Notifications"]
    },
    {
      title: "Backend / Cloud",
      color: C.secondary,
      items: ["API RESTful (Node/Python)", "PostgreSQL + Redis Cache", "Docker + Kubernetes", "Firebase Auth & Firestore", "CI/CD com GitHub Actions"]
    }
  ];

  leftSections.forEach((sec, i) => {
    const y = 1.08 + i * 2.08;
    addCard(s, 0.38, y, 4.35, 1.82, sec.color);
    s.addText(sec.title, {
      x: 0.54, y: y + 0.08, w: 4.1, h: 0.32,
      fontSize: 12, fontFace: "Georgia", color: C.textDark, bold: true, margin: 0
    });
    s.addText(sec.items.map((it, j) => ({
      text: it,
      options: { bullet: true, breakLine: j < sec.items.length - 1, fontSize: 9.5, color: C.textMid }
    })), {
      x: 0.54, y: y + 0.44, w: 4.1, h: 1.3,
      fontSize: 9.5, color: C.textMid, valign: "top", margin: 0
    });
  });

  // Right column – AI/Data
  addCard(s, 5.1, 1.08, 4.52, 3.82, C.accent);
  s.addText("IA & Data Science", {
    x: 5.26, y: 1.16, w: 4.25, h: 0.32,
    fontSize: 12, fontFace: "Georgia", color: C.textDark, bold: true, margin: 0
  });

  const aiItems = [
    { label: "Modelo de Predição", detail: "Random Forest / XGBoost para tempo de espera" },
    { label: "Dados de Treino", detail: "Histórico de atendimentos, calendário e volume" },
    { label: "Pipeline ML", detail: "Python (scikit-learn, pandas) + MLflow tracking" },
    { label: "Serving", detail: "FastAPI endpoint consumido pelo app Android" },
    { label: "Monitoramento", detail: "Drift detection, retraining automático mensal" },
    { label: "Privacidade", detail: "Dados anonimizados, LGPD-compliant" },
  ];

  aiItems.forEach((item, i) => {
    const y = 1.56 + i * 0.56;
    s.addShape(pres.shapes.RECTANGLE, {
      x: 5.1, y, w: 4.52, h: 0.5,
      fill: { color: (i % 2 === 0 ? C.lightGray : C.white) },
      line: { color: C.lightGray, width: 0.5 }
    });
    s.addText(item.label, {
      x: 5.2, y: y + 0.04, w: 1.8, h: 0.22,
      fontSize: 9, color: C.primary, bold: true, margin: 0
    });
    s.addText(item.detail, {
      x: 5.2, y: y + 0.24, w: 4.3, h: 0.22,
      fontSize: 8.5, color: C.textMid, margin: 0
    });
  });

  addFooter(s, "07 / 09");
})();

// ══════════════════════════════════════════════════════════════
// SLIDE 8 – Impact & Delivery Experience 5.0
// ══════════════════════════════════════════════════════════════
(function slide8() {
  const s = pres.addSlide();
  s.background = { color: C.offWhite };

  // Header
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 10, h: 0.9,
    fill: { color: C.dark },
    line: { color: C.dark }
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.35, h: 0.9,
    fill: { color: C.accent },
    line: { color: C.accent }
  });
  s.addText("IMPACTO & EXPERIÊNCIA 5.0", {
    x: 0.55, y: 0.05, w: 8, h: 0.42,
    fontSize: 20, fontFace: "Georgia", color: C.white, bold: true, valign: "bottom", margin: 0
  });
  s.addText("Resultados esperados e a visão de saúde como serviço centrado no cidadão", {
    x: 0.55, y: 0.47, w: 8.5, h: 0.3,
    fontSize: 10, color: C.lightGray, italic: true, valign: "top", margin: 0
  });

  // Top stats row
  const impactStats = [
    { v: "40%",   l: "Redução no tempo\nde espera percebido" },
    { v: "85%",   l: "Satisfação\ndo paciente" },
    { v: "3x",    l: "Engajamento\ncom o app" },
    { v: "100%",  l: "Transparência\nna jornada" },
  ];

  impactStats.forEach((st, i) => {
    const x = 0.38 + i * 2.38;
    s.addShape(pres.shapes.RECTANGLE, {
      x, y: 1.08, w: 2.2, h: 1.05,
      fill: { color: C.dark },
      line: { color: C.accent, width: 1.5 },
      shadow: makeCardShadow()
    });
    s.addShape(pres.shapes.RECTANGLE, {
      x, y: 1.08, w: 2.2, h: 0.07,
      fill: { color: C.accent },
      line: { color: C.accent }
    });
    s.addText(st.v, {
      x: x + 0.05, y: 1.15, w: 2.1, h: 0.5,
      fontSize: 28, color: C.accent, bold: true, align: "center", valign: "middle", margin: 0
    });
    s.addText(st.l, {
      x: x + 0.05, y: 1.66, w: 2.1, h: 0.4,
      fontSize: 8, color: C.lightGray, align: "center", valign: "top", margin: 0
    });
  });

  // Three pillars of 5.0 experience
  s.addText("Os 3 Pilares da Experiência 5.0", {
    x: 0.4, y: 2.32, w: 9.2, h: 0.3,
    fontSize: 13, fontFace: "Georgia", color: C.primary, bold: true, margin: 0
  });

  const pillars = [
    {
      color: C.primary,
      icon: "T",
      title: "Transparente",
      bullets: ["Paciente sabe cada etapa da jornada", "Tempo de espera visível em tempo real", "Comunicação clara e sem ruído", "Histórico completo acessível"]
    },
    {
      color: C.secondary,
      icon: "E",
      title: "Eficiente",
      bullets: ["IA otimiza alocação de recursos", "Redução de filas desnecessárias", "Predição antecipa gargalos", "Gestores tomam decisões com dados"]
    },
    {
      color: C.accent,
      icon: "C",
      title: "Centrado no Paciente",
      bullets: ["Experiência personalizada por perfil", "Notificações no momento certo", "Autonomia e controle para o usuário", "Saúde acessível e humana"]
    },
  ];

  pillars.forEach((p, i) => {
    const x = 0.38 + i * 3.22;
    const y = 2.75;
    const w = 3.0;
    const h = 2.25;

    s.addShape(pres.shapes.RECTANGLE, {
      x, y, w, h,
      fill: { color: C.white },
      line: { color: p.color, width: 1 },
      shadow: makeCardShadow()
    });
    s.addShape(pres.shapes.RECTANGLE, {
      x, y, w, h: 0.07,
      fill: { color: p.color },
      line: { color: p.color }
    });
    addCircleIcon(s, p.icon, x + 0.38, y + 0.42, 0.28, p.color, C.white);
    s.addText(p.title, {
      x: x + 0.75, y: y + 0.18, w: w - 0.85, h: 0.42,
      fontSize: 14, fontFace: "Georgia", color: C.textDark, bold: true, valign: "middle", margin: 0
    });
    s.addText(p.bullets.map((b, j) => ({
      text: b,
      options: { bullet: true, breakLine: j < p.bullets.length - 1, fontSize: 9, color: C.textMid }
    })), {
      x: x + 0.14, y: y + 0.82, w: w - 0.25, h: 1.32,
      fontSize: 9, color: C.textMid, valign: "top", margin: 0
    });
  });

  addFooter(s, "08 / 09");
})();

// ══════════════════════════════════════════════════════════════
// SLIDE 9 – Conclusion / CTA
// ══════════════════════════════════════════════════════════════
(function slide9() {
  const s = pres.addSlide();
  s.background = { color: C.dark };

  // Left accent
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.45, h: 5.625,
    fill: { color: C.primary },
    line: { color: C.primary }
  });

  // Top bar
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.45, y: 0, w: 9.55, h: 0.06,
    fill: { color: C.accent },
    line: { color: C.accent }
  });

  // "Conclusão" tag
  s.addText("CONCLUSÃO", {
    x: 0.65, y: 0.22, w: 2.5, h: 0.28,
    fontSize: 9, color: C.accent, bold: true, charSpacing: 4, margin: 0
  });

  s.addText("SmartCare 5.0:", {
    x: 0.65, y: 0.55, w: 9, h: 0.5,
    fontSize: 26, fontFace: "Georgia", color: C.accent, bold: true, margin: 0
  });
  s.addText("O Futuro da Saúde é Inteligente, Proativo e Humano", {
    x: 0.65, y: 1.03, w: 9, h: 0.52,
    fontSize: 18, fontFace: "Georgia", color: C.white, bold: false, italic: true, margin: 0
  });

  // Separator
  s.addShape(pres.shapes.LINE, {
    x: 0.65, y: 1.63, w: 8.8, h: 0,
    line: { color: C.darkMid, width: 1 }
  });

  // Summary bullets
  const summaryItems = [
    "SmartCare 5.0 resolve um problema real: baixa adesão ao autocuidado e falta de visibilidade na jornada de saúde",
    "A extensão de Logística com IA adiciona predição de tempo de atendimento, tracking do paciente e notificações proativas",
    "Tecnologia Kotlin + ML + cloud entrega uma experiência 5.0: transparente, eficiente e centrada no paciente",
    "Alinhado à missão da Leroy Merlin de levar inovação e experiência de serviço de excelência ao cliente",
  ];

  s.addText(summaryItems.map((item, i) => ({
    text: item,
    options: { bullet: true, breakLine: i < summaryItems.length - 1, fontSize: 10.5, color: C.lightGray }
  })), {
    x: 0.65, y: 1.75, w: 8.8, h: 2.0,
    fontSize: 10.5, color: C.lightGray, valign: "top", margin: 0
  });

  // CTA box
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.65, y: 3.9, w: 8.8, h: 0.9,
    fill: { color: C.primary },
    line: { color: C.accent, width: 1.5 },
    shadow: makeCardShadow()
  });
  s.addText("Prontos para transformar a experiência de saúde com dados e inteligência artificial.", {
    x: 0.85, y: 3.98, w: 8.4, h: 0.38,
    fontSize: 13, fontFace: "Georgia", color: C.white, bold: true, align: "center", valign: "middle", margin: 0
  });
  s.addText("Felipe  ·  Flávio  ·  Guilherme  ·  Gustavo  —  Smart HAS Team", {
    x: 0.85, y: 4.36, w: 8.4, h: 0.34,
    fontSize: 10, color: C.lightGray, align: "center", valign: "middle", italic: true, margin: 0
  });

  addDarkFooter(s);
  s.addText("09 / 09", {
    x: 8.5, y: 5.355, w: 1.3, h: 0.25,
    fontSize: 7, color: C.white, bold: false, align: "right", valign: "middle", margin: 0
  });
})();

// ── Write file ────────────────────────────────────────────────
pres.writeFile({ fileName: "C:\\Projetos\\SmartCare5\\SmartCare_AI_Logistics_Pitch.pptx" })
  .then(() => console.log("DONE: SmartCare_AI_Logistics_Pitch.pptx created"))
  .catch(err => { console.error("ERROR:", err); process.exit(1); });

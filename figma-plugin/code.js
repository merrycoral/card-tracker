// Card Tracker UI Generator - Figma Plugin
// Run this plugin inside Figma to generate all screens automatically

const COLORS = {
  primary: { r: 0.102, g: 0.451, b: 0.910 },    // #1A73E8
  primaryLight: { r: 0.878, g: 0.922, b: 0.988 }, // #E0EBFC
  green: { r: 0.204, g: 0.659, b: 0.325 },        // #34A853
  orange: { r: 0.984, g: 0.737, b: 0.016 },       // #FBBC04
  red: { r: 0.918, g: 0.263, b: 0.208 },          // #EA4335
  purple: { r: 0.612, g: 0.153, b: 0.690 },       // #9C27B0
  white: { r: 1, g: 1, b: 1 },
  bg: { r: 0.965, g: 0.969, b: 0.976 },           // #F6F7F9
  card: { r: 1, g: 1, b: 1 },
  text: { r: 0.133, g: 0.133, b: 0.133 },         // #222222
  textSub: { r: 0.420, g: 0.420, b: 0.420 },      // #6B6B6B
  textLight: { r: 0.702, g: 0.702, b: 0.702 },    // #B3B3B3
  border: { r: 0.898, g: 0.898, b: 0.898 },       // #E5E5E5
  progressBg: { r: 0.929, g: 0.929, b: 0.929 },   // #EDEDED
};

const FONT = { family: "Inter", style: "Regular" };
const FONT_BOLD = { family: "Inter", style: "Bold" };
const FONT_MEDIUM = { family: "Inter", style: "Medium" };
const FONT_SEMI = { family: "Inter", style: "SemiBold" };

// ── Helpers ──────────────────────────────────────────────────────────────────

function hex2rgb(hex) {
  const n = parseInt(hex.replace('#', ''), 16);
  return { r: ((n >> 16) & 255) / 255, g: ((n >> 8) & 255) / 255, b: (n & 255) / 255 };
}

async function loadFonts() {
  await Promise.all([
    figma.loadFontAsync(FONT),
    figma.loadFontAsync(FONT_BOLD),
    figma.loadFontAsync(FONT_MEDIUM),
    figma.loadFontAsync(FONT_SEMI),
  ]);
}

function rect(parent, x, y, w, h, fill, cornerRadius = 0, name = 'rect') {
  const r = figma.createRectangle();
  r.name = name;
  r.x = x; r.y = y; r.resize(w, h);
  r.fills = [{ type: 'SOLID', color: fill }];
  if (cornerRadius) r.cornerRadius = cornerRadius;
  parent.appendChild(r);
  return r;
}

function text(parent, x, y, content, size, color, fontName = FONT, maxWidth = 0) {
  const t = figma.createText();
  t.fontName = fontName;
  t.fontSize = size;
  t.characters = content;
  t.fills = [{ type: 'SOLID', color }];
  t.x = x; t.y = y;
  if (maxWidth) { t.textAutoResize = 'HEIGHT'; t.resize(maxWidth, t.height); }
  parent.appendChild(t);
  return t;
}

function frame(parent, x, y, w, h, fill = COLORS.white, name = 'Frame', cornerRadius = 0) {
  const f = figma.createFrame();
  f.name = name;
  f.x = x; f.y = y;
  f.resize(w, h);
  f.fills = fill ? [{ type: 'SOLID', color: fill }] : [];
  if (cornerRadius) f.cornerRadius = cornerRadius;
  if (parent) parent.appendChild(f);
  return f;
}

function progressBar(parent, x, y, w, h, value, fillColor, bgColor = COLORS.progressBg) {
  const bg = rect(parent, x, y, w, h, bgColor, h / 2, 'ProgressBg');
  const filled = rect(parent, x, y, Math.max(h, w * value), h, fillColor, h / 2, 'ProgressFill');
  return { bg, filled };
}

function shadow(node) {
  node.effects = [{
    type: 'DROP_SHADOW',
    color: { r: 0, g: 0, b: 0, a: 0.08 },
    offset: { x: 0, y: 2 },
    radius: 8,
    spread: 0,
    visible: true,
    blendMode: 'NORMAL',
  }];
}

function icon(parent, x, y, type, color = COLORS.textSub) {
  // Simple icon approximations using shapes
  const g = figma.createFrame();
  g.name = `Icon_${type}`;
  g.resize(24, 24);
  g.fills = [];
  g.x = x; g.y = y;
  parent.appendChild(g);

  if (type === 'credit_card') {
    rect(g, 2, 5, 20, 14, color, 2);
    rect(g, 2, 9, 20, 3, { r: 1, g: 1, b: 1 });
    rect(g, 4, 14, 6, 2, { r: 1, g: 1, b: 1 }, 1);
  } else if (type === 'add') {
    rect(g, 11, 4, 2, 16, color, 1);
    rect(g, 4, 11, 16, 2, color, 1);
  } else if (type === 'chevron_right') {
    rect(g, 8, 6, 2, 8, color, 1);
    rect(g, 8, 13, 8, 2, color, 1);
  } else if (type === 'chevron_left') {
    rect(g, 14, 6, 2, 8, color, 1);
    rect(g, 8, 13, 8, 2, color, 1);
  } else if (type === 'check_circle') {
    rect(g, 2, 2, 20, 20, color, 10);
    rect(g, 6, 11, 4, 2, COLORS.white, 1);
    rect(g, 9, 9, 2, 6, COLORS.white, 1);
  } else if (type === 'warning') {
    rect(g, 10, 3, 4, 12, color, 1);
    rect(g, 10, 18, 4, 3, color, 1);
  } else if (type === 'more_vert') {
    rect(g, 10, 4, 4, 4, color, 2);
    rect(g, 10, 10, 4, 4, color, 2);
    rect(g, 10, 16, 4, 4, color, 2);
  } else if (type === 'edit') {
    rect(g, 3, 16, 14, 2, color, 1);
    rect(g, 14, 4, 6, 6, color, 1);
    rect(g, 6, 10, 8, 10, color, 1);
  } else if (type === 'bell') {
    rect(g, 8, 2, 8, 14, color, 4);
    rect(g, 6, 14, 12, 4, color, 2);
    rect(g, 9, 18, 6, 3, color, 2);
  }
  return g;
}

// ── Status Bar ────────────────────────────────────────────────────────────────

function statusBar(parent, y = 0) {
  const bar = frame(parent, 0, y, 390, 44, COLORS.white, 'StatusBar');
  text(bar, 20, 14, '9:41', 15, COLORS.text, FONT_SEMI);
  // battery / signal icons (simplified)
  rect(bar, 340, 18, 25, 12, COLORS.text, 2, 'Battery');
  rect(bar, 342, 20, 18, 8, COLORS.white, 1, 'BatteryFill');
  rect(bar, 355, 22, 4, 4, COLORS.text, 1, 'BatteryTip');
  rect(bar, 320, 20, 4, 8, COLORS.text, 1, 'Signal3');
  rect(bar, 314, 22, 4, 6, COLORS.text, 1, 'Signal2');
  rect(bar, 308, 24, 4, 4, COLORS.text, 1, 'Signal1');
  return bar;
}

// ── AppBar ────────────────────────────────────────────────────────────────────

function appBar(parent, y, title, showBack = false, actions = []) {
  const bar = frame(parent, 0, y, 390, 56, COLORS.white, 'AppBar');
  // bottom border
  rect(bar, 0, 55, 390, 1, COLORS.border, 0, 'Divider');

  if (showBack) {
    rect(bar, 16, 16, 24, 24, COLORS.primary, 12, 'BackBtn');
  }
  text(bar, showBack ? 52 : 0, 17, title, 18, COLORS.text, FONT_SEMI, showBack ? 280 : 390);
  if (!showBack) {
    const t = bar.children[bar.children.length - 1];
    t.textAlignHorizontal = 'CENTER';
  }

  actions.forEach((a, i) => {
    const btn = frame(bar, 390 - 44 - i * 44, 8, 40, 40, null, `Action_${i}`);
    text(btn, 0, 8, a, 13, COLORS.primary, FONT_MEDIUM, 40);
    const t = btn.children[0];
    t.textAlignHorizontal = 'CENTER';
  });

  return bar;
}

// ── Month Selector ────────────────────────────────────────────────────────────

function monthSelector(parent, y, label) {
  const row = frame(parent, 0, y, 390, 44, COLORS.white, 'MonthSelector');
  rect(row, 0, 43, 390, 1, COLORS.border, 0, 'Divider');
  // chevrons
  rect(row, 16, 12, 20, 20, COLORS.primaryLight, 10, 'ChevLeft');
  text(row, 22, 14, '<', 12, COLORS.primary, FONT_BOLD);
  text(row, 0, 12, label, 15, COLORS.text, FONT_SEMI, 390);
  const t = row.children[row.children.length - 1];
  t.textAlignHorizontal = 'CENTER';
  rect(row, 354, 12, 20, 20, COLORS.primaryLight, 10, 'ChevRight');
  text(row, 359, 14, '>', 12, COLORS.primary, FONT_BOLD);
  return row;
}

// ── Card Item ─────────────────────────────────────────────────────────────────

function cardItem(parent, x, y, data) {
  const { name, company, used, target, rate, color, benefit, threshold } = data;
  const h = benefit ? 140 : 124;
  const card = frame(parent, x, y, 358, h, COLORS.card, 'CardItem', 16);
  shadow(card);

  // color swatch
  rect(card, 16, 16, 44, 28, color, 6, 'CardSwatch');

  // title block
  text(card, 72, 16, name, 16, COLORS.text, FONT_BOLD, 220);
  text(card, 72, 36, company, 12, COLORS.textSub, FONT, 220);

  // status icon
  if (rate >= 100) {
    rect(card, 318, 16, 20, 20, COLORS.green, 10, 'CheckIcon');
  } else if (rate >= threshold) {
    rect(card, 318, 16, 20, 20, COLORS.orange, 10, 'WarnIcon');
  }
  // more menu
  text(card, 336, 14, '⋮', 20, COLORS.textLight);

  // amounts
  const usedFmt = used >= 10000 ? `${(used / 10000).toFixed(0)}만원` : `${used.toLocaleString()}원`;
  const targetFmt = target >= 10000 ? `${(target / 10000).toFixed(0)}만원` : `${target.toLocaleString()}원`;
  text(card, 16, 60, `${usedFmt} / ${targetFmt}`, 13, COLORS.textSub);
  const rateColor = rate >= 100 ? COLORS.green : rate >= threshold ? COLORS.orange : COLORS.primary;
  text(card, 298, 58, `${rate}%`, 14, rateColor, FONT_BOLD);

  // progress bar
  rect(card, 16, 82, 326, 8, COLORS.progressBg, 4, 'ProgressBg');
  rect(card, 16, 82, Math.max(8, 326 * Math.min(rate / 100, 1)), 8, rateColor, 4, 'ProgressFill');

  // benefit
  if (benefit) {
    text(card, 16, 100, benefit, 12, COLORS.textLight, FONT, 326);
  }

  return card;
}

// ── FAB ───────────────────────────────────────────────────────────────────────

function fab(parent, label) {
  const btn = frame(parent, 270, 720, 104, 48, COLORS.primary, 'FAB', 24);
  shadow(btn);
  rect(btn, 14, 15, 18, 18, { r: 1, g: 1, b: 1 }, 9, 'AddIcon');
  text(btn, 12, 15, '+', 18, COLORS.white, FONT_BOLD);
  text(btn, 34, 15, label, 14, COLORS.white, FONT_MEDIUM);
  return btn;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCREEN 1 — Home
// ═══════════════════════════════════════════════════════════════════════════════

async function buildHomeScreen(page) {
  const phone = frame(null, 0, 0, 390, 844, COLORS.bg, '📱 Home — 카드 목록');

  statusBar(phone);
  appBar(phone, 44, '카드 실적 관리');
  monthSelector(phone, 100, '2026년 3월');

  const CARDS = [
    { name: '신한 Deep Dream', company: '신한카드', used: 280000, target: 300000, rate: 93, color: COLORS.primary, benefit: '전월 30만원 이상 사용 시 최대 5% 할인', threshold: 80 },
    { name: '현대 Z:클럽', company: '현대카드', used: 150000, target: 500000, rate: 30, color: hex2rgb('#EA4335'), benefit: '월 50만원 이상 실적 시 포인트 2배 적립', threshold: 80 },
    { name: 'KB 탄탄대로', company: 'KB국민카드', used: 420000, target: 400000, rate: 105, color: COLORS.green, benefit: '', threshold: 80 },
  ];

  CARDS.forEach((c, i) => cardItem(phone, 16, 156 + i * 156, c));
  fab(phone, '카드 추가');

  page.appendChild(phone);
  return phone;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCREEN 2 — Card Detail
// ═══════════════════════════════════════════════════════════════════════════════

async function buildDetailScreen(page) {
  const phone = frame(null, 430, 0, 390, 844, COLORS.bg, '📱 Card Detail — 카드 상세');

  statusBar(phone);
  appBar(phone, 44, '신한 Deep Dream', true, ['수정']);

  // Card info header
  const header = frame(phone, 16, 116, 358, 136, COLORS.primaryLight, 'CardHeader', 16);
  rect(header, 16, 20, 60, 38, COLORS.primary, 8, 'CardSwatch');
  text(header, 90, 20, '신한 Deep Dream', 18, COLORS.text, FONT_BOLD);
  text(header, 90, 44, '신한카드', 13, COLORS.textSub);
  // Info chips
  const chipFrame1 = frame(header, 16, 76, 150, 44, COLORS.white, 'Chip_Target', 8);
  text(chipFrame1, 10, 6, '월 목표', 11, COLORS.textSub);
  text(chipFrame1, 10, 22, '30만원', 15, COLORS.text, FONT_BOLD);
  const chipFrame2 = frame(header, 180, 76, 162, 44, COLORS.white, 'Chip_Threshold', 8);
  text(chipFrame2, 10, 6, '알림 임계값', 11, COLORS.textSub);
  text(chipFrame2, 10, 22, '80%', 15, COLORS.text, FONT_BOLD);

  // Month selector
  monthSelector(phone, 268, '2026년 3월');

  // Performance input
  const inputArea = frame(phone, 16, 328, 358, 120, COLORS.card, 'PerformanceInput', 16);
  shadow(inputArea);
  text(inputArea, 16, 16, '실적 입력', 16, COLORS.text, FONT_BOLD);
  // Input field
  const inputField = frame(inputArea, 16, 48, 234, 44, COLORS.bg, 'InputField', 10);
  rect(inputField, 0, 0, 234, 44, COLORS.border, 10, 'InputBorder');
  inputField.strokes = [{ type: 'SOLID', color: COLORS.border }];
  inputField.strokeWeight = 1;
  inputField.fills = [{ type: 'SOLID', color: COLORS.bg }];
  text(inputField, 14, 13, '280,000', 15, COLORS.text, FONT, 180);
  text(inputField, 188, 13, '원', 13, COLORS.textSub);

  // Save button
  const saveBtn = frame(inputArea, 262, 48, 80, 44, COLORS.primary, 'SaveBtn', 10);
  text(saveBtn, 0, 14, '저장', 14, COLORS.white, FONT_SEMI, 80);
  const st = saveBtn.children[0];
  st.textAlignHorizontal = 'CENTER';

  // Achievement rate
  text(phone, 16, 462, '달성률', 14, COLORS.textSub, FONT, 200);
  text(phone, 280, 458, '93.3%', 22, COLORS.primary, FONT_BOLD);
  rect(phone, 16, 490, 358, 14, COLORS.progressBg, 7, 'ProgressBg');
  rect(phone, 16, 490, 333, 14, COLORS.primary, 7, 'ProgressFill');

  // Chart section
  text(phone, 16, 524, '월별 달성률 추이', 16, COLORS.text, FONT_BOLD);

  const chartBg = frame(phone, 16, 552, 358, 200, COLORS.card, 'Chart', 16);
  shadow(chartBg);

  // Chart grid lines & labels
  const months = ['10월', '11월', '12월', '1월', '2월', '3월'];
  const rates = [45, 72, 88, 60, 95, 93];
  const chartH = 160;
  const chartW = 310;
  const padL = 36;
  const padT = 12;

  [0, 25, 50, 75, 100].forEach(v => {
    const gy = padT + chartH - (v / 100) * chartH;
    rect(chartBg, padL, gy, chartW, 1, COLORS.border, 0, `Grid_${v}`);
    text(chartBg, 0, gy - 8, `${v}%`, 9, COLORS.textLight);
  });

  // Goal dashed line at 100%
  rect(chartBg, padL, padT, chartW, 1, COLORS.green, 0, 'GoalLine');
  text(chartBg, padL + chartW - 24, padT - 10, '목표', 9, COLORS.green);

  // Plot line segments and dots
  const pts = months.map((m, i) => ({
    x: padL + (i / (months.length - 1)) * chartW,
    y: padT + chartH - (rates[i] / 100) * chartH,
    label: m,
    rate: rates[i],
  }));

  for (let i = 0; i < pts.length - 1; i++) {
    const a = pts[i], b = pts[i + 1];
    const dx = b.x - a.x, dy = b.y - a.y;
    const len = Math.sqrt(dx * dx + dy * dy);
    const seg = figma.createRectangle();
    seg.name = `Line_${i}`;
    seg.resize(len, 2.5);
    seg.x = a.x; seg.y = a.y - 1;
    seg.fills = [{ type: 'SOLID', color: COLORS.primary }];
    seg.rotation = -(Math.atan2(dy, dx) * 180) / Math.PI;
    chartBg.appendChild(seg);
  }

  pts.forEach((p, i) => {
    const dot = figma.createEllipse();
    dot.name = `Dot_${i}`;
    dot.resize(10, 10);
    dot.x = p.x - 5; dot.y = p.y - 5;
    dot.fills = [{ type: 'SOLID', color: p.rate >= 100 ? COLORS.green : COLORS.primary }];
    dot.strokes = [{ type: 'SOLID', color: COLORS.white }];
    dot.strokeWeight = 2;
    chartBg.appendChild(dot);
    text(chartBg, p.x - 10, chartH + padT + 6, p.label, 9, COLORS.textLight, FONT, 20);
  });

  page.appendChild(phone);
  return phone;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCREEN 3 — Add Card
// ═══════════════════════════════════════════════════════════════════════════════

async function buildAddCardScreen(page) {
  const phone = frame(null, 860, 0, 390, 844, COLORS.bg, '📱 Add Card — 카드 추가');

  statusBar(phone);
  appBar(phone, 44, '카드 추가', true, ['저장']);

  let currentY = 116;

  function fieldBlock(label, placeholder, hint = '') {
    const block = frame(phone, 16, currentY, 358, hint ? 96 : 80, COLORS.card, `Field_${label}`, 12);
    shadow(block);
    text(block, 16, 14, label, 13, COLORS.text, FONT_SEMI);
    const inputF = frame(block, 16, 36, 326, 40, COLORS.bg, 'Input', 10);
    inputF.strokes = [{ type: 'SOLID', color: COLORS.border }];
    inputF.strokeWeight = 1;
    text(inputF, 14, 11, placeholder, 14, COLORS.textLight);
    if (hint) text(block, 16, 80, hint, 11, COLORS.textLight, FONT, 326);
    currentY += (hint ? 96 : 80) + 12;
    return block;
  }

  fieldBlock('카드 이름', '예) 신한 Deep Dream');
  fieldBlock('카드사', '예) 신한카드');
  fieldBlock('월 목표 실적 (원)', '예) 300000', '숫자만 입력하세요');
  fieldBlock('혜택 설명', '예) 전월 30만원 이상 시 5% 할인');

  // Color picker
  const colorBlock = frame(phone, 16, currentY, 358, 80, COLORS.card, 'ColorPicker', 12);
  shadow(colorBlock);
  text(colorBlock, 16, 14, '카드 색상', 13, COLORS.text, FONT_SEMI);
  const swatchColors = [COLORS.primary, hex2rgb('#34A853'), hex2rgb('#EA4335'), hex2rgb('#FBBC04'), COLORS.purple, hex2rgb('#FF5722'), hex2rgb('#00BCD4'), hex2rgb('#607D8B')];
  swatchColors.forEach((c, i) => {
    const swatch = figma.createEllipse();
    swatch.name = `Swatch_${i}`;
    swatch.resize(32, 32);
    swatch.x = 16 + i * 42;
    swatch.y = 38;
    swatch.fills = [{ type: 'SOLID', color: c }];
    if (i === 0) {
      swatch.strokes = [{ type: 'SOLID', color: COLORS.text }];
      swatch.strokeWeight = 2.5;
    }
    colorBlock.appendChild(swatch);
  });
  currentY += 80 + 12;

  // Alert threshold slider
  const sliderBlock = frame(phone, 16, currentY, 358, 88, COLORS.card, 'ThresholdSlider', 12);
  shadow(sliderBlock);
  text(sliderBlock, 16, 14, '알림 임계값', 13, COLORS.text, FONT_SEMI);
  text(sliderBlock, 298, 14, '80%', 13, COLORS.primary, FONT_BOLD);
  text(sliderBlock, 16, 34, '이 비율 달성 시 즉시 알림을 받습니다', 11, COLORS.textLight, FONT, 326);
  // Slider track
  rect(sliderBlock, 16, 58, 326, 6, COLORS.progressBg, 3, 'SliderTrack');
  rect(sliderBlock, 16, 58, 238, 6, COLORS.primary, 3, 'SliderFill');
  const thumb = figma.createEllipse();
  thumb.name = 'SliderThumb';
  thumb.resize(20, 20);
  thumb.x = 244; thumb.y = 51;
  thumb.fills = [{ type: 'SOLID', color: COLORS.white }];
  thumb.strokes = [{ type: 'SOLID', color: COLORS.primary }];
  thumb.strokeWeight = 2;
  sliderBlock.appendChild(thumb);

  page.appendChild(phone);
  return phone;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCREEN 4 — Notification Toast + Empty State
// ═══════════════════════════════════════════════════════════════════════════════

async function buildExtraScreens(page) {
  // Empty State
  const empty = frame(null, 1290, 0, 390, 844, COLORS.bg, '📱 Empty State');
  statusBar(empty);
  appBar(empty, 44, '카드 실적 관리');
  monthSelector(empty, 100, '2026년 3월');

  const emptyIcon = frame(empty, 155, 320, 80, 80, COLORS.progressBg, 'EmptyIcon', 40);
  rect(emptyIcon, 14, 24, 52, 32, COLORS.textLight, 4, 'Card');
  text(empty, 0, 416, '등록된 카드가 없습니다', 17, COLORS.textSub, FONT_MEDIUM, 390);
  const et = empty.children[empty.children.length - 1];
  et.textAlignHorizontal = 'CENTER';
  text(empty, 0, 442, '카드 추가 버튼을 눌러 시작하세요', 13, COLORS.textLight, FONT, 390);
  const et2 = empty.children[empty.children.length - 1];
  et2.textAlignHorizontal = 'CENTER';
  fab(empty, '카드 추가');

  // Achievement notification toast
  const toast = frame(empty, 16, 760, 358, 64, hex2rgb('#1E1E1E'), 'ToastNotification', 12);
  rect(toast, 14, 14, 36, 36, COLORS.green, 18, 'ToastIcon');
  text(toast, 62, 12, '신한 Deep Dream 실적 달성!', 14, COLORS.white, FONT_SEMI);
  text(toast, 62, 34, '이번 달 실적이 93% 달성되었습니다.', 12, hex2rgb('#AAAAAA'), FONT, 280);

  page.appendChild(empty);
  return empty;
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPONENT SHEET
// ═══════════════════════════════════════════════════════════════════════════════

async function buildComponentSheet(page) {
  const sheet = frame(null, 0, 900, 1680, 600, COLORS.bg, '🧩 Component Sheet');

  // Title
  text(sheet, 40, 24, 'Card Tracker — Component Sheet', 24, COLORS.text, FONT_BOLD);

  // Color palette
  text(sheet, 40, 72, 'Color Palette', 16, COLORS.text, FONT_SEMI);
  const palette = [
    { label: 'Primary', color: COLORS.primary },
    { label: 'Green', color: COLORS.green },
    { label: 'Orange', color: COLORS.orange },
    { label: 'Red', color: COLORS.red },
    { label: 'Purple', color: COLORS.purple },
    { label: 'BG', color: COLORS.bg },
    { label: 'Text', color: COLORS.text },
    { label: 'TextSub', color: COLORS.textSub },
  ];
  palette.forEach((p, i) => {
    rect(sheet, 40 + i * 96, 100, 80, 80, p.color, 12, `Color_${p.label}`);
    text(sheet, 40 + i * 96, 188, p.label, 11, COLORS.textSub);
  });

  // Progress bar variants
  text(sheet, 40, 224, 'Progress Bars', 16, COLORS.text, FONT_SEMI);
  const progressVariants = [
    { label: '30% — 미달', val: 0.3, color: COLORS.primary },
    { label: '80% — 임계값', val: 0.8, color: COLORS.orange },
    { label: '100% — 달성', val: 1.0, color: COLORS.green },
  ];
  progressVariants.forEach((v, i) => {
    text(sheet, 40, 252 + i * 44, v.label, 12, COLORS.textSub);
    rect(sheet, 140, 254 + i * 44, 300, 10, COLORS.progressBg, 5, 'Bg');
    rect(sheet, 140, 254 + i * 44, 300 * v.val, 10, v.color, 5, 'Fill');
    text(sheet, 448, 250 + i * 44, `${(v.val * 100).toFixed(0)}%`, 12, v.color, FONT_BOLD);
  });

  // Typography scale
  text(sheet, 560, 72, 'Typography', 16, COLORS.text, FONT_SEMI);
  const typo = [
    { label: 'H1 — Bold 24', size: 24, font: FONT_BOLD },
    { label: 'H2 — SemiBold 18', size: 18, font: FONT_SEMI },
    { label: 'Body — Regular 14', size: 14, font: FONT },
    { label: 'Caption — Regular 12', size: 12, font: FONT },
    { label: 'Micro — Regular 11', size: 11, font: FONT },
  ];
  typo.forEach((t, i) => {
    text(sheet, 560, 96 + i * 40, t.label, t.size, COLORS.text, t.font);
  });

  // Button variants
  text(sheet, 1040, 72, 'Buttons', 16, COLORS.text, FONT_SEMI);
  const primaryBtn = frame(sheet, 1040, 100, 120, 44, COLORS.primary, 'PrimaryBtn', 10);
  text(primaryBtn, 0, 14, '저장', 14, COLORS.white, FONT_SEMI, 120);
  primaryBtn.children[0].textAlignHorizontal = 'CENTER';

  const outlineBtn = frame(sheet, 1180, 100, 120, 44, COLORS.white, 'OutlineBtn', 10);
  outlineBtn.strokes = [{ type: 'SOLID', color: COLORS.primary }];
  outlineBtn.strokeWeight = 1.5;
  text(outlineBtn, 0, 14, '취소', 14, COLORS.primary, FONT_SEMI, 120);
  outlineBtn.children[0].textAlignHorizontal = 'CENTER';

  const dangerBtn = frame(sheet, 1320, 100, 120, 44, hex2rgb('#FDECEA'), 'DangerBtn', 10);
  text(dangerBtn, 0, 14, '삭제', 14, COLORS.red, FONT_SEMI, 120);
  dangerBtn.children[0].textAlignHorizontal = 'CENTER';

  // FAB component
  const fabComp = frame(sheet, 1040, 164, 120, 48, COLORS.primary, 'FAB', 24);
  shadow(fabComp);
  text(fabComp, 0, 15, '+ 카드 추가', 14, COLORS.white, FONT_MEDIUM, 120);
  fabComp.children[0].textAlignHorizontal = 'CENTER';

  page.appendChild(sheet);
  return sheet;
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════════

async function main() {
  await loadFonts();

  // Use current page or create new
  const page = figma.currentPage;
  page.name = 'Card Tracker UI';

  figma.showUI(__html__, { visible: false });
  figma.ui.postMessage({ type: 'start' });

  try {
    const [home, detail, addCard, extra, components] = await Promise.all([
      buildHomeScreen(page),
      buildDetailScreen(page),
      buildAddCardScreen(page),
      buildExtraScreens(page),
      buildComponentSheet(page),
    ]);

    // Center viewport on all screens
    figma.viewport.scrollAndZoomIntoView([home, detail, addCard, extra, components]);

    figma.notify('✅ Card Tracker UI 생성 완료! (4개 화면 + 컴포넌트 시트)', { timeout: 5000 });
  } catch (e) {
    figma.notify(`❌ 오류: ${e.message}`, { error: true });
    console.error(e);
  }

  figma.closePlugin();
}

main();

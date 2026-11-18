import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const OUT = path.dirname(fileURLToPath(import.meta.url));

const C = {
  ink: '#0F172A',
  muted: '#475569',
  green: '#0F766E',
  dark: '#0B5D4E',
  mint: '#D1FAE5',
  mintBg: '#ECFDF5',
  blue: '#1D4ED8',
  blueBg: '#DBEAFE',
  amber: '#B45309',
  amberBg: '#FEF3C7',
  red: '#B91C1C',
  redBg: '#FEE2E2',
  border: '#CBD5E1',
  paper: '#FFFFFF',
  soft: '#F8FAFC',
};

const esc = (value) =>
  String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

function svgDoc(width, height, body) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="${C.green}"/>
    </marker>
    <marker id="arrowBlue" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="${C.blue}"/>
    </marker>
    <marker id="arrowAmber" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="${C.amber}"/>
    </marker>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="130%">
      <feDropShadow dx="0" dy="2" stdDeviation="4" flood-color="#0F172A" flood-opacity="0.08"/>
    </filter>
  </defs>
  <rect width="100%" height="100%" fill="${C.paper}"/>
  ${body}
</svg>`;
}

function rect(x, y, w, h, { fill = C.paper, stroke = C.green, rx = 12, sw = 2, dash = '' } = {}) {
  const dashAttr = dash ? ` stroke-dasharray="${dash}"` : '';
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${rx}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"${dashAttr}/>`;
}

function txt(x, y, value, { size = 16, weight = 400, anchor = 'start', fill = C.ink, italic = false } = {}) {
  return `<text x="${x}" y="${y}" font-family="Segoe UI, Arial, sans-serif" font-size="${size}" font-weight="${weight}" text-anchor="${anchor}" fill="${fill}" dominant-baseline="middle"${italic ? ' font-style="italic"' : ''}>${esc(value)}</text>`;
}

function mtext(x, y, lines, { size = 16, weight = 400, anchor = 'middle', fill = C.ink, lineHeight = 21 } = {}) {
  const start = y - ((lines.length - 1) * lineHeight) / 2;
  return `<text x="${x}" y="${start}" font-family="Segoe UI, Arial, sans-serif" font-size="${size}" font-weight="${weight}" text-anchor="${anchor}" fill="${fill}" dominant-baseline="middle">${lines
    .map((line, index) => `<tspan x="${x}" dy="${index === 0 ? 0 : lineHeight}">${esc(line)}</tspan>`)
    .join('')}</text>`;
}

function line(x1, y1, x2, y2, { color = C.green, sw = 2, dash = '', marker = true, markerId = 'arrow' } = {}) {
  const dashAttr = dash ? ` stroke-dasharray="${dash}"` : '';
  const markerAttr = marker ? ` marker-end="url(#${markerId})"` : '';
  return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${color}" stroke-width="${sw}"${dashAttr}${markerAttr}/>`;
}

function pathEl(d, { color = C.green, sw = 2, dash = '', marker = true, markerId = 'arrow', fill = 'none' } = {}) {
  const dashAttr = dash ? ` stroke-dasharray="${dash}"` : '';
  const markerAttr = marker ? ` marker-end="url(#${markerId})"` : '';
  return `<path d="${d}" fill="${fill}" stroke="${color}" stroke-width="${sw}"${dashAttr}${markerAttr}/>`;
}

function ellipse(cx, cy, rx, ry, label, { fill = C.blueBg, stroke = C.blue, size = 16, weight = 600 } = {}) {
  const lines = Array.isArray(label) ? label : [label];
  return `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${fill}" stroke="${stroke}" stroke-width="2"/>${mtext(cx, cy, lines, { size, weight, lineHeight: 20 })}`;
}

function actor(x, y, label, color = C.green) {
  const head = `<circle cx="${x}" cy="${y - 48}" r="15" fill="${C.paper}" stroke="${color}" stroke-width="2.5"/>`;
  const body = `<line x1="${x}" y1="${y - 33}" x2="${x}" y2="${y + 15}" stroke="${color}" stroke-width="2.5"/>`;
  const arms = `<line x1="${x - 30}" y1="${y - 12}" x2="${x + 30}" y2="${y - 12}" stroke="${color}" stroke-width="2.5"/>`;
  const legs = `<path d="M ${x} ${y + 15} L ${x - 24} ${y + 48} M ${x} ${y + 15} L ${x + 24} ${y + 48}" fill="none" stroke="${color}" stroke-width="2.5"/>`;
  return `<g>${head}${body}${arms}${legs}${txt(x, y + 74, label, { size: 19, weight: 700, anchor: 'middle', fill: color })}</g>`;
}

function diamond(cx, cy, w, h, label, { fill = C.amberBg, stroke = C.amber, size = 15 } = {}) {
  const points = `${cx},${cy - h / 2} ${cx + w / 2},${cy} ${cx},${cy + h / 2} ${cx - w / 2},${cy}`;
  return `<polygon points="${points}" fill="${fill}" stroke="${stroke}" stroke-width="2"/>${mtext(cx, cy, Array.isArray(label) ? label : [label], { size, weight: 600, lineHeight: 18 })}`;
}

function activity(cx, cy, w, h, label, { fill = C.mintBg, stroke = C.green } = {}) {
  return `${rect(cx - w / 2, cy - h / 2, w, h, { fill, stroke, rx: 12, sw: 2 })}${mtext(cx, cy, Array.isArray(label) ? label : [label], { size: 15, weight: 600, lineHeight: 19 })}`;
}

function umlClass(x, y, w, title, attrs, methods, color = C.green) {
  const lh = 19;
  const head = 38;
  const pad = 10;
  const attrH = Math.max(1, attrs.length) * lh + pad * 2;
  const methH = Math.max(1, methods.length) * lh + pad * 2;
  const h = head + attrH + methH;

  let body = rect(x, y, w, h, { fill: C.paper, stroke: color, rx: 8, sw: 2 });
  body += `<path d="M ${x + 8} ${y} H ${x + w - 8} Q ${x + w} ${y} ${x + w} ${y + 8} V ${y + head} H ${x} V ${y + 8} Q ${x} ${y} ${x + 8} ${y} Z" fill="${color}"/>`;
  body += txt(x + w / 2, y + head / 2, title, { size: 17, weight: 700, anchor: 'middle', fill: '#FFFFFF' });

  let cy = y + head + pad + lh / 2;
  for (const item of attrs) {
    body += txt(x + 12, cy, item, { size: 14, fill: C.ink });
    cy += lh;
  }

  const sepY = y + head + attrH;
  body += line(x, sepY, x + w, sepY, { color, sw: 1.5, marker: false });
  cy = sepY + pad + lh / 2;
  for (const item of methods) {
    body += txt(x + 12, cy, item, { size: 14, fill: C.muted });
    cy += lh;
  }

  return { body, h, bottom: y + h, midY: y + h / 2 };
}

function save(name, content) {
  fs.writeFileSync(path.join(OUT, name), content, 'utf8');
  console.log(`created ${name}`);
}

// ------------------------------------------------------------
// 1. Use case diagram
// ------------------------------------------------------------
{
  const W = 1320;
  const H = 900;
  let b = '';
  b += txt(W / 2, 38, 'Use Case Diagram INVENTRA', { size: 25, weight: 700, anchor: 'middle', fill: C.dark });
  b += rect(300, 70, 760, 780, { fill: C.soft, stroke: C.green, rx: 24, sw: 2, dash: '10 8' });
  b += txt(680, 100, 'Sistem INVENTRA', { size: 19, weight: 700, anchor: 'middle', fill: C.green });

  b += actor(120, 450, 'Staff', C.blue);
  b += actor(1210, 450, 'Admin', C.amber);

  const left = 500;
  const right = 880;
  const rows = [150, 225, 300, 375, 450, 525, 600, 675, 750];

  const leftCases = [
    ['Login', 'public'],
    ['Register', 'public'],
    ['Dashboard', 'staff'],
    ['Profil & Logout', 'staff'],
    ['Kelola Stok', 'staff'],
    ['Transaksi Penjualan', 'staff'],
    ['Riwayat Transaksi', 'staff'],
    ['Laporan', 'staff'],
    ['Notifikasi Stok', 'staff'],
  ];

  const rightCases = [
    ['Kelola Kategori', 'admin'],
    ['Kelola Supplier', 'admin'],
    ['Kelola Produk', 'admin'],
    ['Upload Gambar', 'admin'],
    ['Pembatalan Penjualan', 'admin'],
    [['Daftar Pengguna', '(API)'], 'admin'],
  ];

  const styleFor = (kind) => {
    if (kind === 'admin') return { fill: C.amberBg, stroke: C.amber };
    if (kind === 'public') return { fill: C.mint, stroke: C.green };
    return { fill: C.blueBg, stroke: C.blue };
  };

  leftCases.forEach(([label, kind], index) => {
    const y = rows[index];
    b += line(155, 438, left - 90, y, { color: C.blue, sw: 1.7, marker: true, markerId: 'arrowBlue' });
    b += ellipse(left, y, 92, 30, label, { ...styleFor(kind), size: 15 });
  });

  rightCases.forEach(([label, kind], index) => {
    const y = rows[index];
    b += line(1165, 438, right + 92, y, { color: C.amber, sw: 1.7, marker: true, markerId: 'arrowAmber' });
    b += ellipse(right, y, 92, 30, label, { ...styleFor(kind), size: 15 });
  });

  b += line(left, 525, left, 480, { color: C.green, sw: 1.5, dash: '6 5' });
  b += line(right, 375, right, 330, { color: C.green, sw: 1.5, dash: '6 5' });

  b += rect(600, 300, 170, 132, { fill: '#FFFFFF', stroke: C.border, rx: 12, sw: 1.5 });
  b += mtext(685, 366, ['Catatan:', 'Admin memiliki seluruh', 'akses Staff ditambah', 'fitur master data.'], { size: 13, fill: C.muted, lineHeight: 19 });
  b += rect(600, 510, 170, 120, { fill: '#FFFFFF', stroke: C.border, rx: 12, sw: 1.5 });
  b += mtext(685, 570, ['Registrasi publik', 'hanya membuat akun', 'dengan role staff.'], { size: 13, fill: C.muted, lineHeight: 19 });

  b += rect(340, 786, 600, 54, { fill: '#FFFFFF', stroke: C.border, rx: 8, sw: 1 });
  b += txt(640, 805, 'Biru = fitur operasional Staff   |   Kuning = fitur Admin   |   Hijau = akses publik', { size: 13, anchor: 'middle', fill: C.muted });
  b += txt(640, 825, 'Garis putus-putus menunjukkan relasi <<include>> atau <<extend>>.', { size: 12, anchor: 'middle', fill: C.muted, italic: true });

  save('use_case.svg', svgDoc(W, H, b));
}

// ------------------------------------------------------------
// 2. Activity diagram - login
// ------------------------------------------------------------
{
  const W = 900;
  const H = 1080;
  let b = '';
  b += txt(W / 2, 34, 'Activity Diagram Login INVENTRA', { size: 24, weight: 700, anchor: 'middle', fill: C.dark });
  b += `<circle cx="450" cy="78" r="19" fill="${C.dark}"/>`;
  b += line(450, 97, 450, 120);
  b += activity(450, 148, 320, 54, 'Buka aplikasi INVENTRA', { fill: C.blueBg, stroke: C.blue });
  b += line(450, 175, 450, 205);
  b += activity(450, 233, 320, 54, 'Masukkan email dan password', { fill: C.blueBg, stroke: C.blue });
  b += line(450, 260, 450, 292);
  b += diamond(450, 335, 220, 86, 'Validasi form?');
  b += line(450, 378, 450, 415);
  b += activity(450, 443, 330, 54, 'Kirim permintaan login ke API', { fill: C.mintBg, stroke: C.green });
  b += line(450, 470, 450, 502);
  b += diamond(450, 545, 240, 86, 'Kredensial valid?');
  b += line(450, 588, 450, 625);
  b += activity(450, 653, 330, 54, 'Simpan token JWT dan data user', { fill: C.mintBg, stroke: C.green });
  b += line(450, 680, 450, 712);
  b += activity(450, 740, 330, 54, 'Tampilkan dashboard sesuai role', { fill: C.mintBg, stroke: C.green });
  b += line(450, 767, 450, 802);
  b += diamond(450, 845, 190, 82, 'Logout?');
  b += line(450, 886, 450, 922);
  b += activity(450, 950, 300, 54, 'Hapus sesi dan token', { fill: C.blueBg, stroke: C.blue });
  b += line(450, 977, 450, 1012);
  b += `<circle cx="450" cy="1032" r="19" fill="${C.paper}" stroke="${C.dark}" stroke-width="4"/><circle cx="450" cy="1032" r="11" fill="${C.dark}"/>`;

  b += line(560, 335, 700, 335, { color: C.red, sw: 1.7 });
  b += activity(700, 335, 220, 58, ['Tampilkan pesan', 'validasi'], { fill: C.redBg, stroke: C.red });
  b += pathEl('M 810 306 L 810 233 L 610 233', { color: C.red, sw: 1.7 });
  b += txt(815, 270, 'perbaiki input', { size: 13, fill: C.red, italic: true });

  b += line(570, 545, 700, 545, { color: C.red, sw: 1.7 });
  b += activity(700, 545, 220, 58, ['Tampilkan pesan', 'login gagal'], { fill: C.redBg, stroke: C.red });
  b += pathEl('M 810 516 L 810 233 L 610 233', { color: C.red, sw: 1.7 });
  b += txt(815, 480, 'coba lagi', { size: 13, fill: C.red, italic: true });

  b += line(545, 845, 700, 845, { color: C.blue, sw: 1.7 });
  b += activity(700, 845, 220, 58, ['Tetap di aplikasi', '(belum logout)'], { fill: C.blueBg, stroke: C.blue });
  b += txt(700, 900, 'Tidak', { size: 13, fill: C.muted, anchor: 'middle' });
  b += txt(700, 380, 'Tidak', { size: 13, fill: C.muted, anchor: 'middle' });
  b += txt(700, 590, 'Tidak', { size: 13, fill: C.muted, anchor: 'middle' });
  b += txt(510, 885, 'Ya', { size: 13, fill: C.muted });

  save('activity_login.svg', svgDoc(W, H, b));
}

// ------------------------------------------------------------
// 3. Activity diagram - sale
// ------------------------------------------------------------
{
  const W = 1000;
  const H = 1200;
  let b = '';
  b += txt(W / 2, 34, 'Activity Diagram Transaksi Penjualan', { size: 24, weight: 700, anchor: 'middle', fill: C.dark });
  b += `<circle cx="500" cy="78" r="19" fill="${C.dark}"/>`;
  b += line(500, 97, 500, 120);
  b += activity(500, 148, 340, 54, 'Pilih menu Transaksi', { fill: C.blueBg, stroke: C.blue });
  b += line(500, 175, 500, 205);
  b += activity(500, 233, 340, 54, 'Pilih produk dan jumlah', { fill: C.blueBg, stroke: C.blue });
  b += line(500, 260, 500, 290);
  b += activity(500, 318, 340, 54, 'Tambahkan ke keranjang', { fill: C.blueBg, stroke: C.blue });
  b += line(500, 345, 500, 378);
  b += diamond(500, 420, 240, 84, 'Tambah barang lagi?');
  b += line(500, 462, 500, 495);
  b += activity(500, 523, 340, 54, 'Klik Simpan Transaksi', { fill: C.blueBg, stroke: C.blue });
  b += line(500, 550, 500, 582);
  b += activity(500, 610, 390, 58, ['API memvalidasi stok', 'dan menghitung total'], { fill: C.mintBg, stroke: C.green });
  b += line(500, 639, 500, 672);
  b += diamond(500, 714, 250, 84, 'Stok mencukupi?');
  b += line(500, 756, 500, 790);
  b += activity(500, 818, 340, 54, 'Simpan sales dan sale_items', { fill: C.mintBg, stroke: C.green });
  b += line(500, 845, 500, 875);
  b += activity(500, 903, 340, 54, 'Kurangi stok dan catat movement out', { fill: C.mintBg, stroke: C.green });
  b += line(500, 930, 500, 960);
  b += activity(500, 988, 300, 54, 'Commit transaksi', { fill: C.mintBg, stroke: C.green });
  b += line(500, 1015, 500, 1045);
  b += activity(500, 1073, 340, 54, 'Tampilkan sukses dan riwayat', { fill: C.blueBg, stroke: C.blue });
  b += line(500, 1100, 500, 1134);
  b += `<circle cx="500" cy="1154" r="19" fill="${C.paper}" stroke="${C.dark}" stroke-width="4"/><circle cx="500" cy="1154" r="11" fill="${C.dark}"/>`;

  b += pathEl('M 620 420 L 760 420 L 760 315 L 670 315', { color: C.blue, sw: 1.7 });
  b += txt(690, 285, 'Ya', { size: 13, fill: C.muted, anchor: 'middle' });
  b += txt(690, 465, 'Tidak', { size: 13, fill: C.muted, anchor: 'middle' });

  b += line(625, 714, 750, 714, { color: C.red, sw: 1.7 });
  b += activity(790, 714, 240, 62, ['Tampilkan error;', 'transaksi dibatalkan'], { fill: C.redBg, stroke: C.red });
  b += pathEl('M 790 683 L 790 560 L 670 560', { color: C.red, sw: 1.7 });
  b += txt(800, 640, 'perbaiki jumlah', { size: 13, fill: C.red, italic: true });

  b += txt(500, 1188, 'Seluruh proses simpan berjalan dalam satu transaksi database (rollback jika gagal).', { size: 12, anchor: 'middle', fill: C.muted, italic: true });

  save('activity_sale.svg', svgDoc(W, H, b));
}

// ------------------------------------------------------------
// 4. Class diagram
// ------------------------------------------------------------
{
  const W = 1420;
  const H = 980;
  let b = '';
  b += txt(W / 2, 34, 'Class Diagram Domain INVENTRA', { size: 25, weight: 700, anchor: 'middle', fill: C.dark });

  const user = umlClass(70, 80, 310, 'User', [
    '- id: BIGINT',
    '- name: VARCHAR(100)',
    '- email: VARCHAR(150)',
    '- password_hash: TEXT',
    '- role: user_role',
    '- is_active: BOOLEAN',
  ], ['+ login()', '+ logout()', '+ hasRole(role): bool'], C.green);

  const category = umlClass(70, 460, 310, 'Category', [
    '- id: BIGINT',
    '- name: VARCHAR(100)',
    '- description: TEXT',
  ], ['+ create()', '+ update()', '+ delete()'], C.green);

  const supplier = umlClass(70, 700, 310, 'Supplier', [
    '- id: BIGINT',
    '- name: VARCHAR(150)',
    '- phone: VARCHAR(30)',
    '- email: VARCHAR(150)',
    '- address: TEXT',
  ], ['+ create()', '+ update()', '+ delete()'], C.green);

  const product = umlClass(540, 300, 350, 'Product', [
    '- id: BIGINT',
    '- category_id: BIGINT',
    '- sku: VARCHAR(50)',
    '- name: VARCHAR(150)',
    '- price: NUMERIC(12,2)',
    '- stock: INTEGER',
    '- min_stock: INTEGER',
    '- image_url: TEXT',
  ], ['+ isLowStock(): bool', '+ updateStock()', '+ uploadImage()'], C.green);

  const movement = umlClass(1040, 80, 330, 'StockMovement', [
    '- id: BIGINT',
    '- product_id: BIGINT',
    '- user_id: BIGINT',
    '- type: movement_type',
    '- quantity: INTEGER',
    '- note: TEXT',
    '- created_at: TIMESTAMPTZ',
  ], ['+ record()'], C.green);

  const sale = umlClass(1040, 430, 330, 'Sale', [
    '- id: BIGINT',
    '- user_id: BIGINT',
    '- total: NUMERIC(14,2)',
    '- created_at: TIMESTAMPTZ',
  ], ['+ calculateTotal()', '+ cancel()'], C.green);

  const item = umlClass(1040, 680, 330, 'SaleItem', [
    '- id: BIGINT',
    '- sale_id: BIGINT',
    '- product_id: BIGINT',
    '- product_name: VARCHAR(150)',
    '- price: NUMERIC(12,2)',
    '- quantity: INTEGER',
    '- subtotal: NUMERIC(14,2)',
  ], ['+ calculateSubtotal()'], C.green);

  b += user.body + category.body + supplier.body + product.body + movement.body + sale.body + item.body;

  b += line(380, 520, 540, 520, { marker: false });
  b += txt(390, 505, '1', { size: 14, fill: C.muted });
  b += txt(510, 505, '0..*', { size: 14, fill: C.muted, anchor: 'end' });

  b += pathEl('M 890 380 L 1040 300', { marker: false });
  b += txt(905, 335, '1', { size: 14, fill: C.muted });
  b += txt(1020, 290, '0..*', { size: 14, fill: C.muted, anchor: 'end' });

  b += pathEl('M 890 620 L 1040 760', { marker: false });
  b += txt(905, 675, '1', { size: 14, fill: C.muted });
  b += txt(1020, 742, '0..*', { size: 14, fill: C.muted, anchor: 'end' });

  b += line(1205, 638, 1205, 680, { marker: false });
  b += txt(1215, 650, '1', { size: 14, fill: C.muted });
  b += txt(1215, 675, '0..*', { size: 14, fill: C.muted });

  b += pathEl('M 380 180 L 930 180 L 930 500 L 1040 500', { marker: false });
  b += txt(392, 166, '1', { size: 14, fill: C.muted });
  b += txt(1025, 485, '0..*', { size: 14, fill: C.muted, anchor: 'end' });

  b += pathEl('M 380 240 L 930 240 L 930 220 L 1040 220', { marker: false });
  b += txt(392, 226, '1', { size: 14, fill: C.muted });
  b += txt(1025, 205, '0..*', { size: 14, fill: C.muted, anchor: 'end' });

  b += rect(490, 790, 520, 110, { fill: '#FFFFFF', stroke: C.border, rx: 12, sw: 1.2 });
  b += mtext(750, 845, [
    'Catatan: diagram ini adalah model domain konseptual.',
    'Implementasi Flutter memakai widget, ApiClient, AuthService, dan Session.',
  ], { size: 13, fill: C.muted, lineHeight: 20 });

  save('class_diagram.svg', svgDoc(W, H, b));
}

// ------------------------------------------------------------
// 5. Gantt chart
// ------------------------------------------------------------
{
  const W = 1200;
  const H = 650;
  const left = 310;
  const top = 95;
  const rowH = 46;
  const weekW = 100;
  const weeks = 8;
  let b = '';
  b += txt(W / 2, 34, 'Jadwal Pengembangan INVENTRA (8 Minggu)', { size: 24, weight: 700, anchor: 'middle', fill: C.dark });

  b += rect(left, top, weekW * weeks, 36, { fill: C.dark, stroke: C.dark, rx: 0, sw: 0 });
  for (let i = 0; i < weeks; i += 1) {
    b += line(left + i * weekW, top, left + i * weekW, top + 36 + rowH * 10, { color: C.border, sw: 1, marker: false });
    b += txt(left + i * weekW + weekW / 2, top + 18, `M${i + 1}`, { size: 14, weight: 700, anchor: 'middle', fill: '#FFFFFF' });
  }

  const tasks = [
    ['Analisis kebutuhan & SRS', 1, 2, C.green],
    ['Desain UI/UX', 2, 1, C.blue],
    ['Desain database & ERD', 2, 1, C.green],
    ['Setup backend & autentikasi', 3, 2, C.green],
    ['Modul master data', 4, 2, C.blue],
    ['Modul stok', 5, 2, C.green],
    ['Modul penjualan & laporan', 6, 2, C.blue],
    ['Integrasi Flutter', 6, 2, C.green],
    ['Pengujian blackbox', 7, 2, C.amber],
    ['Deployment & dokumentasi', 8, 1, C.dark],
  ];

  tasks.forEach(([label, start, length, color], index) => {
    const y = top + 36 + index * rowH;
    if (index % 2 === 0) {
      b += rect(40, y, W - 80, rowH, { fill: '#F8FAFC', stroke: '#F8FAFC', rx: 0, sw: 0 });
    }
    b += txt(55, y + rowH / 2, label, { size: 14, weight: index % 2 === 0 ? 600 : 400, fill: C.ink });
    const x = left + (start - 1) * weekW + 8;
    const w = length * weekW - 16;
    b += rect(x, y + 10, w, rowH - 20, { fill: color, stroke: color, rx: 8, sw: 0 });
    b += txt(x + w / 2, y + rowH / 2, `M${start}${length > 1 ? `-M${start + length - 1}` : ''}`, { size: 12, weight: 700, anchor: 'middle', fill: '#FFFFFF' });
  });

  b += line(left, top + 36 + tasks.length * rowH, left + weekW * weeks, top + 36 + tasks.length * rowH, { color: C.ink, sw: 1.5, marker: false });
  b += line(left, top, left, top + 36 + tasks.length * rowH, { color: C.ink, sw: 1.5, marker: false });

  b += txt(W / 2, 605, 'Milestone: M1 requirement & desain, M2 backend inti, M3 penjualan & laporan, M4 pengujian & deploy.', { size: 13, anchor: 'middle', fill: C.muted });

  save('gantt.svg', svgDoc(W, H, b));
}

// ------------------------------------------------------------
// 6. Deployment architecture
// ------------------------------------------------------------
{
  const W = 1200;
  const H = 650;
  let b = '';
  b += txt(W / 2, 34, 'Arsitektur Deployment INVENTRA', { size: 25, weight: 700, anchor: 'middle', fill: C.dark });

  b += rect(50, 250, 210, 120, { fill: C.blueBg, stroke: C.blue, rx: 14, sw: 2 });
  b += mtext(155, 310, ['Pengguna', 'Browser / Android'], { size: 17, weight: 600, lineHeight: 24 });

  b += rect(330, 250, 220, 120, { fill: C.mintBg, stroke: C.green, rx: 14, sw: 2 });
  b += mtext(440, 310, ['Frontend Flutter', 'Netlify / Vercel'], { size: 17, weight: 600, lineHeight: 24 });

  b += rect(620, 250, 220, 120, { fill: C.amberBg, stroke: C.amber, rx: 14, sw: 2 });
  b += mtext(730, 310, ['REST API Express', 'Render / Vercel'], { size: 17, weight: 600, lineHeight: 24 });

  b += rect(920, 110, 220, 110, { fill: C.mintBg, stroke: C.green, rx: 14, sw: 2 });
  b += mtext(1030, 165, ['PostgreSQL', 'Aiven (SSL)'], { size: 17, weight: 600, lineHeight: 24 });

  b += rect(920, 400, 220, 110, { fill: C.blueBg, stroke: C.blue, rx: 14, sw: 2 });
  b += mtext(1030, 455, ['Cloudinary', 'Penyimpanan gambar'], { size: 17, weight: 600, lineHeight: 24 });

  b += rect(620, 500, 220, 90, { fill: '#F1F5F9', stroke: C.muted, rx: 14, sw: 2 });
  b += mtext(730, 545, ['GitHub', 'Repository + branch'], { size: 17, weight: 600, lineHeight: 24 });

  b += line(260, 310, 330, 310);
  b += txt(280, 290, 'HTTPS', { size: 12, fill: C.muted });
  b += line(550, 310, 620, 310);
  b += txt(565, 290, 'JSON + JWT', { size: 12, fill: C.muted });
  b += line(840, 300, 920, 190, { color: C.green });
  b += txt(860, 225, 'SSL', { size: 12, fill: C.muted });
  b += line(840, 330, 920, 450, { color: C.blue });
  b += txt(860, 405, 'HTTPS', { size: 12, fill: C.muted });
  b += pathEl('M 730 500 L 730 370', { color: C.muted, dash: '7 5', marker: true });
  b += txt(745, 440, 'deploy', { size: 12, fill: C.muted, italic: true });
  b += pathEl('M 730 500 L 440 370', { color: C.muted, dash: '7 5', marker: true });
  b += txt(500, 455, 'deploy', { size: 12, fill: C.muted, italic: true });

  b += txt(W / 2, 625, 'Semua komunikasi produksi menggunakan HTTPS. Database Aiven diakses dengan SSL.', { size: 13, anchor: 'middle', fill: C.muted });

  save('architecture.svg', svgDoc(W, H, b));
}

console.log('Selesai membuat diagram SVG.');

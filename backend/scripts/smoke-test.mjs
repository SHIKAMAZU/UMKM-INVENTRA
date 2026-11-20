const BASE = process.env.API_URL ?? 'http://localhost:3000';

let passed = 0;
let failed = 0;

function check(name, condition, detail = '') {
  if (condition) {
    passed += 1;
    console.log(`PASS  ${name}`);
  } else {
    failed += 1;
    console.log(`FAIL  ${name} ${detail}`);
  }
}

async function request(path, { method = 'GET', token, body, form } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body) headers['Content-Type'] = 'application/json';

  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: form ?? (body ? JSON.stringify(body) : undefined),
  });

  let json = null;
  try {
    json = await res.json();
  } catch {
    json = null;
  }
  return { status: res.status, json };
}

async function login(email, password) {
  const res = await request('/api/auth/login', { method: 'POST', body: { email, password } });
  return res.json?.data?.token;
}

async function main() {
  const suffix = Date.now();

  const health = await request('/api/health');
  check('GET /api/health -> 200', health.status === 200, JSON.stringify(health.json));

  const unauth = await request('/api/products');
  check('GET /api/products tanpa token -> 401', unauth.status === 401, JSON.stringify(unauth.json));

  const badRegister = await request('/api/auth/register', {
    method: 'POST',
    body: { name: 'X', email: 'bukan-email', password: '123' },
  });
  check('register invalid -> 422', badRegister.status === 422, JSON.stringify(badRegister.json));

  const adminToken = await login('admin@toko.test', 'admin123');
  const staffToken = await login('user@toko.test', 'user123');
  check('login admin', Boolean(adminToken));
  check('login staff', Boolean(staffToken));

  const wrongPassword = await request('/api/auth/login', {
    method: 'POST',
    body: { email: 'admin@toko.test', password: 'salah' },
  });
  check('login password salah -> 401', wrongPassword.status === 401);

  const me = await request('/api/auth/me', { token: adminToken });
  check('GET /api/auth/me -> admin', me.json?.data?.role === 'admin');

  const products = await request('/api/products?limit=100', { token: staffToken });
  check(
    'staff GET products -> 200 + data',
    products.status === 200 && Array.isArray(products.json?.data) && products.json.data.length > 0
  );

  const category = await request('/api/categories', {
    method: 'POST',
    token: adminToken,
    body: { name: `Kategori Uji ${suffix}`, description: 'dibuat oleh smoke test' },
  });
  check('admin POST category -> 201', category.status === 201, JSON.stringify(category.json));
  const categoryId = category.json?.data?.id;

  const staffCreateCategory = await request('/api/categories', {
    method: 'POST',
    token: staffToken,
    body: { name: `Staff Dilarang ${suffix}` },
  });
  check('staff POST category -> 403', staffCreateCategory.status === 403);

  const product = await request('/api/products', {
    method: 'POST',
    token: adminToken,
    body: {
      category_id: categoryId,
      sku: `UJI-${suffix}`,
      name: 'Produk Uji',
      description: 'produk untuk smoke test',
      price: 15000,
      stock: 10,
      min_stock: 3,
    },
  });
  check('admin POST product -> 201', product.status === 201, JSON.stringify(product.json));
  const productId = product.json?.data?.id;

  const staffCreateProduct = await request('/api/products', {
    method: 'POST',
    token: staffToken,
    body: { category_id: categoryId, sku: `STF-${suffix}`, name: 'Staff Dilarang', price: 1000 },
  });
  check('staff POST product -> 403', staffCreateProduct.status === 403);

  const stockIn = await request(`/api/products/${productId}/stock`, {
    method: 'POST',
    token: staffToken,
    body: { type: 'in', quantity: 5, note: 'uji stok masuk' },
  });
  check(
    'staff POST stock in -> 201 stok 15',
    stockIn.status === 201 && stockIn.json?.data?.product?.stock === 15,
    JSON.stringify(stockIn.json)
  );

  const stockOut = await request(`/api/products/${productId}/stock`, {
    method: 'POST',
    token: staffToken,
    body: { type: 'out', quantity: 100 },
  });
  check('stock out melebihi stok -> 400', stockOut.status === 400, JSON.stringify(stockOut.json));

  const png = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    'base64'
  );
  const form = new FormData();
  form.append('image', new Blob([png], { type: 'image/png' }), 'test.png');
  const upload = await request(`/api/products/${productId}/image`, {
    method: 'POST',
    token: adminToken,
    form,
  });
  check(
    'admin upload gambar -> 200 + image_url',
    upload.status === 200 && Boolean(upload.json?.data?.image_url),
    JSON.stringify(upload.json)
  );

  const imageUrl = upload.json?.data?.image_url;
  if (imageUrl) {
    const fullImageUrl = /^https?:\/\//i.test(imageUrl) ? imageUrl : `${BASE}${imageUrl}`;
    const imageRes = await fetch(fullImageUrl);
    check('GET gambar terunggah -> 200', imageRes.status === 200);
  }

  const wrongType = new FormData();
  wrongType.append('image', new Blob(['bukan gambar'], { type: 'text/plain' }), 'test.txt');
  const badUpload = await request(`/api/products/${productId}/image`, {
    method: 'POST',
    token: adminToken,
    form: wrongType,
  });
  check('upload tipe salah -> 422', badUpload.status === 422, JSON.stringify(badUpload.json));

  const movements = await request('/api/stock-movements?limit=100', { token: adminToken });
  check('admin GET stock-movements -> 200', movements.status === 200);

  const staffMovements = await request('/api/stock-movements', { token: staffToken });
  check('staff GET stock-movements -> 403', staffMovements.status === 403);

  const users = await request('/api/users', { token: adminToken });
  check('admin GET users -> 200', users.status === 200);

  const duplicateSku = await request('/api/products', {
    method: 'POST',
    token: adminToken,
    body: { category_id: categoryId, sku: `UJI-${suffix}`, name: 'Duplikat', price: 1000 },
  });
  check('SKU duplikat -> 409', duplicateSku.status === 409, JSON.stringify(duplicateSku.json));

  const notFound = await request('/api/products/99999999', { token: adminToken });
  check('produk tidak ada -> 404', notFound.status === 404);

  const del = await request(`/api/products/${productId}`, { method: 'DELETE', token: adminToken });
  check('admin DELETE product -> 200', del.status === 200);

  const delCategory = await request(`/api/categories/${categoryId}`, {
    method: 'DELETE',
    token: adminToken,
  });
  check('admin DELETE category -> 200', delCategory.status === 200);

  console.log(`\nHasil: ${passed} lulus, ${failed} gagal`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((err) => {
  console.error('Smoke test error:', err);
  process.exit(1);
});

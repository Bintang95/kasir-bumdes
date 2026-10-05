const express = require('express');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const sqlite3 = require('sqlite3').verbose();

const app = express();
const PORT = process.env.PORT || 3000;
const dataDir = path.join(__dirname, 'data');
const dbPath = path.join(dataDir, 'bumdes.db');

if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const db = new sqlite3.Database(dbPath);

function hashValue(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) return reject(err);
      resolve({ id: this.lastID, changes: this.changes });
    });
  });
}

function get(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) return reject(err);
      resolve(row);
    });
  });
}

function all(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) return reject(err);
      resolve(rows);
    });
  });
}

async function initDatabase() {
  await run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'admin',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      barcode TEXT UNIQUE NOT NULL,
      sku TEXT UNIQUE,
      name TEXT NOT NULL,
      category TEXT DEFAULT 'Umum',
      purchase_price INTEGER NOT NULL DEFAULT 0,
      selling_price INTEGER NOT NULL DEFAULT 0,
      stock INTEGER NOT NULL DEFAULT 0,
      unit TEXT DEFAULT 'pcs',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_code TEXT UNIQUE NOT NULL,
      customer_name TEXT,
      payment_type TEXT DEFAULT 'Tunai',
      total_amount INTEGER NOT NULL DEFAULT 0,
      total_profit INTEGER NOT NULL DEFAULT 0,
      created_by INTEGER,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS transaction_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      unit_price INTEGER NOT NULL,
      purchase_price INTEGER NOT NULL,
      subtotal INTEGER NOT NULL,
      profit INTEGER NOT NULL,
      FOREIGN KEY (transaction_id) REFERENCES transactions(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    )
  `);

  const adminUser = await get('SELECT id FROM users WHERE username = ?', ['admin']);

  if (!adminUser) {
    await run(
      'INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)',
      ['admin', hashValue('admin123'), 'admin']
    );
  }

  const productCount = await get('SELECT COUNT(*) AS total FROM products');

  if (productCount.total === 0) {
    const seedProducts = [
      ['123456789012', 'BR-001', 'Beras 5kg', 'Sembako', 42000, 55000, 25, 'karung'],
      ['987654321098', 'MN-002', 'Minyak Goreng 2L', 'Sembako', 25000, 32000, 18, 'botol'],
      ['111222333444', 'GL-003', 'Gula Pasir 1kg', 'Sembako', 12000, 15000, 30, 'karung'],
      ['555666777888', 'TE-004', 'Telur 1kg', 'Pangan', 22000, 28000, 16, 'kg'],
      ['444333222111', 'SK-005', 'Sabun Cuci 1L', 'Peralatan', 15000, 22000, 14, 'pcs'],
    ];

    for (const product of seedProducts) {
      await run(
        `INSERT INTO products (barcode, sku, name, category, purchase_price, selling_price, stock, unit) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        product
      );
    }
  }
}

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'BUMDes cashier API ready' });
});

app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Username dan password wajib diisi' });
  }

  const user = await get('SELECT * FROM users WHERE username = ?', [username]);

  if (!user) {
    return res.status(401).json({ message: 'Username tidak ditemukan' });
  }

  const passwordHash = hashValue(password);

  if (user.password_hash !== passwordHash) {
    return res.status(401).json({ message: 'Password salah' });
  }

  res.json({
    token: `bumdes-${user.id}-${Date.now()}`,
    user: {
      id: user.id,
      username: user.username,
      role: user.role,
    },
  });
});

app.get('/api/products', async (req, res) => {
  const { search = '', category = '' } = req.query;
  let where = [];
  let params = [];

  if (search) {
    where.push('(name LIKE ? OR barcode LIKE ? OR sku LIKE ?)');
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }

  if (category) {
    where.push('category = ?');
    params.push(category);
  }

  const sql = `
    SELECT * FROM products
    ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
    ORDER BY name ASC
  `;

  const products = await all(sql, params);
  res.json(products);
});

app.get('/api/products/categories', async (req, res) => {
  const rows = await all('SELECT DISTINCT category FROM products ORDER BY category ASC');
  res.json(rows.map((row) => row.category));
});

app.post('/api/products', async (req, res) => {
  const product = req.body;

  if (!product.barcode || !product.name || !product.selling_price) {
    return res.status(400).json({ message: 'Barcode, nama, dan harga jual wajib diisi' });
  }

  try {
    const result = await run(
      `INSERT INTO products (barcode, sku, name, category, purchase_price, selling_price, stock, unit)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        product.barcode.trim(),
        product.sku ? product.sku.trim() : null,
        product.name.trim(),
        product.category || 'Umum',
        Number(product.purchase_price || 0),
        Number(product.selling_price),
        Number(product.stock || 0),
        product.unit || 'pcs',
      ]
    );

    const created = await get('SELECT * FROM products WHERE id = ?', [result.id]);
    res.status(201).json(created);
  } catch (error) {
    if (error.code === 'SQLITE_CONSTRAINT') {
      return res.status(409).json({ message: 'Barcode atau SKU sudah digunakan' });
    }
    res.status(500).json({ message: 'Gagal menyimpan produk', error: error.message });
  }
});

app.put('/api/products/:id', async (req, res) => {
  const { id } = req.params;
  const product = req.body;

  try {
    await run(
      `UPDATE products
       SET barcode = ?, sku = ?, name = ?, category = ?, purchase_price = ?, selling_price = ?, stock = ?, unit = ?, updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [
        product.barcode.trim(),
        product.sku ? product.sku.trim() : null,
        product.name.trim(),
        product.category || 'Umum',
        Number(product.purchase_price || 0),
        Number(product.selling_price),
        Number(product.stock || 0),
        product.unit || 'pcs',
        id,
      ]
    );

    const updated = await get('SELECT * FROM products WHERE id = ?', [id]);
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengupdate produk', error: error.message });
  }
});

app.delete('/api/products/:id', async (req, res) => {
  const { id } = req.params;

  try {
    await run('DELETE FROM products WHERE id = ?', [id]);
    res.json({ message: 'Produk berhasil dihapus' });
  } catch (error) {
    res.status(500).json({ message: 'Gagal menghapus produk', error: error.message });
  }
});

app.get('/api/products/:barcode', async (req, res) => {
  const product = await get('SELECT * FROM products WHERE barcode = ?', [req.params.barcode]);

  if (!product) {
    return res.status(404).json({ message: 'Produk tidak ditemukan' });
  }

  res.json(product);
});

app.get('/api/transactions', async (req, res) => {
  const rows = await all(`
    SELECT t.*, u.username AS cashier_name
    FROM transactions t
    LEFT JOIN users u ON u.id = t.created_by
    ORDER BY t.created_at DESC
  `);

  res.json(rows);
});

app.get('/api/reports/summary', async (req, res) => {
  const { from, to } = req.query;

  let whereClause = '';
  const params = [];

  if (from) {
    whereClause += ' AND date(t.created_at) >= date(?)';
    params.push(from);
  }

  if (to) {
    whereClause += ' AND date(t.created_at) <= date(?)';
    params.push(to);
  }

  const summary = await get(`
    SELECT
      COUNT(t.id) AS total_transactions,
      COALESCE(SUM(t.total_amount), 0) AS total_sales,
      COALESCE(SUM(t.total_profit), 0) AS total_profit,
      COALESCE(SUM((SELECT COUNT(*) FROM transaction_items ti WHERE ti.transaction_id = t.id)), 0) AS total_items
    FROM transactions t
    WHERE 1=1 ${whereClause}
  `, params);

  const transactions = await all(`
    SELECT t.*, u.username AS cashier_name
    FROM transactions t
    LEFT JOIN users u ON u.id = t.created_by
    WHERE 1=1 ${whereClause}
    ORDER BY t.created_at DESC
  `, params);

  res.json({ summary, transactions });
});

app.post('/api/transactions', async (req, res) => {
  const { items, customerName, paymentType, cashierId } = req.body;

  if (!Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ message: 'Tidak ada produk dalam transaksi' });
  }

  try {
    const transactionCode = `TRX-${Date.now()}`;

    let totalAmount = 0;
    let totalProfit = 0;
    const preparedItems = [];

    for (const item of items) {
      const product = await get('SELECT * FROM products WHERE id = ?', [item.productId]);

      if (!product) {
        throw new Error(`Produk tidak ditemukan: ${item.productId}`);
      }

      if (product.stock < item.quantity) {
        throw new Error(`Stok ${product.name} tidak mencukupi`);
      }

      const subtotal = Number(product.selling_price) * Number(item.quantity);
      const profit = (Number(product.selling_price) - Number(product.purchase_price)) * Number(item.quantity);

      totalAmount += subtotal;
      totalProfit += profit;

      preparedItems.push({
        productId: product.id,
        productName: product.name,
        quantity: Number(item.quantity),
        unitPrice: Number(product.selling_price),
        purchasePrice: Number(product.purchase_price),
        subtotal,
        profit,
      });
    }

    const txResult = await run(
      `INSERT INTO transactions (transaction_code, customer_name, payment_type, total_amount, total_profit, created_by)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [transactionCode, customerName || 'Umum', paymentType || 'Tunai', totalAmount, totalProfit, cashierId || 1]
    );

    for (const item of preparedItems) {
      await run(
        `INSERT INTO transaction_items (transaction_id, product_id, product_name, quantity, unit_price, purchase_price, subtotal, profit)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [txResult.id, item.productId, item.productName, item.quantity, item.unitPrice, item.purchasePrice, item.subtotal, item.profit]
      );

      await run(
        `UPDATE products SET stock = stock - ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
        [item.quantity, item.productId]
      );
    }

    const transaction = await get('SELECT * FROM transactions WHERE id = ?', [txResult.id]);
    res.status(201).json({
      message: 'Transaksi berhasil disimpan',
      transaction,
      totalAmount,
      totalProfit,
    });
  } catch (error) {
    res.status(400).json({ message: error.message || 'Gagal memproses transaksi' });
  }
});

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

async function startServer() {
  await initDatabase();
  app.listen(PORT, () => {
    console.log(`BUMDes cashier running at http://localhost:${PORT}`);
  });
}

startServer().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});

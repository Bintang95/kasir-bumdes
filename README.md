const state = {
  token: null,
  user: null,
  products: [],
  users: [],
  cart: [],
  scanner: null,
  scannerEnabled: false,
};

const els = {};

function initElements() {
  els.loginView = document.getElementById('loginView');
  els.appView = document.getElementById('appView');
  els.loginForm = document.getElementById('loginForm');
  els.loginError = document.getElementById('loginError');
  els.username = document.getElementById('username');
  els.password = document.getElementById('password');
  els.cashierName = document.getElementById('cashierName');
  els.logoutBtn = document.getElementById('logoutBtn');
  els.tabButtons = document.querySelectorAll('.tab-button');
  els.productForm = document.getElementById('productForm');
  els.productTableBody = document.getElementById('productTableBody');
  els.categoryFilter = document.getElementById('categoryFilter');
  els.productSearch = document.getElementById('productSearch');
  els.productId = document.getElementById('productId');
  els.barcode = document.getElementById('barcode');
  els.sku = document.getElementById('sku');
  els.name = document.getElementById('name');
  els.category = document.getElementById('category');
  els.purchasePrice = document.getElementById('purchasePrice');
  els.sellingPrice = document.getElementById('sellingPrice');
  els.stock = document.getElementById('stock');
  els.minStock = document.getElementById('minStock');
  els.unit = document.getElementById('unit');
  els.cancelProductEdit = document.getElementById('cancelProductEdit');
  els.barcodeInput = document.getElementById('barcodeInput');
  els.addByBarcodeBtn = document.getElementById('addByBarcodeBtn');
  els.cartTable = document.getElementById('cartTable');
  els.checkoutBtn = document.getElementById('checkoutBtn');
  els.cartTotal = document.getElementById('cartTotal');
  els.customerName = document.getElementById('customerName');
  els.paymentType = document.getElementById('paymentType');
  els.quickProducts = document.getElementById('quickProducts');
  els.toggleScannerBtn = document.getElementById('toggleScannerBtn');
  els.scannerContainer = document.getElementById('scannerContainer');
  els.reportFrom = document.getElementById('reportFrom');
  els.reportTo = document.getElementById('reportTo');
  els.applyReportBtn = document.getElementById('applyReportBtn');
  els.exportPdfBtn = document.getElementById('exportPdfBtn');
  els.exportExcelBtn = document.getElementById('exportExcelBtn');
  els.reportTableBody = document.getElementById('reportTableBody');
  els.lowStockTable = document.getElementById('lowStockTable');
  els.latestTransactionsTable = document.getElementById('latestTransactionsTable');
  els.statSales = document.getElementById('statSales');
  els.statTransactions = document.getElementById('statTransactions');
  els.statProfit = document.getElementById('statProfit');
  els.statLowStock = document.getElementById('statLowStock');
  els.reportSales = document.getElementById('reportSales');
  els.reportProfit = document.getElementById('reportProfit');
  els.reportTransactions = document.getElementById('reportTransactions');
  els.usersTabButton = document.getElementById('usersTabButton');
  els.userForm = document.getElementById('userForm');
  els.userTableBody = document.getElementById('userTableBody');
  els.userId = document.getElementById('userId');
  els.userUsername = document.getElementById('userUsername');
  els.userPassword = document.getElementById('userPassword');
  els.userRole = document.getElementById('userRole');
  els.cancelUserEdit = document.getElementById('cancelUserEdit');
}

function formatCurrency(value) {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(Number(value || 0));
}

function setMessage(element, text, type = 'error') {
  element.textContent = text;
  element.classList.toggle('hidden', !text);
  element.classList.toggle('error', type === 'error');
}

function getAuthHeaders() {
  return {
    Authorization: `Bearer ${state.token}`,
  };
}

async function apiFetch(path, options = {}) {
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  const response = await fetch(path, {
    ...options,
    headers: {
      ...headers,
      ...getAuthHeaders(),
    },
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.message || 'Request failed');
  }
  return data;
}

async function login(event) {
  event.preventDefault();
  const username = els.username.value.trim();
  const password = els.password.value;

  try {
    const result = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    }).then(async (res) => {
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Login gagal');
      return data;
    });

    state.token = result.token;
    state.user = result.user;
    els.cashierName.textContent = result.user.username;
    setMessage(els.loginError, '', 'error');
    els.loginView.classList.add('hidden');
    els.appView.classList.remove('hidden');
    renderAccessControl();
    loadDashboard();
    loadProducts();
    loadReports();
    loadUsers();
  } catch (error) {
    setMessage(els.loginError, error.message, 'error');
  }
}

function logout() {
  state.token = null;
  state.user = null;
  state.cart = [];
  renderCart();
  els.appView.classList.add('hidden');
  els.loginView.classList.remove('hidden');
}

function renderAccessControl() {
  const canManageUsers = state.user && state.user.role === 'admin';
  const canManageProducts = state.user && ['admin', 'operator'].includes(state.user.role);
  const canManageSales = state.user && ['admin', 'cashier', 'operator'].includes(state.user.role);

  els.usersTabButton.style.display = canManageUsers ? 'inline-block' : 'none';
  document.querySelectorAll('.tab-button').forEach((button) => {
    if (button.dataset.tab === 'products' && !canManageProducts) button.style.display = 'none';
    if (button.dataset.tab === 'sales' && !canManageSales) button.style.display = 'none';
  });
}

async function loadDashboard() {
  try {
    const data = await apiFetch('/api/reports/summary');
    const summary = data.summary || {};
    els.statSales.textContent = formatCurrency(summary.total_sales || 0);
    els.statTransactions.textContent = Number(summary.total_transactions || 0);
    els.statProfit.textContent = formatCurrency(summary.total_profit || 0);

    const lowStock = await apiFetch('/api/products/low-stock');
    els.statLowStock.textContent = Array.isArray(lowStock) ? lowStock.length : 0;
    els.lowStockTable.innerHTML = '';

    if (lowStock.length) {
      lowStock.forEach((product) => {
        const row = document.createElement('tr');
        row.innerHTML = `
          <td>${product.name}</td>
          <td>${product.stock}</td>
          <td>${product.min_stock}</td>
        `;
        els.lowStockTable.appendChild(row);
      });
    } else {
      els.lowStockTable.innerHTML = '<tr><td colspan="3">Tidak ada stok minim</td></tr>';
    }

    els.latestTransactionsTable.innerHTML = '';
    (data.transactions || []).slice(0, 5).forEach((tx) => {
      const row = document.createElement('tr');
      row.innerHTML = `
        <td>${tx.transaction_code}</td>
        <td>${formatCurrency(tx.total_amount)}</td>
        <td>${new Date(tx.created_at).toLocaleString('id-ID')}</td>
      `;
      els.latestTransactionsTable.appendChild(row);
    });
  } catch (error) {
    console.error(error);
  }
}

async function loadProducts() {
  try {
    const search = els.productSearch.value.trim();
    const category = els.categoryFilter.value;
    const products = await apiFetch(`/api/products?search=${encodeURIComponent(search)}&category=${encodeURIComponent(category)}`);
    state.products = products;
    renderProductsTable();
    renderQuickProducts();
    renderCategories();
  } catch (error) {
    console.error(error);
  }
}

function renderCategories() {
  const categories = [...new Set(state.products.map((p) => p.category).filter(Boolean))];
  const selected = els.categoryFilter.value;
  els.categoryFilter.innerHTML = '<option value="">Semua kategori</option>';
  categories.forEach((category) => {
    const option = document.createElement('option');
    option.value = category;
    option.textContent = category;
    if (selected === category) option.selected = true;
    els.categoryFilter.appendChild(option);
  });
}

function renderProductsTable() {
  els.productTableBody.innerHTML = '';
  state.products.forEach((product) => {
    const row = document.createElement('tr');
    row.innerHTML = `
      <td>${product.barcode}</td>
      <td>${product.name}</td>
      <td>${product.category}</td>
      <td>${formatCurrency(product.purchase_price)}</td>
      <td>${formatCurrency(product.selling_price)}</td>
      <td>${product.stock}</td>
      <td>${product.min_stock || 0}</td>
      <td>
        <button class="secondary" data-action="edit" data-id="${product.id}">Edit</button>
        <button class="secondary" data-action="delete" data-id="${product.id}">Hapus</button>
      </td>
    `;
    els.productTableBody.appendChild(row);
  });

  els.productTableBody.querySelectorAll('button[data-action="edit"]').forEach((button) => {
    button.addEventListener('click', () => {
      const product = state.products.find((item) => item.id === Number(button.dataset.id));
      if (product) fillProductForm(product);
    });
  });

  els.productTableBody.querySelectorAll('button[data-action="delete"]').forEach((button) => {
    button.addEventListener('click', async () => {
      const productId = Number(button.dataset.id);
      if (confirm('Hapus produk ini?')) {
        await apiFetch(`/api/products/${productId}`, { method: 'DELETE' });
        loadProducts();
      }
    });
  });
}

function fillProductForm(product) {
  els.productId.value = product.id;
  els.barcode.value = product.barcode;
  els.sku.value = product.sku || '';
  els.name.value = product.name;
  els.category.value = product.category;
  els.purchasePrice.value = product.purchase_price;
  els.sellingPrice.value = product.selling_price;
  els.stock.value = product.stock;
  els.minStock.value = product.min_stock || 5;
  els.unit.value = product.unit;
  els.barcode.focus();
}

function resetProductForm() {
  els.productForm.reset();
  els.productId.value = '';
  els.category.value = 'Umum';
  els.unit.value = 'pcs';
  els.minStock.value = 5;
}

async function handleProductForm(event) {
  event.preventDefault();

  const payload = {
    barcode: els.barcode.value.trim(),
    sku: els.sku.value.trim(),
    name: els.name.value.trim(),
    category: els.category.value.trim() || 'Umum',
    purchase_price: Number(els.purchasePrice.value || 0),
    selling_price: Number(els.sellingPrice.value || 0),
    stock: Number(els.stock.value || 0),
    min_stock: Number(els.minStock.value || 5),
    unit: els.unit.value.trim() || 'pcs',
  };

  try {
    if (els.productId.value) {
      await apiFetch(`/api/products/${els.productId.value}`, {
        method: 'PUT',
        body: JSON.stringify(payload),
      });
    } else {
      await apiFetch('/api/products', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    }

    resetProductForm();
    loadProducts();
    loadDashboard();
  } catch (error) {
    alert(error.message);
  }
}

async function addToCartByBarcode(barcode) {
  const clean = barcode.trim();
  if (!clean) return;

  try {
    const product = await apiFetch(`/api/products/${encodeURIComponent(clean)}`);
    const existing = state.cart.find((item) => item.id === product.id);

    if (existing) {
      existing.quantity += 1;
    } else {
      state.cart.push({
        id: product.id,
        name: product.name,
        price: Number(product.selling_price),
        quantity: 1,
      });
    }

    renderCart();
    els.barcodeInput.value = '';
  } catch (error) {
    alert(error.message);
  }
}

function renderCart() {
  els.cartTable.innerHTML = '';

  if (!state.cart.length) {
    els.cartTable.innerHTML = '<tr><td colspan="5">Belum ada produk</td></tr>';
    els.cartTotal.textContent = formatCurrency(0);
    return;
  }

  let total = 0;

  state.cart.forEach((item) => {
    const row = document.createElement('tr');
    const subtotal = item.price * item.quantity;
    total += subtotal;

    row.innerHTML = `
      <td>${item.name}</td>
      <td>
        <button class="secondary" data-action="decrease" data-id="${item.id}">-</button>
        ${item.quantity}
        <button class="secondary" data-action="increase" data-id="${item.id}">+</button>
      </td>
      <td>${formatCurrency(item.price)}</td>
      <td>${formatCurrency(subtotal)}</td>
      <td><button class="secondary" data-action="remove" data-id="${item.id}">Hapus</button></td>
    `;
    els.cartTable.appendChild(row);
  });

  els.cartTable.querySelectorAll('button[data-action="increase"]').forEach((button) => {
    button.addEventListener('click', () => {
      const item = state.cart.find((entry) => entry.id === Number(button.dataset.id));
      if (item) item.quantity += 1;
      renderCart();
    });
  });

  els.cartTable.querySelectorAll('button[data-action="decrease"]').forEach((button) => {
    button.addEventListener('click', () => {
      const item = state.cart.find((entry) => entry.id === Number(button.dataset.id));
      if (!item) return;
      if (item.quantity > 1) item.quantity -= 1;
      else state.cart = state.cart.filter((entry) => entry.id !== item.id);
      renderCart();
    });
  });

  els.cartTable.querySelectorAll('button[data-action="remove"]').forEach((button) => {
    button.addEventListener('click', () => {
      const itemId = Number(button.dataset.id);
      state.cart = state.cart.filter((entry) => entry.id !== itemId);
      renderCart();
    });
  });

  els.cartTotal.textContent = formatCurrency(total);
}

function renderQuickProducts() {
  els.quickProducts.innerHTML = '';
  state.products.slice(0, 8).forEach((product) => {
    const item = document.createElement('div');
    item.className = 'quick-product-item';
    item.innerHTML = `
      <h4>${product.name}</h4>
      <p>${formatCurrency(product.selling_price)}</p>
      <button type="button" data-id="${product.id}">Tambah</button>
    `;
    item.querySelector('button').addEventListener('click', () => {
      const productEntry = state.products.find((entry) => entry.id === Number(product.id));
      if (!productEntry) return;
      const existing = state.cart.find((entry) => entry.id === productEntry.id);
      if (existing) existing.quantity += 1;
      else state.cart.push({ id: productEntry.id, name: productEntry.name, price: Number(productEntry.selling_price), quantity: 1 });
      renderCart();
    });
    els.quickProducts.appendChild(item);
  });
}

async function checkout() {
  if (!state.cart.length) {
    alert('Keranjang masih kosong');
    return;
  }

  try {
    const payload = {
      customerName: els.customerName.value.trim() || 'Umum',
      paymentType: els.paymentType.value,
      cashierId: state.user.id,
      items: state.cart.map((item) => ({ productId: item.id, quantity: item.quantity })),
    };

    const result = await apiFetch('/api/transactions', {
      method: 'POST',
      body: JSON.stringify(payload),
    });

    state.cart = [];
    renderCart();
    alert(`Transaksi ${result.transaction.transaction_code} berhasil disimpan`);
    printReceipt(result.transaction.id);
    loadDashboard();
    loadReports();
    loadProducts();
  } catch (error) {
    alert(error.message);
  }
}

function printReceipt(transactionId) {
  const win = window.open('', '_blank');
  const title = 'Struk Penjualan';
  const content = `
    <html>
      <head>
        <title>${title}</title>
        <style>
          body { font-family: Arial; width: 300px; margin: 20px auto; }
          h2 { text-align: center; }
          .line { border-bottom: 1px dashed #333; margin: 10px 0; }
          .row { display: flex; justify-content: space-between; margin: 4px 0; }
          .total { font-weight: bold; }
        </style>
      </head>
      <body>
        <h2>BUMDes Kasir</h2>
        <div class="line"></div>
        <div class="row"><span>Customer</span><span>${els.customerName.value || 'Umum'}</span></div>
        <div class="row"><span>Metode</span><span>${els.paymentType.value}</span></div>
        ${state.cart.map((item) => `<div class="row"><span>${item.name} x${item.quantity}</span><span>${formatCurrency(item.price * item.quantity)}</span></div>`).join('')}
        <div class="line"></div>
        <div class="row total"><span>Total</span><span>${formatCurrency(state.cart.reduce((sum, item) => sum + item.price * item.quantity, 0))}</span></div>
      </body>
    </html>
  `;

  win.document.write(content);
  win.document.close();
  win.focus();
  win.print();
}

async function loadReports() {
  const from = els.reportFrom.value || '';
  const to = els.reportTo.value || '';

  try {
    const url = new URL('/api/reports/summary', window.location.origin);
    if (from) url.searchParams.set('from', from);
    if (to) url.searchParams.set('to', to);

    const data = await apiFetch(url.pathname + url.search);
    const summary = data.summary || {};

    els.reportSales.textContent = formatCurrency(summary.total_sales || 0);
    els.reportProfit.textContent = formatCurrency(summary.total_profit || 0);
    els.reportTransactions.textContent = Number(summary.total_transactions || 0);

    els.reportTableBody.innerHTML = '';
    (data.transactions || []).forEach((item) => {
      const row = document.createElement('tr');
      row.innerHTML = `
        <td>${item.transaction_code}</td>
        <td>${item.customer_name || 'Umum'}</td>
        <td>${formatCurrency(item.total_amount)}</td>
        <td>${formatCurrency(item.total_profit)}</td>
        <td>${new Date(item.created_at).toLocaleString('id-ID')}</td>
        <td><button class="secondary" data-id="${item.id}">Print</button></td>
      `;
      row.querySelector('button').addEventListener('click', () => {
        window.open(`/api/transactions/${item.id}/receipt.pdf`, '_blank');
      });
      els.reportTableBody.appendChild(row);
    });
  } catch (error) {
    console.error(error);
  }
}

async function loadUsers() {
  if (!state.user || state.user.role !== 'admin') return;

  try {
    const users = await apiFetch('/api/users');
    state.users = users;
    els.userTableBody.innerHTML = '';
    users.forEach((user) => {
      const row = document.createElement('tr');
      row.innerHTML = `
        <td>${user.username}</td>
        <td>${user.role}</td>
        <td>${new Date(user.created_at).toLocaleString('id-ID')}</td>
        <td>
          <button class="secondary" data-action="edit-user" data-id="${user.id}">Edit</button>
        </td>
      `;
      els.userTableBody.appendChild(row);
    });

    els.userTableBody.querySelectorAll('button[data-action="edit-user"]').forEach((button) => {
      button.addEventListener('click', () => {
        const user = users.find((entry) => entry.id === Number(button.dataset.id));
        if (user) {
          els.userId.value = user.id;
          els.userUsername.value = user.username;
          els.userRole.value = user.role;
          els.userPassword.value = '';
        }
      });
    });
  } catch (error) {
    console.error(error);
  }
}

async function handleUserForm(event) {
  event.preventDefault();
  if (state.user.role !== 'admin') return;

  const username = els.userUsername.value.trim();
  const password = els.userPassword.value;
  const role = els.userRole.value;

  try {
    await apiFetch('/api/users', {
      method: 'POST',
      body: JSON.stringify({ username, password, role }),
    });
    els.userForm.reset();
    els.userRole.value = 'cashier';
    loadUsers();
  } catch (error) {
    alert(error.message);
  }
}

function setActiveTab(tabName) {
  document.querySelectorAll('.tab-panel').forEach((panel) => {
    panel.classList.toggle('hidden', panel.id !== tabName);
  });

  document.querySelectorAll('.tab-button').forEach((button) => {
    button.classList.toggle('active', button.dataset.tab === tabName);
  });
}

async function toggleScanner() {
  if (!window.Html5Qrcode) {
    alert('Scanner kamera tidak tersedia di browser ini');
    return;
  }

  if (state.scannerEnabled) {
    if (state.scanner) {
      await state.scanner.stop();
    }
    state.scannerEnabled = false;
    els.scannerContainer.classList.add('hidden');
    els.toggleScannerBtn.textContent = 'Aktifkan Kamera Scanner';
    return;
  }

  state.scannerEnabled = true;
  els.scannerContainer.classList.remove('hidden');
  els.toggleScannerBtn.textContent = 'Matikan Kamera Scanner';

  state.scanner = new Html5Qrcode('scannerContainer');

  try {
    await state.scanner.start(
      { facingMode: 'environment' },
      { fps: 10, qrbox: { width: 250, height: 200 } },
      (decodedText) => addToCartByBarcode(decodedText),
      () => {}
    );
  } catch (error) {
    console.error('Scanner error:', error);
    alert('Gagal mengaktifkan kamera scanner');
    state.scannerEnabled = false;
    els.scannerContainer.classList.add('hidden');
    els.toggleScannerBtn.textContent = 'Aktifkan Kamera Scanner';
  }
}

function bindEvents() {
  els.loginForm.addEventListener('submit', login);
  els.logoutBtn.addEventListener('click', logout);
  els.tabButtons.forEach((button) => button.addEventListener('click', () => setActiveTab(button.dataset.tab)));
  els.productSearch.addEventListener('input', loadProducts);
  els.categoryFilter.addEventListener('change', loadProducts);
  els.productForm.addEventListener('submit', handleProductForm);
  els.cancelProductEdit.addEventListener('click', resetProductForm);
  els.addByBarcodeBtn.addEventListener('click', () => addToCartByBarcode(els.barcodeInput.value));
  els.barcodeInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      addToCartByBarcode(els.barcodeInput.value);
    }
  });
  els.checkoutBtn.addEventListener('click', checkout);
  els.applyReportBtn.addEventListener('click', loadReports);
  els.exportPdfBtn.addEventListener('click', () => {
    const from = els.reportFrom.value || '';
    const to = els.reportTo.value || '';
    const url = new URL('/api/reports/export/pdf', window.location.origin);
    if (from) url.searchParams.set('from', from);
    if (to) url.searchParams.set('to', to);
    window.open(url.toString(), '_blank');
  });
  els.exportExcelBtn.addEventListener('click', () => {
    const from = els.reportFrom.value || '';
    const to = els.reportTo.value || '';
    const url = new URL('/api/reports/export/excel', window.location.origin);
    if (from) url.searchParams.set('from', from);
    if (to) url.searchParams.set('to', to);
    window.open(url.toString(), '_blank');
  });
  els.toggleScannerBtn.addEventListener('click', toggleScanner);
  els.userForm.addEventListener('submit', handleUserForm);
  els.cancelUserEdit.addEventListener('click', () => {
    els.userForm.reset();
    els.userRole.value = 'cashier';
  });
}

function initialize() {
  initElements();
  bindEvents();
  resetProductForm();
  renderCart();
  setActiveTab('dashboard');
}

initialize();

const state = {
  token: null,
  user: null,
  products: [],
  cart: [],
  selectedTab: 'dashboard',
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
  els.reportTableBody = document.getElementById('reportTableBody');
  els.topProductsTable = document.getElementById('topProductsTable');
  els.latestTransactionsTable = document.getElementById('latestTransactionsTable');
  els.statSales = document.getElementById('statSales');
  els.statTransactions = document.getElementById('statTransactions');
  els.statProfit = document.getElementById('statProfit');
  els.statItems = document.getElementById('statItems');
  els.reportSales = document.getElementById('reportSales');
  els.reportProfit = document.getElementById('reportProfit');
  els.reportTransactions = document.getElementById('reportTransactions');
}

function formatCurrency(value) {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(Number(value || 0));
}

function setMessage(element, text, type = 'error') {
  element.textContent = text;
  element.classList.toggle('hidden', !text);
  element.classList.toggle('error', type === 'error');
}

async function apiFetch(path, options = {}) {
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  const response = await fetch(path, {
    ...options,
    headers,
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(data.message || 'Request failed');
  }

  return data;
}

async function handleLogin(event) {
  event.preventDefault();

  const username = els.username.value.trim();
  const password = els.password.value;

  try {
    const result = await apiFetch('/api/login', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    });

    state.token = result.token;
    state.user = result.user;
    els.cashierName.textContent = result.user.username;
    setMessage(els.loginError, '', 'error');
    els.loginView.classList.add('hidden');
    els.appView.classList.remove('hidden');
    loadProducts();
    loadDashboard();
    loadReports();
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

async function loadProducts() {
  const search = els.productSearch.value.trim();
  const category = els.categoryFilter.value;

  try {
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
  const currentValue = els.categoryFilter.value;
  els.categoryFilter.innerHTML = '<option value="">Semua kategori</option>';

  categories.forEach((category) => {
    const option = document.createElement('option');
    option.value = category;
    option.textContent = category;
    if (category === currentValue) option.selected = true;
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
      <td>
        <button class="secondary" data-action="edit" data-id="${product.id}">Edit</button>
        <button class="secondary" data-action="delete" data-id="${product.id}">Hapus</button>
      </td>
    `;
    els.productTableBody.appendChild(row);
  });

  els.productTableBody.querySelectorAll('button[data-action="edit"]').forEach((button) => {
    button.addEventListener('click', async () => {
      const product = state.products.find((item) => item.id === Number(button.dataset.id));
      fillProductForm(product);
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
  els.unit.value = product.unit;
  els.barcode.focus();
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
  } catch (error) {
    alert(error.message);
  }
}

function resetProductForm() {
  els.productForm.reset();
  els.productId.value = '';
  els.category.value = 'Umum';
  els.unit.value = 'pcs';
}

async function addToCartByBarcode(barcode) {
  const cleanBarcode = barcode.trim();

  if (!cleanBarcode) return;

  try {
    const product = await apiFetch(`/api/products/${encodeURIComponent(cleanBarcode)}`);

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
      item.quantity += 1;
      renderCart();
    });
  });

  els.cartTable.querySelectorAll('button[data-action="decrease"]').forEach((button) => {
    button.addEventListener('click', () => {
      const item = state.cart.find((entry) => entry.id === Number(button.dataset.id));
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

  const payload = {
    customerName: els.customerName.value.trim() || 'Umum',
    paymentType: els.paymentType.value,
    cashierId: state.user.id,
    items: state.cart.map((item) => ({
      productId: item.id,
      quantity: item.quantity,
    })),
  };

  try {
    const result = await apiFetch('/api/transactions', {
      method: 'POST',
      body: JSON.stringify(payload),
    });

    alert(`Transaksi ${result.transaction.transaction_code} berhasil disimpan`);
    state.cart = [];
    renderCart();
    loadDashboard();
    loadReports();
    loadProducts();
  } catch (error) {
    alert(error.message);
  }
}

async function loadDashboard() {
  try {
    const report = await apiFetch('/api/reports/summary');
    const summary = report.summary || {};

    els.statSales.textContent = formatCurrency(summary.total_sales || 0);
    els.statTransactions.textContent = Number(summary.total_transactions || 0);
    els.statProfit.textContent = formatCurrency(summary.total_profit || 0);
    els.statItems.textContent = Number(summary.total_items || 0);

    const transactions = report.transactions || [];
    els.latestTransactionsTable.innerHTML = '';

    transactions.slice(0, 5).forEach((item) => {
      const row = document.createElement('tr');
      row.innerHTML = `
        <td>${item.transaction_code}</td>
        <td>${formatCurrency(item.total_amount)}</td>
        <td>${new Date(item.created_at).toLocaleString('id-ID')}</td>
      `;
      els.latestTransactionsTable.appendChild(row);
    });

    const soldMap = {};
    transactions.forEach((tx) => {
      // no item details; keep summary only if not available
    });

    els.topProductsTable.innerHTML = '<tr><td colspan="2">Belum ada data</td></tr>';
  } catch (error) {
    console.error(error);
  }
}

async function loadReports() {
  const from = els.reportFrom.value || '';
  const to = els.reportTo.value || '';

  try {
    const url = new URL('/api/reports/summary', window.location.origin);
    if (from) url.searchParams.set('from', from);
    if (to) url.searchParams.set('to', to);

    const report = await apiFetch(url.pathname + url.search);
    const summary = report.summary || {};

    els.reportSales.textContent = formatCurrency(summary.total_sales || 0);
    els.reportProfit.textContent = formatCurrency(summary.total_profit || 0);
    els.reportTransactions.textContent = Number(summary.total_transactions || 0);

    els.reportTableBody.innerHTML = '';
    (report.transactions || []).forEach((item) => {
      const row = document.createElement('tr');
      row.innerHTML = `
        <td>${item.transaction_code}</td>
        <td>${item.customer_name || 'Umum'}</td>
        <td>${formatCurrency(item.total_amount)}</td>
        <td>${formatCurrency(item.total_profit)}</td>
        <td>${new Date(item.created_at).toLocaleString('id-ID')}</td>
      `;
      els.reportTableBody.appendChild(row);
    });
  } catch (error) {
    console.error(error);
  }
}

function setActiveTab(tabName) {
  state.selectedTab = tabName;
  document.querySelectorAll('.tab-panel').forEach((panel) => {
    panel.classList.toggle('hidden', panel.id !== tabName);
  });

  document.querySelectorAll('.tab-button').forEach((button) => {
    button.classList.toggle('active', button.dataset.tab === tabName);
  });
}

function attachEvents() {
  els.loginForm.addEventListener('submit', handleLogin);
  els.logoutBtn.addEventListener('click', logout);
  els.tabButtons.forEach((button) => {
    button.addEventListener('click', () => setActiveTab(button.dataset.tab));
  });
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
  els.toggleScannerBtn.addEventListener('click', toggleScanner);
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
      (decodedText) => {
        addToCartByBarcode(decodedText);
      },
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

function initialize() {
  initElements();
  attachEvents();
  resetProductForm();
  els.productSearch.value = '';
  els.reportFrom.value = '';
  els.reportTo.value = '';
  setActiveTab('dashboard');
}

initialize();

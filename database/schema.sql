const state = {
  token: null,
  user: null,
  products: [],
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
  els.usersTabButton = document.getElementById('usersTabButton');

  els.productSearch = document.getElementById('productSearch');
  els.categoryFilter = document.getElementById('categoryFilter');
  els.productForm = document.getElementById('productForm');
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
  els.productTableBody = document.getElementById('productTableBody');

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
  els.reportSales = document.getElementById('reportSales');
  els.reportProfit = document.getElementById('reportProfit');
  els.reportTransactions = document.getElementById('reportTransactions');
  els.reportTableBody = document.getElementById('reportTableBody');
  els.dailyReportTable = document.getElementById('dailyReportTable');
  els.monthlyReportTable = document.getElementById('monthlyReportTable');
  els.productSalesTable = document.getElementById('productSalesTable');
  els.cashierPerformanceTable = document.getElementById('cashierPerformanceTable');
  els.statSales = document.getElementById('statSales');
  els.statTransactions = document.getElementById('statTransactions');
  els.statProfit = document.getElementById('statProfit');
  els.statLowStock = document.getElementById('statLowStock');
  els.lowStockTable = document.getElementById('lowStockTable');
  els.latestTransactionsTable = document.getElementById('latestTransactionsTable');

  els.userForm = document.getElementById('userForm');
  els.userUsername = document.getElementById('userUsername');
  els.userPassword = document.getElementById('userPassword');
  els.userRole = document.getElementById('userRole');
  els.cancelUserEdit = document.getElementById('cancelUserEdit');
  els.userTableBody = document.getElementById('userTableBody');
}

function formatCurrency(value) {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(Number(value || 0));
}

function setMessage(element, text, error = true) {
  element.textContent = text || '';
  element.classList.toggle('hidden', !text);
  element.classList.toggle('error', error);
}

function getAuthHeaders() {
  return state.token ? { Authorization: `Bearer ${state.token}` } : {};
}

async function apiFetch(path, options = {}) {
  const response = await fetch(path, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...getAuthHeaders(),
      ...(options.headers || {}),
    },
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(data.message || 'Request failed');
  }

  return data;
}

function renderAccessControl() {
  const role = state.user?.role;
  const canManageUsers = role === 'admin';
  const canManageProducts = ['admin', 'operator'].includes(role);
  const canUseSales = ['admin', 'cashier', 'operator'].includes(role);

  els.usersTabButton.style.display = canManageUsers ? 'inline-flex' : 'none';
  document.querySelectorAll('.tab-button').forEach((button) => {
    if (button.dataset.tab === 'products' && !canManageProducts) button.style.display = 'none';
    if (button.dataset.tab === 'sales' && !canUseSales) button.style.display = 'none';
  });
}

async function handleLogin(event) {
  event.preventDefault();

  try {
    const result = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: els.username.value.trim(),
        password: els.password.value,
      }),
    }).then(async (res) => {
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Login gagal');
      return data;
    });

    state.token = result.token;
    state.user = result.user;
    els.cashierName.textContent = result.user.username;
    els.loginView.classList.add('hidden');
    els.appView.classList.remove('hidden');
    setMessage(els.loginError, '', true);
    renderAccessControl();
    loadDashboard();
    loadProducts();
    loadReports();
    loadUsers();
  } catch (error) {
    setMessage(els.loginError, error.message, true);
  }
}

function logout() {
  state.token = null;
  state.user = null;
  state.cart = [];
  renderCart();
  els.loginView.classList.remove('hidden');
  els.appView.classList.add('hidden');
  setMessage(els.loginError, '', true);
  els.username.value = 'admin';
  els.password.value = 'admin123';
}

async function loadDashboard() {
  try {
    const summaryRes = await apiFetch('/api/reports/summary');
    const summary = summaryRes.summary || {};

    els.statSales.textContent = formatCurrency(summary.total_sales || 0);
    els.statTransactions.textContent = Number(summary.total_transactions || 0);
    els.statProfit.textContent = formatCurrency(summary.total_profit || 0);

    const lowStockRes = await apiFetch('/api/products/low-stock');
    els.statLowStock.textContent = Array.isArray(lowStockRes) ? lowStockRes.length : 0;
    els.lowStockTable.innerHTML = '';

    if (lowStockRes.length) {
      lowStockRes.slice(0, 6).forEach((item) => {
        const row = document.createElement('tr');
        row.innerHTML = `
          <td>${item.name}</td>
          <td>${item.stock}</td>
          <td>${item.min_stock}</td>
        `;
        els.lowStockTable.appendChild(row);
      });
    } else {
      els.lowStockTable.innerHTML = '<tr><td colspan="3">Tidak ada stok minim</td></tr>';
    }

    els.latestTransactionsTable.innerHTML = '';
    const txs = summaryRes.transactions || [];
    txs.slice(0, 5).forEach((tx) => {
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
    const url = `/api/products?search=${encodeURIComponent(search)}&category=${encodeURIComponent(category)}`;
    const products = await apiFetch(url);
    state.products = products;
    renderProductsTable();
    renderQuickProducts();
    renderCategories();
  } catch (error) {
    console.error(error);
  }
}

function renderCategories() {
  const selected = els.categoryFilter.value;
  const categories = [...new Set(state.products.map((p) => p.category).filter(Boolean))];
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
      <td>${product.min_stock}</td>
      <td>
        <button class="ghost-btn" data-action="edit" data-id="${product.id}">Edit</button>
        <button class="ghost-btn" data-action="delete" data-id="${product.id}">Hapus</button>
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
      if (!confirm('Hapus produk ini?')) return;
      try {
        await apiFetch(`/api/products/${button.dataset.id}`, { method: 'DELETE' });
        loadProducts();
      } catch (error) {
        alert(error.message);
      }
    });
  });
}

function fillProductForm(product) {
  els.productId.value = product.id;
  els.barcode.value = product.barcode;
  els.sku.value = product.sku || '';
  els.name.value = product.name;
  els.category.value = product.category || 'Umum';
  els.purchasePrice.value = product.purchase_price;
  els.sellingPrice.value = product.selling_price;
  els.stock.value = product.stock;
  els.minStock.value = product.min_stock || 5;
  els.unit.value = product.unit || 'pcs';
  els.barcode.focus();
}

function resetProductForm() {
  els.productForm.reset();
  els.productId.value = '';
  els.category.value = 'Umum';
  els.unit.value = 'pcs';
  els.minStock.value = 5;
}

async function handleProductSubmit(event) {
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
    const subtotal = item.price * item.quantity;
    total += subtotal;

    const row = document.createElement('tr');
    row.innerHTML = `
      <td>${item.name}</td>
      <td>
        <button class="ghost-btn" data-action="decrease" data-id="${item.id}">-</button>
        ${item.quantity}
        <button class="ghost-btn" data-action="increase" data-id="${item.id}">+</button>
      </td>
      <td>${formatCurrency(item.price)}</td>
      <td>${formatCurrency(subtotal)}</td>
      <td><button class="ghost-btn" data-action="remove" data-id="${item.id}">Hapus</button></td>
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
      if (item.quantity > 1) {
        item.quantity -= 1;
      } else {
        state.cart = state.cart.filter((entry) => entry.id !== item.id);
      }
      renderCart();
    });
  });

  els.cartTable.querySelectorAll('button[data-action="remove"]').forEach((button) => {
    button.addEventListener('click', () => {
      const id = Number(button.dataset.id);
      state.cart = state.cart.filter((item) => item.id !== id);
      renderCart();
    });
  });

  els.cartTotal.textContent = formatCurrency(total);
}

function renderQuickProducts() {
  els.quickProducts.innerHTML = '';

  state.products.slice(0, 8).forEach((product) => {
    const item = document.createElement('div');
    item.className = 'quick-item';
    item.innerHTML = `
      <h4>${product.name}</h4>
      <p>${formatCurrency(product.selling_price)}</p>
      <button type="button" data-id="${product.id}">Tambah</button>
    `;
    item.querySelector('button').addEventListener('click', () => {
      const target = state.products.find((entry) => entry.id === Number(product.id));
      if (!target) return;
      const existing = state.cart.find((entry) => entry.id === target.id);
      if (existing) existing.quantity += 1;
      else state.cart.push({ id: target.id, name: target.name, price: Number(target.selling_price), quantity: 1 });
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

    alert(`Transaksi ${result.transaction.transaction_code} berhasil disimpan.`);
    const transactionId = result.transaction.id;
    state.cart = [];
    renderCart();
    loadDashboard();
    loadReports();
    loadProducts();
    printReceipt(transactionId);
  } catch (error) {
    alert(error.message);
  }
}

function printReceipt(transactionId) {
  const printWindow = window.open(`/api/transactions/${transactionId}/receipt.pdf`, '_blank');
  if (!printWindow) {
    alert('Popup diblokir. Izinkan popup untuk print struk.');
  }
}

async function loadReports() {
  try {
    const from = els.reportFrom.value;
    const to = els.reportTo.value;

    const summaryURL = new URL('/api/reports/summary', window.location.origin);
    if (from) summaryURL.searchParams.set('from', from);
    if (to) summaryURL.searchParams.set('to', to);

    const summaryRes = await apiFetch(summaryURL.pathname + summaryURL.search);
    const summary = summaryRes.summary || {};

    els.reportSales.textContent = formatCurrency(summary.total_sales || 0);
    els.reportProfit.textContent = formatCurrency(summary.total_profit || 0);
    els.reportTransactions.textContent = Number(summary.total_transactions || 0);

    els.reportTableBody.innerHTML = '';
    (summaryRes.transactions || []).forEach((row) => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${row.transaction_code}</td>
        <td>${row.customer_name || 'Umum'}</td>
        <td>${formatCurrency(row.total_amount)}</td>
        <td>${formatCurrency(row.total_profit)}</td>
        <td>${new Date(row.created_at).toLocaleString('id-ID')}</td>
        <td><button class="ghost-btn" data-id="${row.id}">Print</button></td>
      `;
      tr.querySelector('button').addEventListener('click', () => printReceipt(row.id));
      els.reportTableBody.appendChild(tr);
    });

    const dailyUrl = new URL('/api/reports/daily', window.location.origin);
    if (from) dailyUrl.searchParams.set('from', from);
    if (to) dailyUrl.searchParams.set('to', to);
    const dailyRows = await apiFetch(dailyUrl.pathname + dailyUrl.search);
    els.dailyReportTable.innerHTML = '';
    if (dailyRows.length) {
      dailyRows.forEach((row) => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>${row.date}</td>
          <td>${row.total_transactions}</td>
          <td>${formatCurrency(row.total_sales)}</td>
          <td>${formatCurrency(row.total_profit)}</td>
        `;
        els.dailyReportTable.appendChild(tr);
      });
    } else {
      els.dailyReportTable.innerHTML = '<tr><td colspan="4">Tidak ada data</td></tr>';
    }

    const monthlyUrl = new URL('/api/reports/monthly', window.location.origin);
    monthlyUrl.searchParams.set('year', new Date().getFullYear());
    const monthlyRows = await apiFetch(monthlyUrl.pathname + monthlyUrl.search);
    els.monthlyReportTable.innerHTML = '';
    if (monthlyRows.length) {
      monthlyRows.forEach((row) => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>${row.month}</td>
          <td>${row.total_transactions}</td>
          <td>${formatCurrency(row.total_sales)}</td>
          <td>${formatCurrency(row.total_profit)}</td>
        `;
        els.monthlyReportTable.appendChild(tr);
      });
    } else {
      els.monthlyReportTable.innerHTML = '<tr><td colspan="4">Tidak ada data</td></tr>';
    }

    const productUrl = new URL('/api/reports/product-sales', window.location.origin);
    if (from) productUrl.searchParams.set('from', from);
    if (to) productUrl.searchParams.set('to', to);
    const productRows = await apiFetch(productUrl.pathname + productUrl.search);
    els.productSalesTable.innerHTML = '';
    if (productRows.length) {
      productRows.slice(0, 10).forEach((row) => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>${row.product_name}</td>
          <td>${row.category || 'Umum'}</td>
          <td>${row.total_quantity}</td>
          <td>${formatCurrency(row.total_sales)}</td>
        `;
        els.productSalesTable.appendChild(tr);
      });
    } else {
      els.productSalesTable.innerHTML = '<tr><td colspan="4">Tidak ada data</td></tr>';
    }

    const perfUrl = new URL('/api/reports/cashier-performance', window.location.origin);
    if (from) perfUrl.searchParams.set('from', from);
    if (to) perfUrl.searchParams.set('to', to);
    const perfRows = await apiFetch(perfUrl.pathname + perfUrl.search);
    els.cashierPerformanceTable.innerHTML = '';
    if (perfRows.length) {
      perfRows.forEach((row) => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>${row.username || '-'}</td>
          <td>${row.role || '-'}</td>
          <td>${row.transaction_count || 0}</td>
          <td>${formatCurrency(row.total_sales || 0)}</td>
        `;
        els.cashierPerformanceTable.appendChild(tr);
      });
    } else {
      els.cashierPerformanceTable.innerHTML = '<tr><td colspan="4">Tidak ada data</td></tr>';
    }
  } catch (error) {
    console.error(error);
  }
}

async function loadUsers() {
  if (state.user?.role !== 'admin') return;
  try {
    const users = await apiFetch('/api/users');
    els.userTableBody.innerHTML = '';
    users.forEach((user) => {
      const row = document.createElement('tr');
      row.innerHTML = `
        <td>${user.username}</td>
        <td>${user.role}</td>
        <td>${new Date(user.created_at).toLocaleString('id-ID')}</td>
      `;
      els.userTableBody.appendChild(row);
    });
  } catch (error) {
    console.error(error);
  }
}

async function handleUserSubmit(event) {
  event.preventDefault();
  if (state.user?.role !== 'admin') return;

  try {
    await apiFetch('/api/users', {
      method: 'POST',
      body: JSON.stringify({
        username: els.userUsername.value.trim(),
        password: els.userPassword.value,
        role: els.userRole.value,
      }),
    });

    els.userForm.reset();
    els.userRole.value = 'cashier';
    loadUsers();
  } catch (error) {
    alert(error.message);
  }
}

async function toggleScanner() {
  if (!window.Html5Qrcode) {
    alert('Scanner kamera tidak tersedia di browser ini');
    return;
  }

  if (state.scannerEnabled) {
    if (state.scanner) {
      try { await state.scanner.stop(); } catch (e) {}
    }
    state.scannerEnabled = false;
    els.scannerContainer.classList.add('hidden');
    els.toggleScannerBtn.textContent = 'Aktifkan Kamera Scanner';
    return;
  }

  try {
    state.scannerEnabled = true;
    els.scannerContainer.classList.remove('hidden');
    els.toggleScannerBtn.textContent = 'Matikan Kamera Scanner';

    state.scanner = new Html5Qrcode('scannerContainer');
    await state.scanner.start(
      { facingMode: 'environment' },
      { fps: 10, qrbox: { width: 250, height: 200 } },
      (decodedText) => addToCartByBarcode(decodedText),
      () => {}
    );
  } catch (error) {
    console.error(error);
    state.scannerEnabled = false;
    els.scannerContainer.classList.add('hidden');
    els.toggleScannerBtn.textContent = 'Aktifkan Kamera Scanner';
    alert('Gagal mengaktifkan kamera scanner');
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

function bindEvents() {
  els.loginForm.addEventListener('submit', handleLogin);
  els.logoutBtn.addEventListener('click', logout);
  els.tabButtons.forEach((button) => button.addEventListener('click', () => setActiveTab(button.dataset.tab)));
  els.categoryFilter.addEventListener('change', loadProducts);
  els.productSearch.addEventListener('input', loadProducts);
  els.productForm.addEventListener('submit', handleProductSubmit);
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
    const url = new URL('/api/reports/export/pdf', window.location.origin);
    if (els.reportFrom.value) url.searchParams.set('from', els.reportFrom.value);
    if (els.reportTo.value) url.searchParams.set('to', els.reportTo.value);
    window.open(url.toString(), '_blank');
  });
  els.exportExcelBtn.addEventListener('click', () => {
    const url = new URL('/api/reports/export/excel', window.location.origin);
    if (els.reportFrom.value) url.searchParams.set('from', els.reportFrom.value);
    if (els.reportTo.value) url.searchParams.set('to', els.reportTo.value);
    window.open(url.toString(), '_blank');
  });
  els.toggleScannerBtn.addEventListener('click', toggleScanner);
  els.userForm.addEventListener('submit', handleUserSubmit);
  els.cancelUserEdit.addEventListener('click', () => {
    els.userForm.reset();
    els.userRole.value = 'cashier';
  });
}

function initialize() {
  initElements();
  bindEvents();
  renderCart();
  resetProductForm();
  setActiveTab('dashboard');
}

initialize();

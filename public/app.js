* {
  box-sizing: border-box;
}

:root {
  --bg: #f4f7fb;
  --panel: #ffffff;
  --panel-alt: #f8fafc;
  --primary: #2563eb;
  --primary-dark: #1d4ed8;
  --secondary: #0f172a;
  --soft-border: #e2e8f0;
  --text: #1e293b;
  --muted: #64748b;
  --danger: #dc2626;
  --warning: #f59e0b;
  --success: #16a34a;
  --shadow: 0 16px 40px rgba(15, 23, 42, 0.08);
}

body {
  margin: 0;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: linear-gradient(135deg, #edf2ff 0%, #f8fafc 100%);
  color: var(--text);
}

button, input, select {
  font: inherit;
}

button {
  cursor: pointer;
}

.hidden {
  display: none !important;
}

.auth-shell {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: radial-gradient(circle at top, rgba(37,99,235,0.18), transparent 35%), linear-gradient(135deg, #0f172a, #1d4ed8);
}

.auth-card {
  width: min(440px, 100%);
  background: rgba(255,255,255,0.95);
  backdrop-filter: blur(10px);
  padding: 30px 28px;
  border-radius: 24px;
  box-shadow: 0 25px 60px rgba(15,23,42,0.25);
}

.brand {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 22px;
}

.brand-icon {
  width: 52px;
  height: 52px;
  border-radius: 16px;
  display: grid;
  place-items: center;
  background: linear-gradient(135deg, var(--primary), #60a5fa);
  color: white;
  font-weight: 800;
  font-size: 1.5rem;
}

.brand h1 {
  margin: 0;
  font-size: 1.9rem;
}

.brand p {
  margin: 4px 0 0;
  color: var(--muted);
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.login-form label {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--text);
}

.login-form input,
.toolbar input,
.toolbar select,
.grid-form input,
.grid-form select,
.field-row input,
.field-row select {
  width: 100%;
  padding: 12px 14px;
  border: 1px solid var(--soft-border);
  border-radius: 12px;
  background: white;
  outline: none;
}

.login-form input:focus,
.toolbar input:focus,
.grid-form input:focus,
.field-row input:focus,
.field-row select:focus {
  border-color: rgba(37,99,235,0.6);
  box-shadow: 0 0 0 3px rgba(37,99,235,0.12);
}

.primary-btn,
.secondary-btn,
.ghost-btn {
  border: none;
  border-radius: 12px;
  padding: 12px 16px;
  font-weight: 700;
  transition: 0.2s ease;
}

.primary-btn {
  background: linear-gradient(135deg, var(--primary), var(--primary-dark));
  color: white;
  box-shadow: 0 10px 18px rgba(37,99,235,0.18);
}

.primary-btn:hover {
  transform: translateY(-1px);
}

.secondary-btn {
  background: #e2e8f0;
  color: var(--secondary);
}

.ghost-btn {
  background: #f1f5f9;
  color: var(--secondary);
}

.message {
  margin-top: 12px;
  border-radius: 10px;
  padding: 10px 12px;
  font-size: 0.92rem;
}

.message.error {
  background: #fee2e2;
  color: #991b1b;
}

.app-shell {
  padding-bottom: 30px;
}

.topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 18px 24px;
  background: linear-gradient(135deg, #0f172a, #1e293b);
  color: white;
  box-shadow: 0 6px 18px rgba(15,23,42,0.12);
}

.brand-mini {
  display: flex;
  align-items: center;
  gap: 12px;
}

.brand-pill {
  display: inline-block;
  padding: 6px 10px;
  background: rgba(255,255,255,0.08);
  border: 1px solid rgba(255,255,255,0.15);
  border-radius: 999px;
  font-size: 0.72rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.brand-mini h2 {
  margin: 0;
  font-size: 1.2rem;
}

.topbar-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.nav-tabs {
  display: flex;
  gap: 12px;
  padding: 16px 24px 0;
  overflow-x: auto;
}

.tab-button {
  background: transparent;
  border: 1px solid transparent;
  border-radius: 12px 12px 0 0;
  padding: 12px 18px;
  color: var(--muted);
  font-weight: 700;
}

.tab-button.active {
  background: var(--panel);
  color: var(--secondary);
  border-color: var(--soft-border);
  border-bottom-color: transparent;
}

.page-content {
  padding: 20px 24px 0;
}

.tab-panel {
  display: block;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 16px;
  margin-bottom: 20px;
}

.stat-card {
  background: var(--panel);
  border: 1px solid var(--soft-border);
  border-radius: 18px;
  box-shadow: var(--shadow);
  padding: 18px 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.stat-card.warning {
  border-color: rgba(245, 158, 11, 0.3);
}

.stat-card span {
  color: var(--muted);
  font-size: 0.84rem;
}

.stat-card strong {
  font-size: clamp(1.1rem, 2vw, 1.6rem);
}

.panel,
.mini-panel {
  background: var(--panel);
  border: 1px solid var(--soft-border);
  border-radius: 18px;
  padding: 18px;
  box-shadow: var(--shadow);
}

.panel h3,
.mini-panel h4 {
  margin-top: 0;
}

.two-cols,
.sales-layout {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 18px;
}

.toolbar,
.button-row,
.field-row {
  display: flex;
  gap: 12px;
  align-items: center;
}

.toolbar {
  flex-wrap: wrap;
  margin-bottom: 18px;
}

.toolbar input,
.toolbar select {
  flex: 1 1 220px;
}

.grid-form {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 12px;
  margin-top: 12px;
}

.table-wrapper {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 12px;
}

th, td {
  padding: 12px 10px;
  border-bottom: 1px solid var(--soft-border);
  text-align: left;
  vertical-align: top;
}

th {
  color: var(--muted);
  font-size: 0.8rem;
  text-transform: uppercase;
}

.scanner {
  border: 1px solid var(--soft-border);
  background: #0f172a;
  min-height: 220px;
  border-radius: 12px;
  overflow: hidden;
  margin: 10px 0 16px;
}

.checkout-box {
  margin-top: 18px;
  display: grid;
  gap: 12px;
}

.field-row {
  display: grid;
  grid-template-columns: 140px 1fr;
}

.checkout-total {
  margin-top: 18px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  flex-wrap: wrap;
}

.checkout-total strong {
  font-size: 1.4rem;
}

.quick-products {
  display: grid;
  gap: 12px;
}

.quick-item {
  padding: 12px;
  border: 1px solid #dbeafe;
  border-radius: 12px;
  background: var(--panel-alt);
}

.quick-item h4,
.quick-item p {
  margin: 0;
}

.quick-item button {
  width: 100%;
  margin-top: 10px;
  background: #dbeafe;
  color: var(--primary-dark);
  border: none;
  border-radius: 10px;
  padding: 10px;
  font-weight: 700;
}

.report-blocks {
  margin-top: 20px;
  display: grid;
  gap: 18px;
}

.mini-panel {
  overflow-x: auto;
}

.small-grid {
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
}

@media (max-width: 720px) {
  .field-row {
    grid-template-columns: 1fr;
  }

  .topbar {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .nav-tabs {
    padding-top: 12px;
  }
}

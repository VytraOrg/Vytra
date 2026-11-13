// ==========================================================================
// Vytra Admin Portal Logic (app.js)
// ==========================================================================

// Smart Local Backend Auto-Detection
const isLocalEnvironment = window.location.hostname === 'localhost' ||
  window.location.hostname === '127.0.0.1' ||
  window.location.protocol === 'file:';

const API_BASE_URL = localStorage.getItem('use_local_backend') === 'false'
  ? 'https://localcommerceapp-1.onrender.com/api/v1'
  : (isLocalEnvironment || localStorage.getItem('use_local_backend') === 'true'
      ? 'http://localhost:5001/api/v1'
      : 'https://localcommerceapp-1.onrender.com/api/v1');

// App State Management
let token = localStorage.getItem('admin_token') || null;
let adminUser = JSON.parse(localStorage.getItem('admin_user')) || null;
let shopsData = [];
let activeTab = 'verifications';
let activeFilter = 'Pending';

// Split Workspace State
let selectedShopId = null;
let activeDocType = 'gst';
let zoomLevel = 1.0;
let rotationAngle = 0;

// Initialize Lucide Icons
function initIcons() {
  if (window.lucide) {
    window.lucide.createIcons();
  }
}

// Show Toast Alert
function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  
  let iconName = 'info';
  if (type === 'success') iconName = 'check-circle2';
  if (type === 'error') iconName = 'alert-circle';
  
  toast.innerHTML = `
    <i data-lucide="${iconName}"></i>
    <span>${message}</span>
  `;
  
  container.appendChild(toast);
  initIcons();
  
  // Slide out and remove toast after 3.5 seconds
  setTimeout(() => {
    toast.style.transform = 'translateX(120%)';
    toast.style.transition = 'all 0.2s cubic-bezier(0.16, 1, 0.3, 1)';
    setTimeout(() => toast.remove(), 250);
  }, 3500);
}

// Authentication Check on Load
document.addEventListener('DOMContentLoaded', () => {
  initIcons();
  checkAuth();
  setupEventListeners();
  setupKeyboardShortcuts();
  setupSidebarCollapse();
  setupProfileDropdown();
  setupPasswordToggle();
  loadRememberedEmail();
});

function checkAuth() {
  const authScreen = document.getElementById('auth-screen');
  const dashboardScreen = document.getElementById('dashboard-screen');
  
  if (token && adminUser && adminUser.role === 'Admin') {
    authScreen.classList.add('hidden');
    dashboardScreen.classList.remove('hidden');
    
    // Set admin profile UI
    document.getElementById('admin-name').textContent = adminUser.name || 'Admin';
    document.getElementById('admin-email').textContent = adminUser.email || 'admin@commerce.com';
    
    // Fetch initial data
    fetchShops();
  } else {
    // Clear storage to be safe
    logout();
    authScreen.classList.remove('hidden');
    dashboardScreen.classList.add('hidden');
  }
}

function logout() {
  localStorage.removeItem('admin_token');
  localStorage.removeItem('admin_user');
  token = null;
  adminUser = null;
  document.getElementById('auth-screen').classList.remove('hidden');
  document.getElementById('dashboard-screen').classList.add('hidden');
}

// Password show/hide toggle
function setupPasswordToggle() {
  const toggleBtn = document.getElementById('toggle-password');
  const passwordInput = document.getElementById('password');
  if (!toggleBtn || !passwordInput) return;

  toggleBtn.addEventListener('click', () => {
    const isHidden = passwordInput.type === 'password';
    passwordInput.type = isHidden ? 'text' : 'password';
    toggleBtn.innerHTML = `<i data-lucide="${isHidden ? 'eye-off' : 'eye'}"></i>`;
    initIcons();
    toggleBtn.title = isHidden ? 'Hide password' : 'Show password';
  });
}

// Pre-fill email if remember-me was checked previously
function loadRememberedEmail() {
  const remembered = localStorage.getItem('admin_remembered_email');
  if (remembered) {
    const emailInput = document.getElementById('email');
    const rememberCheckbox = document.getElementById('remember-me');
    if (emailInput) emailInput.value = remembered;
    if (rememberCheckbox) rememberCheckbox.checked = true;
  }
}

// Keyboard Shortcuts setup
function setupKeyboardShortcuts() {
  document.addEventListener('keydown', (e) => {
    const searchInput = document.getElementById('shop-search');
    if (!searchInput) return;

    // Ctrl + K or Meta + K focuses the search bar
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
      e.preventDefault();
      searchInput.focus();
    }
    
    // Slash (/) key focuses the search bar if not in an input field
    if (e.key === '/' && document.activeElement !== searchInput && document.activeElement.tagName !== 'INPUT') {
      e.preventDefault();
      searchInput.focus();
    }
  });
}

// Sidebar Collapsible state setup
function setupSidebarCollapse() {
  const sidebar = document.getElementById('sidebar');
  const collapseBtn = document.getElementById('sidebar-collapse-btn');
  if (!sidebar || !collapseBtn) return;
  
  // Load saved state
  const isCollapsed = localStorage.getItem('admin_sidebar_collapsed') === 'true';
  if (isCollapsed) {
    sidebar.classList.add('collapsed');
    collapseBtn.innerHTML = '<i data-lucide="chevron-right"></i>';
  }
  
  collapseBtn.addEventListener('click', () => {
    const collapsed = sidebar.classList.toggle('collapsed');
    localStorage.setItem('admin_sidebar_collapsed', collapsed);
    
    // Replace inner HTML to safely update Lucide icon
    collapseBtn.innerHTML = `<i data-lucide="${collapsed ? 'chevron-right' : 'chevron-left'}"></i>`;
    initIcons();
  });
}

// Profile dropdown controls
function setupProfileDropdown() {
  const trigger = document.getElementById('profile-menu-trigger');
  const dropdown = document.getElementById('profile-dropdown');
  if (!trigger || !dropdown) return;
  
  trigger.addEventListener('click', (e) => {
    e.stopPropagation();
    dropdown.classList.toggle('hidden');
  });
  
  document.addEventListener('click', (e) => {
    if (!trigger.contains(e.target) && !dropdown.contains(e.target)) {
      dropdown.classList.add('hidden');
    }
  });
}

// Setup Event Listeners
function setupEventListeners() {
  // Login Form Submission
  const loginForm = document.getElementById('login-form');
  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const loginBtn = document.getElementById('login-btn');
    
    loginBtn.disabled = true;
    loginBtn.innerHTML = '<span>Signing In...</span><div class="spinner-small" style="margin-left:8px;"></div>';
    
    try {
      const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, role: 'Admin' })
      });
      
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.message || 'Authentication failed');
      }
      
      if (data.user.role !== 'Admin') {
        throw new Error('Access denied. Admin role required.');
      }
      
      // Handle remember-me
      const rememberMe = document.getElementById('remember-me');
      if (rememberMe && rememberMe.checked) {
        localStorage.setItem('admin_remembered_email', email);
      } else {
        localStorage.removeItem('admin_remembered_email');
      }

      // Save session credentials
      token = data.access_token;
      adminUser = data.user;
      localStorage.setItem('admin_token', token);
      localStorage.setItem('admin_user', JSON.stringify(adminUser));
      
      showToast('Logged in successfully!', 'success');
      checkAuth();
    } catch (err) {
      showToast(err.message, 'error');
    } finally {
      loginBtn.disabled = false;
      loginBtn.innerHTML = '<span>Sign In</span><i data-lucide="arrow-right"></i>';
      initIcons();
    }
  });

  // Forgot password — show toast (no backend endpoint yet)
  const forgotLink = document.getElementById('forgot-link');
  if (forgotLink) {
    forgotLink.addEventListener('click', (e) => {
      e.preventDefault();
      showToast('Contact your system administrator to reset your password.', 'info');
    });
  }

  // Logout Button (bound inside CheckAuth as well as here)
  const logoutBtn = document.getElementById('logout-btn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', logout);
  }

  // Quick Dev Demo Login Chip
  const demoChip = document.getElementById('demo-login-chip');
  if (demoChip) {
    demoChip.addEventListener('click', () => {
      document.getElementById('email').value = 'admin@commerce.com';
      document.getElementById('password').value = 'admin123';
      showToast('Admin test credentials filled', 'info');
    });
  }

  // Refresh Distributors Button
  const refreshDistBtn = document.getElementById('refresh-distributors-btn');
  if (refreshDistBtn) {
    refreshDistBtn.addEventListener('click', () => {
      loadDistributors();
      showToast('Distributor list refreshed', 'info');
    });
  }

  // Tab Menu Switching
  const menuItems = document.querySelectorAll('.menu-item');
  menuItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      menuItems.forEach(i => i.classList.remove('active'));
      item.classList.add('active');
      
      activeTab = item.getAttribute('data-tab');
      
      const verificationsView = document.getElementById('verifications-view');
      const distributorsView = document.getElementById('distributors-view');

      if (activeTab === 'distributors') {
        if (verificationsView) verificationsView.classList.add('hidden');
        if (distributorsView) distributorsView.classList.remove('hidden');
        loadDistributors();
      } else {
        if (distributorsView) distributorsView.classList.add('hidden');
        if (verificationsView) verificationsView.classList.remove('hidden');
        
        // Update filters/UI based on selected tab
        const filterBtns = document.querySelectorAll('.filter-btn');
        if (activeTab === 'verifications') {
          // Show pending
          filterBtns.forEach(btn => {
            if (btn.getAttribute('data-filter') === 'Pending') btn.click();
          });
        } else {
          // Show all
          filterBtns.forEach(btn => {
            if (btn.getAttribute('data-filter') === 'all') btn.click();
          });
        }
      }
    });
  });

  // Filter Buttons
  const filterBtns = document.querySelectorAll('.filter-btn');
  filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      filterBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeFilter = btn.getAttribute('data-filter');
      renderShops();
    });
  });

  // Search Input Handler & Clear Button logic
  const searchInput = document.getElementById('shop-search');
  const searchClear = document.getElementById('search-clear-btn');
  if (searchInput && searchClear) {
    searchInput.addEventListener('input', () => {
      if (searchInput.value.length > 0) {
        searchClear.classList.remove('hidden');
      } else {
        searchClear.classList.add('hidden');
      }
      renderShops();
    });
    
    searchClear.addEventListener('click', () => {
      searchInput.value = '';
      searchClear.classList.add('hidden');
      searchInput.focus();
      renderShops();
    });
  }

  // Modal Close Button
  document.getElementById('close-modal-btn').addEventListener('click', hideModal);
  
  // Setup Workspace Event Listeners
  setupWorkspaceListeners();
}

// Fetch Shops from API
async function fetchShops() {
  const qList = document.getElementById('queue-list');
  
  try {
    const response = await fetch(`${API_BASE_URL}/shops/admin/all`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      if (response.status === 401) {
        showToast('Session expired. Please log in again.', 'error');
        logout();
        return;
      }
      throw new Error('Failed to fetch shops data');
    }
    
    shopsData = await response.json();
    
    // Smart Defaulting: If there are 0 Pending shops and Verified shops exist,
    // seamlessly switch to 'Verified' so the screen isn't empty on load.
    const pendingCount = shopsData.filter(s => s.verificationStatus === 'Pending').length;
    const verifiedCount = shopsData.filter(s => s.verificationStatus === 'Verified').length;
    
    if (pendingCount === 0 && verifiedCount > 0 && activeFilter === 'Pending') {
      activeFilter = 'Verified';
      const filterBtns = document.querySelectorAll('.queue-panel-card .filter-btn');
      filterBtns.forEach(b => {
        b.classList.toggle('active', b.getAttribute('data-filter') === 'Verified');
      });
    }

    updateMetrics();
    renderAnalytics();
    renderShops();

    // Auto-select the first visible shop so inspector and viewer immediately light up!
    if (!selectedShopId) {
      let visible = shopsData;
      if (activeFilter !== 'all') {
        visible = shopsData.filter(s => s.verificationStatus === activeFilter);
      }
      if (visible.length > 0) {
        selectShop(visible[0]._id);
      }
    }
  } catch (err) {
    showToast(err.message, 'error');
    if (qList) {
      qList.innerHTML = `
        <div class="empty-state">
          <i data-lucide="alert-octagon"></i>
          <p>${err.message}</p>
        </div>
      `;
    }
    initIcons();
  }
}

// Update Dashboard Header metrics with trends and filter counts
function updateMetrics() {
  const pending = shopsData.filter(s => s.verificationStatus === 'Pending').length;
  const verified = shopsData.filter(s => s.verificationStatus === 'Verified').length;
  const rejected = shopsData.filter(s => s.verificationStatus === 'Rejected').length;
  const review = shopsData.filter(s => s.verificationStatus === 'Under Review').length;
  const changes = shopsData.filter(s => s.verificationStatus === 'Changes Requested').length;
  const total = shopsData.length;
  
  document.getElementById('pending-count').textContent = pending;
  document.getElementById('verified-count').textContent = verified;
  document.getElementById('rejected-count').textContent = rejected;
  document.getElementById('total-count').textContent = total;
  
  // Update live badges on filter buttons
  const filterBtns = document.querySelectorAll('.queue-panel-card .filter-btn');
  filterBtns.forEach(btn => {
    const filter = btn.getAttribute('data-filter');
    let count = 0;
    if (filter === 'Pending') count = pending;
    else if (filter === 'Under Review') count = review;
    else if (filter === 'Changes Requested') count = changes;
    else if (filter === 'Verified') count = verified;
    else if (filter === 'Rejected') count = rejected;
    else if (filter === 'all') count = total;
    
    // Set formatted label with badge
    const label = filter === 'Under Review' ? 'Review' : (filter === 'Changes Requested' ? 'Changes' : filter === 'all' ? 'All' : filter);
    btn.innerHTML = `<span>${label}</span> <span class="filter-count-badge">${count}</span>`;
  });

  // Calculate dynamic ratios to show in trend badges
  const verifiedRate = total > 0 ? Math.round((verified / total) * 100) : 0;

  // Rich professional KPI status pills
  const totalTrend = document.getElementById('total-trend');
  if (totalTrend) {
    totalTrend.innerHTML = `<i data-lucide="sparkles"></i> <span class="trend-val">Active Catalog</span>`;
  }

  const pendingTrend = document.getElementById('pending-trend');
  if (pendingTrend) {
    if (pending === 0) {
      pendingTrend.className = 'trend-badge success';
      pendingTrend.innerHTML = `<i data-lucide="check-check"></i> <span class="trend-val">Queue Clear</span>`;
    } else {
      pendingTrend.className = 'trend-badge warning';
      pendingTrend.innerHTML = `<i data-lucide="clock"></i> <span class="trend-val">${pending} Action Required</span>`;
    }
  }

  const verifiedTrend = document.getElementById('verified-trend');
  if (verifiedTrend) {
    verifiedTrend.className = 'trend-badge success';
    verifiedTrend.innerHTML = `<i data-lucide="badge-check"></i> <span class="trend-val">${verifiedRate}% Verified</span>`;
  }

  const rejectedTrend = document.getElementById('rejected-trend');
  if (rejectedTrend) {
    rejectedTrend.className = rejected > 0 ? 'trend-badge danger' : 'trend-badge info';
    rejectedTrend.innerHTML = `<i data-lucide="shield-check"></i> <span class="trend-val">${rejected} Flagged</span>`;
  }

  initIcons();
}

// Render dynamic CSS Analytics widgets with executive density
function renderAnalytics() {
  const total = shopsData.length;
  const statusDist = document.getElementById('status-distribution-bar');
  if (!statusDist) return;

  const pending = shopsData.filter(s => s.verificationStatus === 'Pending').length;
  const verified = shopsData.filter(s => s.verificationStatus === 'Verified').length;
  const rejected = shopsData.filter(s => s.verificationStatus === 'Rejected').length;
  const unverified = total - (pending + verified + rejected);

  const verifiedPct = total > 0 ? Math.round((verified / total) * 100) : 0;
  const pendingPct  = total > 0 ? Math.round((pending  / total) * 100) : 0;
  const rejectedPct = total > 0 ? Math.round((rejected / total) * 100) : 0;
  const unverifiedPct = Math.max(0, 100 - verifiedPct - pendingPct - rejectedPct);

  // Update segments with smooth flex layout
  statusDist.innerHTML = `
    <div class="segment verified" style="width: ${verifiedPct}%" title="Verified (${verified})"></div>
    <div class="segment pending" style="width: ${pendingPct}%" title="Pending (${pending})"></div>
    <div class="segment rejected" style="width: ${rejectedPct}%" title="Rejected (${rejected})"></div>
    <div class="segment unverified" style="width: ${unverifiedPct}%" title="Catalog Unverified (${unverified})"></div>
  `;

  // Update dynamic trend metrics container to eliminate empty void
  const trendContainer = document.querySelector('#verifications-view .analytics-card .analytics-body');
  if (trendContainer) {
    trendContainer.innerHTML = `
      <!-- Executive KPI Micro-strip -->
      <div class="trend-kpi-row">
        <div class="kpi-mini-card">
          <span class="kpi-mini-label">Approval Ratio</span>
          <div class="kpi-mini-val success-val">
            <span>${verifiedPct}%</span>
            <span class="kpi-mini-sub">${verified} of ${total} stores</span>
          </div>
        </div>
        <div class="kpi-mini-card">
          <span class="kpi-mini-label">Queue Health</span>
          <div class="kpi-mini-val ${pending === 0 ? 'success-val' : 'warning-val'}">
            <span class="pulse-dot"></span>
            <span>${pending === 0 ? 'Zero Backlog' : `${pending} Pending`}</span>
          </div>
        </div>
        <div class="kpi-mini-card">
          <span class="kpi-mini-label">Avg. Turnaround</span>
          <div class="kpi-mini-val">
            <span>&lt; 2h</span>
            <span class="kpi-mini-sub">Audit SLA</span>
          </div>
        </div>
      </div>

      <!-- Segmented Stacked Distribution Bar -->
      <div class="distribution-bar" id="status-distribution-bar">
        <div class="segment verified" style="width: ${verifiedPct}%" title="Verified: ${verified}"></div>
        <div class="segment pending" style="width: ${pendingPct}%" title="Pending: ${pending}"></div>
        <div class="segment rejected" style="width: ${rejectedPct}%" title="Rejected: ${rejected}"></div>
        <div class="segment unverified" style="width: ${unverifiedPct}%" title="Other: ${unverified}"></div>
      </div>

      <!-- Rich Status Legend Badges -->
      <div class="distribution-legend">
        <div class="legend-item" onclick="filterByStatus('Verified')" title="Filter by Approved">
          <span class="legend-dot status-verified"></span>
          <span class="legend-label">Approved</span>
          <span class="legend-pill success">${verified} (${verifiedPct}%)</span>
        </div>
        <div class="legend-item" onclick="filterByStatus('Pending')" title="Filter by Pending">
          <span class="legend-dot status-pending"></span>
          <span class="legend-label">Pending</span>
          <span class="legend-pill warning">${pending} (${pendingPct}%)</span>
        </div>
        <div class="legend-item" onclick="filterByStatus('Rejected')" title="Filter by Rejected">
          <span class="legend-dot status-rejected"></span>
          <span class="legend-label">Rejected</span>
          <span class="legend-pill danger">${rejected} (${rejectedPct}%)</span>
        </div>
      </div>

      <!-- Live Notice -->
      <div class="queue-status-banner">
        <i data-lucide="${pending === 0 ? 'check-circle' : 'alert-circle'}" style="width: 14px; height: 14px;"></i>
        <span>${pending === 0 ? 'All pending merchant applications are fully verified.' : `${pending} shop applications waiting for review.`}</span>
      </div>
    `;
  }

  // Update Category distributions
  const categories = {};
  shopsData.forEach(shop => {
    const cat = shop.category || 'General';
    categories[cat] = (categories[cat] || 0) + 1;
  });

  const catList = document.getElementById('category-distribution-list');
  if (catList) {
    const sortedCats = Object.entries(categories).sort((a, b) => b[1] - a[1]);
    
    if (sortedCats.length === 0) {
      catList.innerHTML = `
        <div class="loading-placeholder">
          <span>No category data found</span>
        </div>`;
    } else {
      catList.innerHTML = sortedCats.map(([cat, count], index) => {
        const pct = Math.round((count / total) * 100) || 0;
        const catLower = cat.toLowerCase();
        let barColor = 'linear-gradient(90deg, #c98c52, #e5a96e)';
        let badgeColor = '#c98c52';
        if (catLower.includes('grocery')) {
          barColor = 'linear-gradient(90deg, #10b981, #34d399)';
          badgeColor = '#10b981';
        } else if (catLower.includes('pharmacy')) {
          barColor = 'linear-gradient(90deg, #06b6d4, #38bdf8)';
          badgeColor = '#06b6d4';
        } else if (catLower.includes('electronic')) {
          barColor = 'linear-gradient(90deg, #8b5cf6, #a78bfa)';
          badgeColor = '#8b5cf6';
        } else if (catLower.includes('snack')) {
          barColor = 'linear-gradient(90deg, #f59e0b, #fbbf24)';
          badgeColor = '#f59e0b';
        }
        
        return `
          <div class="category-row">
            <div class="category-row-header">
              <span class="name">
                <span class="category-rank">#${index + 1}</span>
                ${cat}
              </span>
              <span class="count">${count} <span class="pct">(${pct}%)</span></span>
            </div>
            <div class="category-bar-bg">
              <div class="category-bar-fill" style="width: ${pct}%; background: ${barColor}"></div>
            </div>
          </div>
        `;
      }).join('');
    }
  }

  initIcons();
}

// Quick filter helper from legend click
window.filterByStatus = function(status) {
  activeFilter = status;
  const filterBtns = document.querySelectorAll('.queue-panel-card .filter-btn');
  filterBtns.forEach(b => {
    b.classList.toggle('active', b.getAttribute('data-filter') === status);
  });
  renderShops();
};

// Helpers for avatars and category styling
function getCategoryClass(category) {
  const cat = (category || '').toLowerCase();
  if (cat === 'grocery') return 'grocery';
  if (cat === 'pharmacy') return 'pharmacy';
  if (cat === 'electronics') return 'electronics';
  return 'others';
}

function getAvatarGradient(name) {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  const gradients = [
    'linear-gradient(135deg, #c98c52, #845326)',
    'linear-gradient(135deg, #10b981, #065f46)',
    'linear-gradient(135deg, #3b82f6, #1e3a8a)',
    'linear-gradient(135deg, #8b5cf6, #581c87)',
    'linear-gradient(135deg, #f59e0b, #78350f)',
    'linear-gradient(135deg, #06b6d4, #164e63)',
    'linear-gradient(135deg, #ec4899, #831843)'
  ];
  const index = Math.abs(hash % gradients.length);
  return gradients[index];
}

// Render Queue Items (3-column layout)
function renderShops() {
  const qList = document.getElementById('queue-list');
  const searchVal = document.getElementById('shop-search').value.toLowerCase().trim();
  
  // 1. Filter by Status Tab
  let filtered = shopsData;
  if (activeFilter !== 'all') {
    filtered = shopsData.filter(s => s.verificationStatus === activeFilter);
  }
  
  // 2. Filter by Search Query
  if (searchVal) {
    filtered = filtered.filter(s => 
      s.name.toLowerCase().includes(searchVal) ||
      s.category.toLowerCase().includes(searchVal) ||
      (s.owner && s.owner.name.toLowerCase().includes(searchVal)) ||
      (s.owner && s.owner.email.toLowerCase().includes(searchVal))
    );
  }
  
  if (filtered.length === 0) {
    const verifiedTotal = shopsData.filter(s => s.verificationStatus === 'Verified').length;
    qList.innerHTML = `
      <div class="empty-state queue-empty-box">
        <div class="empty-icon-bubble">
          <i data-lucide="${activeFilter === 'Pending' ? 'check-check' : 'inbox'}"></i>
        </div>
        <h4>${activeFilter === 'Pending' ? 'Verification Queue is Clear!' : 'No matching stores'}</h4>
        <p>${activeFilter === 'Pending' 
            ? 'There are currently no new stores awaiting audit. You can review approved merchants or search the catalog.' 
            : 'No stores match the selected filter or search keyword.'}</p>
        <div class="empty-quick-actions">
          ${verifiedTotal > 0 && activeFilter !== 'Verified' ? `
            <button onclick="filterByStatus('Verified')" class="primary-btn empty-cta">
              <i data-lucide="badge-check" style="width:13px;height:13px;"></i> View Verified (${verifiedTotal})
            </button>` : ''
          }
          <button onclick="filterByStatus('all')" class="secondary-btn empty-cta">
            <i data-lucide="layout-grid" style="width:13px;height:13px;"></i> View All (${shopsData.length})
          </button>
        </div>
      </div>
    `;
    initIcons();
    return;
  }
  
  qList.innerHTML = filtered.map(shop => {
    const statusLower = (shop.verificationStatus || 'unverified').toLowerCase();
    const initials = (shop.name || 'S').split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase();
    const avatarGradient = getAvatarGradient(shop.name || '');
    const isActive = shop._id === selectedShopId ? 'active' : '';
    const timeAgo = shop.updatedAt ? new Date(shop.updatedAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : 'Recent';
    const isVerified = shop.verificationStatus === 'Verified';
    
    return `
      <div class="queue-card ${isActive}" onclick="selectShop('${shop._id}')">
        <div class="shop-avatar" style="background: ${avatarGradient}">${initials}</div>
        <div class="queue-card-details">
          <div class="queue-card-title-row">
            <span class="name" title="${shop.name}">
              ${shop.name}
              ${isVerified ? '<i data-lucide="badge-check" class="verified-inline-icon"></i>' : ''}
            </span>
            <span class="queue-card-time">${timeAgo}</span>
          </div>
          <div class="queue-card-sub-row">
            <span class="queue-card-meta">${shop.category || 'Retail'}</span>
            <span class="status-badge ${statusLower}">
              <span class="status-dot"></span>
              ${shop.verificationStatus}
            </span>
          </div>
        </div>
      </div>
    `;
  }).join('');
  
  initIcons();
}

// Select a Shop from the Queue List
window.selectShop = function(shopId) {
  selectedShopId = shopId;
  
  // Highlight active card
  const cards = document.querySelectorAll('.queue-card');
  cards.forEach(card => card.classList.remove('active'));
  
  // Re-render the list to capture current active state easily
  renderShops();

  const shop = shopsData.find(s => s._id === shopId);
  if (!shop) return;

  // Toggle empty states vs workspace containers
  document.getElementById('workspace-empty-state').classList.add('hidden');
  document.getElementById('workspace-details').classList.remove('hidden');
  document.getElementById('viewer-empty-state').classList.add('hidden');
  document.getElementById('viewer-container').classList.remove('hidden');

  // Set Shop Details values
  document.getElementById('ws-shop-name').textContent = shop.name;
  document.getElementById('ws-shop-meta').textContent = `${shop.shopType || 'Local Store'} · ${shop.category}`;
  
  // Update status badge (dashed for CSS matching)
  const statusBadge = document.getElementById('ws-shop-status');
  const statusText = document.getElementById('ws-status-text');
  const badgeClass = (shop.verificationStatus || 'unverified').toLowerCase().replace(/\s+/g, '-');
  statusBadge.className = `status-badge ${badgeClass}`;
  statusText.textContent = shop.verificationStatus || 'Unverified';

  // Set Owner Details values
  document.getElementById('ws-owner-name').textContent = shop.ownerName || (shop.owner ? shop.owner.name : 'Unknown');
  document.getElementById('ws-owner-email').textContent = shop.owner ? shop.owner.email : 'No email';
  document.getElementById('ws-owner-phone').textContent = shop.ownerPhone || '-';
  document.getElementById('ws-shop-desc').textContent = shop.description || '-';

  // Set Location Details values
  document.getElementById('ws-shop-address').textContent = shop.address || '-';
  document.getElementById('ws-shop-district').textContent = shop.district || '-';
  document.getElementById('ws-shop-state').textContent = shop.state || '-';
  document.getElementById('ws-shop-pincode').textContent = shop.pincode || '-';

  const mapLink = document.getElementById('ws-shop-map-link');
  if (shop.location && shop.location.coordinates && shop.location.coordinates.length >= 2) {
    const lng = shop.location.coordinates[0];
    const lat = shop.location.coordinates[1];
    
    // Check if they are valid coordinates (not 0.0)
    if (lat !== 0 && lng !== 0) {
      mapLink.href = `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;
      mapLink.style.display = 'inline-flex';
    } else {
      mapLink.style.display = 'none';
    }
  } else {
    mapLink.style.display = 'none';
  }

  // Set Business Credentials values
  document.getElementById('ws-gst-number').textContent = shop.gstNumber || '-';
  document.getElementById('ws-license-number').textContent = shop.tradeLicenseNumber || '-';

  // Reset Checklist
  document.getElementById('check-name-match').checked = false;
  document.getElementById('check-gst-valid').checked = false;
  document.getElementById('check-address-match').checked = false;
  document.getElementById('check-image-match').checked = false;
  
  // Reset rejection and changes requested panes
  document.getElementById('ws-rejection-pane').classList.add('hidden');
  document.getElementById('ws-changes-pane').classList.add('hidden');
  document.getElementById('ws-actions-panel').classList.remove('hidden');

  // Reset buttons
  updateChecklist();

  // Reset rotation and zoom
  zoomLevel = 1.0;
  rotationAngle = 0;

  // Load document (default to GST)
  loadDocument('gst');
};

// Load GST or Trade License into right panel viewport
window.loadDocument = function(type) {
  activeDocType = type;
  
  const gstBtn = document.getElementById('tab-gst-btn');
  const licBtn = document.getElementById('tab-license-btn');
  const imgBtn = document.getElementById('tab-image-btn');
  
  gstBtn.classList.remove('active');
  licBtn.classList.remove('active');
  imgBtn.classList.remove('active');
  
  if (type === 'gst') {
    gstBtn.classList.add('active');
  } else if (type === 'license') {
    licBtn.classList.add('active');
  } else {
    imgBtn.classList.add('active');
  }

  const shop = shopsData.find(s => s._id === selectedShopId);
  if (!shop) return;

  let url;
  if (type === 'gst') {
    url = shop.gstCertificateUrl;
  } else if (type === 'license') {
    url = shop.tradeLicenseUrl;
  } else {
    url = shop.imageUrl;
  }

  const frame = document.getElementById('document-frame');

  if (!url) {
    frame.innerHTML = `
      <div class="loading-placeholder">
        <i data-lucide="slash"></i>
        <span>No document uploaded for this type</span>
      </div>`;
    initIcons();
    return;
  }

  // Check if PDF or Image
  if (url.toLowerCase().endsWith('.pdf') || url.includes('/raw/upload/')) {
    frame.innerHTML = `<iframe src="${url}"></iframe>`;
  } else {
    frame.innerHTML = `<img src="${url}" alt="${type === 'gst' ? 'GST Certificate' : (type === 'license' ? 'Trade License' : 'Shop Photo')}">`;
  }

  // Apply default scale/rotate transform styles
  applyFrameTransform();
};

// Apply zoom and rotation styles to image/iframe
function applyFrameTransform() {
  const frame = document.getElementById('document-frame');
  const imgOrIframe = frame.querySelector('img, iframe');
  if (imgOrIframe) {
    imgOrIframe.style.transform = `scale(${zoomLevel}) rotate(${rotationAngle}deg)`;
    imgOrIframe.style.transition = 'transform 0.2s ease';
  }
}

// Checklist checkboxes validator
window.updateChecklist = function() {
  const nameMatch = document.getElementById('check-name-match').checked;
  const gstValid = document.getElementById('check-gst-valid').checked;
  const addressMatch = document.getElementById('check-address-match').checked;
  const imageMatch = document.getElementById('check-image-match').checked;
  
  const approveBtn = document.getElementById('ws-approve-btn');
  approveBtn.disabled = !(nameMatch && gstValid && addressMatch && imageMatch);
};

// Bind Workspace Listeners
window.setupWorkspaceListeners = function() {
  // Zoom & Rotation Toolbar buttons
  document.getElementById('btn-zoom-in').addEventListener('click', () => {
    if (zoomLevel < 2.5) {
      zoomLevel += 0.15;
      applyFrameTransform();
    }
  });

  document.getElementById('btn-zoom-out').addEventListener('click', () => {
    if (zoomLevel > 0.5) {
      zoomLevel -= 0.15;
      applyFrameTransform();
    }
  });

  document.getElementById('btn-rotate').addEventListener('click', () => {
    rotationAngle = (rotationAngle + 90) % 360;
    applyFrameTransform();
  });

  // Tab switchers
  document.getElementById('tab-gst-btn').addEventListener('click', () => loadDocument('gst'));
  document.getElementById('tab-license-btn').addEventListener('click', () => loadDocument('license'));
  document.getElementById('tab-image-btn').addEventListener('click', () => loadDocument('image'));

  // Checklist checkboxes
  const checkboxes = document.querySelectorAll('.checklist-checkbox');
  checkboxes.forEach(box => {
    box.addEventListener('change', updateChecklist);
  });

  // Action Buttons
  const approveBtn = document.getElementById('ws-approve-btn');
  const rejectBtn = document.getElementById('ws-reject-btn');
  const cancelRejectBtn = document.getElementById('ws-cancel-reject-btn');
  const confirmRejectBtn = document.getElementById('ws-confirm-reject-btn');

  const changesBtn = document.getElementById('ws-changes-btn');
  const cancelChangesBtn = document.getElementById('ws-cancel-changes-btn');
  const confirmChangesBtn = document.getElementById('ws-confirm-changes-btn');

  approveBtn.addEventListener('click', () => {
    if (!selectedShopId) return;
    const shop = shopsData.find(s => s._id === selectedShopId);
    if (shop) confirmVerifyShop(selectedShopId, shop.name, 'Verified');
  });

  rejectBtn.addEventListener('click', () => {
    document.getElementById('ws-rejection-pane').classList.remove('hidden');
    document.getElementById('ws-changes-pane').classList.add('hidden');
    document.getElementById('ws-actions-panel').classList.add('hidden');
    // Clear reject inputs
    document.getElementById('ws-reject-reason-select').selectedIndex = 0;
    document.getElementById('ws-reject-notes-input').value = '';
  });

  cancelRejectBtn.addEventListener('click', () => {
    document.getElementById('ws-rejection-pane').classList.add('hidden');
    document.getElementById('ws-actions-panel').classList.remove('hidden');
  });

  confirmRejectBtn.addEventListener('click', async () => {
    if (!selectedShopId) return;
    const reason = document.getElementById('ws-reject-reason-select').value;
    const notes = document.getElementById('ws-reject-notes-input').value.trim();
    
    // Hide pane and show main buttons
    document.getElementById('ws-rejection-pane').classList.add('hidden');
    document.getElementById('ws-actions-panel').classList.remove('hidden');

    // Call update API
    await updateShopStatus(selectedShopId, 'Rejected', reason, notes);
    
    // Refresh active panel selection or reset
    const shop = shopsData.find(s => s._id === selectedShopId);
    if (shop) {
      selectShop(selectedShopId);
    } else {
      resetWorkspace();
    }
  });

  changesBtn.addEventListener('click', () => {
    document.getElementById('ws-changes-pane').classList.remove('hidden');
    document.getElementById('ws-rejection-pane').classList.add('hidden');
    document.getElementById('ws-actions-panel').classList.add('hidden');
    document.getElementById('ws-changes-notes-input').value = '';
  });

  cancelChangesBtn.addEventListener('click', () => {
    document.getElementById('ws-changes-pane').classList.add('hidden');
    document.getElementById('ws-actions-panel').classList.remove('hidden');
  });

  confirmChangesBtn.addEventListener('click', async () => {
    if (!selectedShopId) return;
    const notes = document.getElementById('ws-changes-notes-input').value.trim();
    
    if (!notes) {
      showToast('Please provide details for the requested changes', 'error');
      return;
    }

    // Hide pane and show main buttons
    document.getElementById('ws-changes-pane').classList.add('hidden');
    document.getElementById('ws-actions-panel').classList.remove('hidden');

    // Call update API
    await updateShopStatus(selectedShopId, 'Changes Requested', undefined, notes);
    
    // Refresh active panel selection or reset
    const shop = shopsData.find(s => s._id === selectedShopId);
    if (shop) {
      selectShop(selectedShopId);
    } else {
      resetWorkspace();
    }
  });
};

function resetWorkspace() {
  selectedShopId = null;
  document.getElementById('workspace-empty-state').classList.remove('hidden');
  document.getElementById('workspace-details').classList.add('hidden');
  document.getElementById('viewer-empty-state').classList.remove('hidden');
  document.getElementById('viewer-container').classList.add('hidden');
}

// Open Document in Modal
window.viewDocument = function(url, title) {
  const modal = document.getElementById('doc-modal');
  const modalTitle = document.getElementById('modal-title');
  const container = document.getElementById('modal-doc-container');
  
  modalTitle.textContent = title;
  
  // Check if PDF or Image
  if (url.toLowerCase().endsWith('.pdf') || url.includes('/raw/upload/')) {
    container.innerHTML = `<iframe src="${url}"></iframe>`;
  } else {
    container.innerHTML = `<img src="${url}" alt="${title}">`;
  }
  
  modal.classList.remove('hidden');
};

function hideModal() {
  const modal = document.getElementById('doc-modal');
  modal.classList.add('hidden');
  document.getElementById('modal-doc-container').innerHTML = '';
}

// Confirmation Dialog before Action
window.confirmVerifyShop = function(id, name, targetStatus) {
  const modal = document.getElementById('confirm-modal');
  const title = document.getElementById('confirm-title');
  const message = document.getElementById('confirm-message');
  const icon = document.getElementById('confirm-icon');
  const rejectContainer = document.getElementById('reject-reason-container');
  
  const isApprove = targetStatus === 'Verified';
  
  title.textContent = isApprove ? 'Approve Verification Request' : 'Reject Verification Request';
  message.textContent = isApprove 
    ? `Are you sure you want to approve "${name}"? They will gain full merchant status immediately.`
    : `Are you sure you want to reject the submission for "${name}"? They will have to re-upload their files.`;
  
  icon.setAttribute('data-lucide', isApprove ? 'check-circle' : 'alert-triangle');
  icon.style.color = isApprove ? 'var(--success)' : 'var(--danger)';
  
  if (isApprove) {
    rejectContainer.classList.add('hidden');
  } else {
    rejectContainer.classList.remove('hidden');
    // Reset inputs
    document.getElementById('reject-reason-select').selectedIndex = 0;
    document.getElementById('reject-notes-input').value = '';
  }
  
  modal.classList.remove('hidden');
  initIcons();
  
  // Set up button listeners dynamically
  const cancelBtn = document.getElementById('confirm-cancel-btn');
  const okBtn = document.getElementById('confirm-ok-btn');
  
  const onCancel = () => {
    modal.classList.add('hidden');
    removeListeners();
  };
  
  const onConfirm = async () => {
    modal.classList.add('hidden');
    removeListeners();
    
    let reason = undefined;
    let notes = undefined;
    if (!isApprove) {
      reason = document.getElementById('reject-reason-select').value;
      notes = document.getElementById('reject-notes-input').value.trim();
    }
    
    await updateShopStatus(id, targetStatus, reason, notes);
  };
  
  function removeListeners() {
    cancelBtn.removeEventListener('click', onCancel);
    okBtn.removeEventListener('click', onConfirm);
  }
  
  cancelBtn.addEventListener('click', onCancel);
  okBtn.addEventListener('click', onConfirm);
};

// API Call to Update Shop Status
async function updateShopStatus(id, status, reason, notes) {
  try {
    const payload = { status };
    if (reason) payload.reason = reason;
    if (notes) payload.notes = notes;

    const response = await fetch(`${API_BASE_URL}/shops/admin/${id}/verify`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });
    
    const data = await response.json();
    
    if (!response.ok) {
      throw new Error(data.message || 'Failed to update shop status');
    }
    
    showToast(`Shop status updated to ${status} successfully!`, 'success');
    
    // Refresh list locally
    await fetchShops();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// Safe HTML string escaper
function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

// Wholesale Distributors Loader & Renderer
async function loadDistributors() {
  const container = document.getElementById('distributors-list');
  if (!container) return;

  container.innerHTML = `
    <div class="loading-state">
      <div class="spinner"></div>
      <span>Loading wholesale distributors...</span>
    </div>
  `;

  try {
    const res = await fetch(`${API_BASE_URL}/distributors/public/all`);
    if (!res.ok) throw new Error('Failed to fetch distributors');
    const distributors = await res.json();

    // Update metric counters
    const total = distributors.length;
    const openCount = distributors.filter(d => d.status === 'open' || d.isOpen).length;
    const updatingCount = distributors.filter(d => d.status === 'updating').length;

    const totalEl = document.getElementById('dist-total-count');
    const openEl = document.getElementById('dist-open-count');
    const updatingEl = document.getElementById('dist-updating-count');

    if (totalEl) totalEl.textContent = total;
    if (openEl) openEl.textContent = openCount;
    if (updatingEl) updatingEl.textContent = updatingCount;

    if (distributors.length === 0) {
      container.innerHTML = `
        <div class="workspace-empty-state" style="grid-column: 1 / -1; padding: 40px;">
          <i data-lucide="truck"></i>
          <p>No registered wholesale distributors found.</p>
        </div>
      `;
      initIcons();
      return;
    }

    container.innerHTML = distributors.map(d => {
      const statusClass = (d.status || 'open').toLowerCase();
      const statusLabel = d.status ? d.status.toUpperCase() : (d.isOpen ? 'OPEN' : 'CLOSED');
      return `
        <div class="distributor-card">
          <div class="distributor-header">
            <div>
              <h4 class="distributor-title">${escapeHtml(d.name || 'Wholesale Agency')}</h4>
              <p class="distributor-category">${escapeHtml(d.category || 'Wholesale & FMCG')}</p>
            </div>
            <span class="agency-status-badge ${statusClass}">
              <span class="agency-status-dot"></span>
              ${statusLabel}
            </span>
          </div>

          <div class="distributor-meta-row">
            <div class="distributor-meta-item">
              <i data-lucide="user"></i>
              <span><strong>Owner:</strong> ${escapeHtml(d.ownerName || 'Verified Agency Owner')}</span>
            </div>
            <div class="distributor-meta-item">
              <i data-lucide="phone"></i>
              <span><strong>Contact:</strong> +91 ${escapeHtml(d.phone || '9830012345')}</span>
            </div>
            <div class="distributor-meta-item">
              <i data-lucide="map-pin"></i>
              <span><strong>Warehouse:</strong> ${escapeHtml(d.address || 'Central Wholesale Yard')}</span>
            </div>
          </div>
        </div>
      `;
    }).join('');
    initIcons();
  } catch (err) {
    console.error('Distributors fetch error:', err);
    container.innerHTML = `
      <div class="workspace-empty-state" style="grid-column: 1 / -1; padding: 40px;">
        <i data-lucide="alert-triangle"></i>
        <p>Could not connect to distributors API. Ensure local server is running on port 5001.</p>
      </div>
    `;
    initIcons();
  }
}

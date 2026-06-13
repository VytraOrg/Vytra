// ==========================================================================
// LocalCommerce Admin Portal Logic (app.js)
// ==========================================================================

// Base API URL configuration (defaults to live Render server, local fallback via localStorage override)
const API_BASE_URL = localStorage.getItem('use_local_backend') === 'true'
  ? 'http://localhost:5001/api/v1'
  : 'https://localcommerceapp-1.onrender.com/api/v1';

// App State Management
let token = localStorage.getItem('admin_token') || null;
let adminUser = JSON.parse(localStorage.getItem('admin_user')) || null;
let shopsData = [];
let activeTab = 'verifications';
let activeFilter = 'Pending';

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
    collapseBtn.querySelector('i').setAttribute('data-lucide', 'chevron-right');
  }
  
  collapseBtn.addEventListener('click', () => {
    const collapsed = sidebar.classList.toggle('collapsed');
    localStorage.setItem('admin_sidebar_collapsed', collapsed);
    
    const icon = collapseBtn.querySelector('i');
    if (collapsed) {
      icon.setAttribute('data-lucide', 'chevron-right');
    } else {
      icon.setAttribute('data-lucide', 'chevron-left');
    }
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

  // Logout Button (bound inside CheckAuth as well as here)
  const logoutBtn = document.getElementById('logout-btn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', logout);
  }

  // Tab Menu Switching
  const menuItems = document.querySelectorAll('.menu-item');
  menuItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      menuItems.forEach(i => i.classList.remove('active'));
      item.classList.add('active');
      
      activeTab = item.getAttribute('data-tab');
      
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
}

// Fetch Shops from API
async function fetchShops() {
  const tbody = document.getElementById('verification-list');
  
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
    updateMetrics();
    renderAnalytics();
    renderShops();
  } catch (err) {
    showToast(err.message, 'error');
    tbody.innerHTML = `
      <tr>
        <td colspan="7" class="empty-state">
          <i data-lucide="alert-octagon"></i>
          <p>${err.message}</p>
        </td>
      </tr>
    `;
    initIcons();
  }
}

// Update Dashboard Header metrics with trends
function updateMetrics() {
  const pending = shopsData.filter(s => s.verificationStatus === 'Pending').length;
  const verified = shopsData.filter(s => s.verificationStatus === 'Verified').length;
  const rejected = shopsData.filter(s => s.verificationStatus === 'Rejected').length;
  const total = shopsData.length;
  
  document.getElementById('pending-count').textContent = pending;
  document.getElementById('verified-count').textContent = verified;
  document.getElementById('rejected-count').textContent = rejected;
  document.getElementById('total-count').textContent = total;
  
  // Calculate dynamic ratios to show in trend badges
  const verifiedRate = total > 0 ? Math.round((verified / total) * 100) : 0;
  const pendingRate = total > 0 ? Math.round((pending / total) * 100) : 0;
  const rejectedRate = total > 0 ? Math.round((rejected / total) * 100) : 0;

  // Update trend pills content
  document.querySelector('#total-trend .trend-val').textContent = `+12%`;
  document.querySelector('#pending-trend .trend-val').textContent = `${pendingRate}% rate`;
  document.querySelector('#verified-trend .trend-val').textContent = `${verifiedRate}% rate`;
  document.querySelector('#rejected-trend .trend-val').textContent = `${rejectedRate}% rate`;
}

// Render dynamic CSS Analytics widgets
function renderAnalytics() {
  const total = shopsData.length;
  const statusDist = document.getElementById('status-distribution-bar');
  if (!statusDist) return;

  if (total === 0) {
    statusDist.innerHTML = `
      <div style="width:100%;height:100%;background:rgba(255,255,255,0.02);display:flex;align-items:center;justify-content:center;font-size:11px;color:var(--text-muted)">
        No data available
      </div>`;
    return;
  }

  const pending = shopsData.filter(s => s.verificationStatus === 'Pending').length;
  const verified = shopsData.filter(s => s.verificationStatus === 'Verified').length;
  const rejected = shopsData.filter(s => s.verificationStatus === 'Rejected').length;

  const verifiedPct = Math.round((verified / total) * 100) || 0;
  const pendingPct = Math.round((pending / total) * 100) || 0;
  const rejectedPct = total > 0 ? Math.max(0, 100 - verifiedPct - pendingPct) : 0;

  // Update status segments
  const verifiedSeg = statusDist.querySelector('.segment.verified');
  const pendingSeg = statusDist.querySelector('.segment.pending');
  const rejectedSeg = statusDist.querySelector('.segment.rejected');

  if (verifiedSeg) verifiedSeg.style.width = `${verifiedPct}%`;
  if (pendingSeg) pendingSeg.style.width = `${pendingPct}%`;
  if (rejectedSeg) rejectedSeg.style.width = `${rejectedPct}%`;

  // Update legends
  document.getElementById('status-legend-verified').textContent = `${verified} (${verifiedPct}%)`;
  document.getElementById('status-legend-pending').textContent = `${pending} (${pendingPct}%)`;
  document.getElementById('status-legend-rejected').textContent = `${rejected} (${rejectedPct}%)`;

  // Update Category distributions
  const categories = {};
  shopsData.forEach(shop => {
    const cat = shop.category || 'Others';
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
      catList.innerHTML = sortedCats.map(([cat, count]) => {
        const pct = Math.round((count / total) * 100) || 0;
        const catLower = cat.toLowerCase();
        let barColor = 'var(--primary)';
        if (catLower === 'grocery') barColor = '#10b981';
        if (catLower === 'pharmacy') barColor = '#3b82f6';
        if (catLower === 'electronics') barColor = '#6366f1';
        if (catLower === 'others') barColor = 'var(--text-muted)';
        
        return `
          <div class="category-row">
            <div class="category-row-header">
              <span class="name">${cat}</span>
              <span class="count">${count} (${pct}%)</span>
            </div>
            <div class="category-bar-bg">
              <div class="category-bar-fill" style="width: ${pct}%; background-color: ${barColor}"></div>
            </div>
          </div>
        `;
      }).join('');
    }
  }
}

// Helpers for avatars and category styling
function getCategoryClass(category) {
  const cat = (category || '').toLowerCase();
  if (cat === 'grocery') return 'grocery';
  if (cat === 'pharmacy') return 'pharmacy';
  if (cat === 'electronics') return 'electronics';
  return 'others';
}

function getAvatarColor(name) {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  const colors = ['#6366f1', '#10b981', '#3b82f6', '#8b5cf6', '#ec4899', '#f59e0b', '#14b8a6'];
  const index = Math.abs(hash % colors.length);
  return colors[index];
}

// Render Table Items
function renderShops() {
  const tbody = document.getElementById('verification-list');
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
    tbody.innerHTML = `
      <tr>
        <td colspan="7" class="empty-state">
          <i data-lucide="inbox"></i>
          <p>No shops found matching filters.</p>
          ${activeFilter === 'Pending' ? `
            <button onclick="fetchShops()" class="primary-btn empty-cta">
              <i data-lucide="refresh-cw" style="width:12px;height:12px;"></i> Refresh Queue
            </button>` : ''
          }
        </td>
      </tr>
    `;
    initIcons();
    return;
  }
  
  tbody.innerHTML = filtered.map(shop => {
    const ownerName = shop.owner ? shop.owner.name : 'Unknown';
    const ownerEmail = shop.owner ? shop.owner.email : 'No email';
    const gstUrl = shop.gstCertificateUrl || null;
    const licenseUrl = shop.tradeLicenseUrl || null;
    const updatedAt = shop.updatedAt ? new Date(shop.updatedAt).toLocaleDateString() : 'N/A';
    
    // Status style mapping
    const statusLower = (shop.verificationStatus || 'unverified').toLowerCase();
    
    // Avatar styling details
    const initials = (shop.name || 'S').split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase();
    const avatarColor = getAvatarColor(shop.name || '');
    const categoryClass = getCategoryClass(shop.category);
    
    return `
      <tr>
        <td>
          <div class="shop-cell-container">
            <div class="shop-avatar" style="background-color: ${avatarColor}">${initials}</div>
            <div class="shop-info-cell">
              <span class="shop-name">${shop.name}</span>
              <span class="shop-meta">${shop.shopType || 'Local Store'}</span>
            </div>
          </div>
        </td>
        <td>
          <div class="owner-cell">
            <span class="owner-name">${ownerName}</span>
            <span class="owner-email">${ownerEmail}</span>
          </div>
        </td>
        <td>
          <span class="category-badge ${categoryClass}">${shop.category || 'Others'}</span>
        </td>
        <td>
          ${gstUrl 
            ? `<button onclick="viewDocument('${gstUrl}', 'GST Certificate')" class="doc-btn"><i data-lucide="file-text"></i> View GST</button>`
            : '<span class="doc-btn no-doc"><i data-lucide="slash"></i> Empty</span>'
          }
        </td>
        <td>
          ${licenseUrl 
            ? `<button onclick="viewDocument('${licenseUrl}', 'Trade License')" class="doc-btn"><i data-lucide="file-text"></i> View License</button>`
            : '<span class="doc-btn no-doc"><i data-lucide="slash"></i> Empty</span>'
          }
        </td>
        <td>
          <span class="status-badge ${statusLower}">
            <span class="status-dot"></span>
            ${shop.verificationStatus || 'Unverified'}
          </span>
        </td>
        <td>
          <div class="action-group">
            <button onclick="confirmVerifyShop('${shop._id}', '${shop.name}', 'Verified')" 
                    class="action-btn approve" 
                    title="Approve Shop" 
                    ${shop.verificationStatus === 'Verified' ? 'disabled style="opacity: 0.3; cursor: not-allowed;"' : ''}>
              <i data-lucide="check"></i>
            </button>
            <button onclick="confirmVerifyShop('${shop._id}', '${shop.name}', 'Rejected')" 
                    class="action-btn reject" 
                    title="Reject Shop" 
                    ${shop.verificationStatus === 'Rejected' ? 'disabled style="opacity: 0.3; cursor: not-allowed;"' : ''}>
              <i data-lucide="x"></i>
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
  
  initIcons();
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
  
  const isApprove = targetStatus === 'Verified';
  
  title.textContent = isApprove ? 'Approve Verification Request' : 'Reject Verification Request';
  message.textContent = isApprove 
    ? `Are you sure you want to approve "${name}"? They will gain full merchant status immediately.`
    : `Are you sure you want to reject the submission for "${name}"? They will have to re-upload their files.`;
  
  icon.setAttribute('data-lucide', isApprove ? 'check-circle' : 'alert-triangle');
  icon.style.color = isApprove ? 'var(--success)' : 'var(--danger)';
  
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
    await updateShopStatus(id, targetStatus);
  };
  
  function removeListeners() {
    cancelBtn.removeEventListener('click', onCancel);
    okBtn.removeEventListener('click', onConfirm);
  }
  
  cancelBtn.addEventListener('click', onCancel);
  okBtn.addEventListener('click', onConfirm);
};

// API Call to Update Shop Status
async function updateShopStatus(id, status) {
  try {
    const response = await fetch(`${API_BASE_URL}/shops/admin/${id}/verify`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ status })
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

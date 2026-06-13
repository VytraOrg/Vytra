// ==========================================================================
// LocalCommerce Admin Portal Logic (app.js)
// ==========================================================================

// Base API URL configuration (auto-detect localhost vs production)
const API_BASE_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
  ? 'http://localhost:5001/api/v1'
  : 'https://localcommerceapp-1.onrender.com/api/v1';

// App State Management
let token = localStorage.getItem('admin_token') || null;
let adminUser = JSON.parse(localStorage.getItem('admin_user')) || null;
let shopsData = [];
let activeTab = 'verifications';
let activeFilter = 'Pending';
let docModalInstance = null;

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
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// Authentication Check on Load
document.addEventListener('DOMContentLoaded', () => {
  initIcons();
  checkAuth();
  setupEventListeners();
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
    loginBtn.innerHTML = '<span>Signing In...</span><div class="spinner" style="width:18px;height:18px;border-width:2px;margin-left:8px;"></div>';
    
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

  // Logout Button
  document.getElementById('logout-btn').addEventListener('click', logout);

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

  // Search Input Handler
  const searchInput = document.getElementById('shop-search');
  searchInput.addEventListener('input', () => {
    renderShops();
  });

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

// Update Dashboard Header metrics
function updateMetrics() {
  const pending = shopsData.filter(s => s.verificationStatus === 'Pending').length;
  const verified = shopsData.filter(s => s.verificationStatus === 'Verified').length;
  const rejected = shopsData.filter(s => s.verificationStatus === 'Rejected').length;
  const total = shopsData.length;
  
  document.getElementById('pending-count').textContent = pending;
  document.getElementById('verified-count').textContent = verified;
  document.getElementById('rejected-count').textContent = rejected;
  document.getElementById('total-count').textContent = total;
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
    
    return `
      <tr>
        <td>
          <div class="shop-info-cell">
            <span class="shop-name">${shop.name}</span>
            <span class="shop-meta">${shop.category} &bull; ${shop.shopType}</span>
          </div>
        </td>
        <td>
          <div class="owner-cell">
            <span class="owner-name">${ownerName}</span>
            <span class="owner-email">${ownerEmail}</span>
          </div>
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
        <td>${updatedAt}</td>
        <td>
          <span class="status-badge ${statusLower}">
            <span class="status-dot"></span>
            ${shop.verificationStatus || 'Unverified'}
          </span>
        </td>
        <td>
          <div class="action-group">
            ${shop.verificationStatus === 'Pending' ? `
              <button onclick="confirmVerifyShop('${shop._id}', '${shop.name}', 'Verified')" class="action-btn approve" title="Approve Verification">
                <i data-lucide="check"></i>
              </button>
              <button onclick="confirmVerifyShop('${shop._id}', '${shop.name}', 'Rejected')" class="action-btn reject" title="Reject Verification">
                <i data-lucide="x"></i>
              </button>
            ` : `
              <span style="font-size:11px;color:var(--text-muted);font-weight:500;">No actions</span>
            `}
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

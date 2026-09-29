const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const rootDir = path.resolve(__dirname, '..');
const frontendDir = path.join(rootDir, 'frontend');
const pubspecPath = path.join(frontendDir, 'pubspec.yaml');
const releasesDir = path.join(rootDir, 'releases');
const archivesDir = path.join(releasesDir, 'archives');
const historyPath = path.join(releasesDir, 'build_history.json');
const changelogPath = path.join(rootDir, 'CHANGELOG.md');
const dashboardPath = path.join(releasesDir, 'index.html');
const commitsPath = path.join(releasesDir, 'commits.html');
const docsDir = path.join(rootDir, 'docs');
const docsDashboardPath = path.join(docsDir, 'index.html');
const docsCommitsPath = path.join(docsDir, 'commits.html');

// Ensure release and docs directories exist
if (!fs.existsSync(releasesDir)) fs.mkdirSync(releasesDir, { recursive: true });
if (!fs.existsSync(archivesDir)) fs.mkdirSync(archivesDir, { recursive: true });
if (!fs.existsSync(docsDir)) fs.mkdirSync(docsDir, { recursive: true });

function escapeHtml(str) {
  return (str || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function getCommitHistory(limit = 80) {
  try {
    const raw = execSync(
      `git log -n ${limit} --shortstat --pretty=format:"__START__%n%H%n%h%n%an%n%ad%n%s%n__STAT__" --date=format:"%d %b %Y, %I:%M %p"`,
      { cwd: rootDir, encoding: 'utf8' }
    );
    const entries = raw.split('__START__').filter(Boolean);
    return entries.map(entry => {
      const parts = entry.split('__STAT__');
      const metaLines = parts[0].trim().split('\n');
      const statLine = (parts[1] || '').trim();
      const hash = metaLines[0] || '';
      const shortHash = metaLines[1] || '';
      const author = metaLines[2] || 'Developer';
      const date = metaLines[3] || '';
      const subject = metaLines.slice(4).join(' ').trim();

      const filesMatch = statLine.match(/(\d+)\s+file/);
      const insertMatch = statLine.match(/(\d+)\s+insertion/);
      const deleteMatch = statLine.match(/(\d+)\s+deletion/);

      return {
        hash,
        shortHash,
        author,
        date,
        subject,
        files: filesMatch ? filesMatch[1] : '0',
        insertions: insertMatch ? insertMatch[1] : '0',
        deletions: deleteMatch ? deleteMatch[1] : '0',
      };
    }).filter(c => c.hash);
  } catch (e) {
    console.error('Error fetching git commit history:', e.message);
    return [];
  }
}

function getGitInfo() {
  try {
    const commit = execSync('git rev-parse --short HEAD', { cwd: rootDir }).toString().trim();
    const branch = execSync('git rev-parse --abbrev-ref HEAD', { cwd: rootDir }).toString().trim();
    const commitMsg = execSync('git log -1 --pretty=%B', { cwd: rootDir }).toString().trim();
    return { commit, branch, commitMsg };
  } catch (e) {
    return { commit: 'unknown', branch: 'master', commitMsg: 'Development build' };
  }
}

function parsePubspecVersion() {
  const content = fs.readFileSync(pubspecPath, 'utf8');
  const match = content.match(/^version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)/m);
  if (!match) {
    return { major: 1, minor: 0, patch: 0, build: 1 };
  }
  return {
    major: parseInt(match[1]),
    minor: parseInt(match[2]),
    patch: parseInt(match[3]),
    build: parseInt(match[4]),
  };
}

function updatePubspecVersion(newVersionName, newBuildNumber) {
  let content = fs.readFileSync(pubspecPath, 'utf8');
  content = content.replace(/^version:\s*.*$/m, `version: ${newVersionName}+${newBuildNumber}`);
  fs.writeFileSync(pubspecPath, content, 'utf8');
}

function loadHistory() {
  if (fs.existsSync(historyPath)) {
    try {
      return JSON.parse(fs.readFileSync(historyPath, 'utf8'));
    } catch (e) {
      return [];
    }
  }
  return [];
}

function generateDashboardHtml(history) {
  const latest = history[0] || {};
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Vytra - Build & Release Monitor</title>
  <link rel="icon" type="image/png" href="logo.png">
  <link rel="apple-touch-icon" href="logo.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary: #38240D;
      --primary-light: #F5EBE0;
      --accent: #D4A373;
      --bg: #FAF7F2;
      --card-bg: #FFFFFF;
      --text: #1E1A17;
      --text-muted: #7E7469;
      --border: #EDE4D8;
      --success: #2E7D32;
      --radius: 20px;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Plus Jakarta Sans', sans-serif;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
      padding: 32px 16px 80px;
    }
    .container {
      max-width: 900px;
      margin: 0 auto;
    }
    header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 32px;
      padding-bottom: 24px;
      border-bottom: 1.5px solid var(--border);
      flex-wrap: wrap;
      gap: 16px;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 14px;
    }
    .brand-icon {
      width: 50px;
      height: 50px;
      background: var(--primary);
      border-radius: 14px;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 8px 16px rgba(56, 36, 13, 0.18);
      padding: 7px;
      overflow: hidden;
      flex-shrink: 0;
    }
    .brand-icon img {
      width: 100%;
      height: 100%;
      object-fit: contain;
    }
    .brand-title h1 {
      font-size: 24px;
      font-weight: 900;
      color: var(--primary);
      letter-spacing: -0.5px;
    }
    .brand-title p {
      font-size: 13px;
      color: var(--text-muted);
      font-weight: 500;
    }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: #E8F5E9;
      color: var(--success);
      padding: 8px 16px;
      border-radius: 99px;
      font-size: 13px;
      font-weight: 700;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      background: var(--success);
      border-radius: 50%;
      animation: pulse 1.8s infinite;
    }
    @keyframes pulse {
      0% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.4; transform: scale(1.3); }
      100% { opacity: 1; transform: scale(1); }
    }
    .portal-nav {
      display: inline-flex;
      background: #EDE4D8;
      padding: 5px;
      border-radius: 14px;
      gap: 6px;
      margin-bottom: 28px;
      border: 1px solid var(--border);
    }
    .nav-tab {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 18px;
      border-radius: 10px;
      text-decoration: none;
      font-size: 13.5px;
      font-weight: 700;
      color: var(--text-muted);
      transition: all 0.2s ease;
    }
    .nav-tab svg {
      stroke: currentColor;
    }
    .nav-tab:hover {
      color: var(--primary);
    }
    .nav-tab.active {
      background: var(--card-bg);
      color: var(--primary);
      box-shadow: 0 4px 10px rgba(56, 36, 13, 0.08);
    }
    .hero-card {
      background: linear-gradient(135deg, var(--primary) 0%, #4D3316 100%);
      color: white;
      border-radius: var(--radius);
      padding: 32px;
      margin-bottom: 36px;
      box-shadow: 0 16px 32px rgba(56, 36, 13, 0.18);
      position: relative;
      overflow: hidden;
    }
    .hero-card::after {
      content: '';
      position: absolute;
      right: -40px;
      top: -40px;
      width: 220px;
      height: 220px;
      background: radial-gradient(circle, rgba(212, 163, 115, 0.25) 0%, transparent 70%);
      border-radius: 50%;
    }
    .hero-tag {
      display: inline-block;
      background: rgba(245, 235, 224, 0.18);
      color: var(--primary-light);
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 0.5px;
      text-transform: uppercase;
      margin-bottom: 12px;
    }
    .hero-title {
      font-size: 28px;
      font-weight: 900;
      margin-bottom: 8px;
    }
    .hero-meta {
      font-size: 14px;
      color: rgba(245, 235, 224, 0.8);
      margin-bottom: 24px;
    }
    .download-btn {
      display: inline-flex;
      align-items: center;
      gap: 10px;
      background: var(--primary-light);
      color: var(--primary);
      text-decoration: none;
      padding: 14px 28px;
      border-radius: 14px;
      font-weight: 800;
      font-size: 15px;
      box-shadow: 0 6px 16px rgba(0,0,0,0.15);
      transition: all 0.2s ease;
    }
    .download-btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 20px rgba(0,0,0,0.22);
      background: #FFFFFF;
    }
    .section-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;
    }
    .section-title {
      font-size: 20px;
      font-weight: 800;
      color: var(--primary);
    }
    .build-count {
      font-size: 13px;
      color: var(--text-muted);
      background: var(--card-bg);
      padding: 4px 12px;
      border-radius: 20px;
      border: 1px solid var(--border);
      font-weight: 600;
    }
    .timeline {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .build-card {
      background: var(--card-bg);
      border-radius: var(--radius);
      padding: 24px;
      border: 1.5px solid var(--border);
      box-shadow: 0 4px 12px rgba(56, 36, 13, 0.04);
      transition: all 0.2s ease;
    }
    .build-card:hover {
      border-color: var(--accent);
      box-shadow: 0 8px 24px rgba(56, 36, 13, 0.08);
    }
    .build-card-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 12px;
      flex-wrap: wrap;
      gap: 8px;
    }
    .version-badge {
      font-size: 16px;
      font-weight: 900;
      color: var(--primary);
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .version-pill {
      background: var(--primary-light);
      padding: 4px 10px;
      border-radius: 8px;
      font-size: 12px;
      font-weight: 800;
    }
    .build-date {
      font-size: 12px;
      color: var(--text-muted);
      font-weight: 500;
    }
    .build-meta-row {
      display: flex;
      gap: 16px;
      margin-bottom: 16px;
      flex-wrap: wrap;
      font-size: 12px;
      color: var(--text-muted);
    }
    .meta-tag {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: var(--bg);
      padding: 5px 10px;
      border-radius: 8px;
      border: 1px solid var(--border);
      font-size: 12px;
      font-weight: 600;
      color: var(--text-muted);
    }
    .meta-icon {
      stroke: var(--accent);
      flex-shrink: 0;
    }
    .changes-title {
      font-size: 11px;
      text-transform: uppercase;
      font-weight: 800;
      color: var(--text-muted);
      letter-spacing: 0.6px;
      margin-bottom: 10px;
    }
    .changes-list {
      list-style: none;
      display: flex;
      flex-direction: column;
      gap: 8px;
      margin-bottom: 16px;
    }
    .changes-list li {
      font-size: 13.5px;
      color: var(--text);
      line-height: 1.5;
      position: relative;
      padding-left: 18px;
    }
    .changes-list li::before {
      content: '';
      position: absolute;
      left: 3px;
      top: 8px;
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: var(--accent);
    }
    .card-footer {
      display: flex;
      justify-content: flex-end;
      padding-top: 12px;
      border-top: 1px dashed var(--border);
    }
    .download-link {
      font-size: 13px;
      font-weight: 700;
      color: var(--primary);
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 14px;
      border-radius: 8px;
      background: var(--primary-light);
      transition: background 0.2s;
    }
    .download-link:hover {
      background: var(--accent);
      color: white;
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div class="brand">
        <div class="brand-icon">
          <img src="logo_transparent.png" alt="Vytra Logo">
        </div>
        <div class="brand-title">
          <h1>Vytra Build Monitor</h1>
          <p>Internal Development Release Registry</p>
        </div>
      </div>
      <div class="status-badge">
        <span class="status-dot"></span>
        Latest: v${latest.version || '1.0.0'} (Build ${latest.buildNumber || '1'})
      </div>
    </header>

    <nav class="portal-nav">
      <a href="index.html" class="nav-tab active">
        <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
        Releases & Builds
      </a>
      <a href="commits.html" class="nav-tab">
        <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"></circle><line x1="1.05" y1="12" x2="7" y2="12"></line><line x1="17.01" y1="12" x2="22.96" y2="12"></line></svg>
        Commit Activity
      </a>
    </nav>

    <div class="hero-card">
      <div class="hero-tag">Current Active Build</div>
      <div class="hero-title">Vytra v${latest.version || '1.0.0'}</div>
      <div class="hero-meta">Compiled on ${latest.date || 'Today'} • Size: ${latest.size || '57.8 MB'} • Commit: <code>${latest.commit || 'master'}</code></div>
      <a href="https://github.com/VytraOrg/Vytra/releases/download/v${latest.version || '1.0.3'}/Vytra.apk"
         onclick="if(window.location.protocol === 'file:' || window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') { this.href = 'Vytra.apk'; }"
         class="download-btn" download>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
        Download Vytra.apk
      </a>
    </div>

    <div class="section-header">
      <div class="section-title">Build History & Changelog</div>
      <div class="build-count">${history.length} builds recorded</div>
    </div>

    <div class="timeline">
      ${history.map(item => `
        <div class="build-card">
          <div class="build-card-header">
            <div class="version-badge">
              Vytra v${item.version}
              <span class="version-pill">Build ${item.buildNumber}</span>
            </div>
            <div class="build-date">${item.date}</div>
          </div>
          <div class="build-meta-row">
            <div class="meta-tag">
              <svg class="meta-icon" viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
              ${item.size}
            </div>
            <div class="meta-tag">
              <svg class="meta-icon" viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"></circle><line x1="1.05" y1="12" x2="7" y2="12"></line><line x1="17.01" y1="12" x2="22.96" y2="12"></line></svg>
              Commit: <code>${item.commit}</code>
            </div>
            <div class="meta-tag">
              <svg class="meta-icon" viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="6" y1="3" x2="6" y2="15"></line><circle cx="18" cy="6" r="3"></circle><circle cx="6" cy="18" r="3"></circle><path d="M18 9a9 9 0 0 1-9 9"></path></svg>
              ${item.branch || 'master'}
            </div>
          </div>
          <div class="changes-title">Changes in this build</div>
          <ul class="changes-list">
            ${(item.changes || []).map(c => `<li>${c}</li>`).join('')}
          </ul>
          <div class="card-footer">
            <a href="https://github.com/VytraOrg/Vytra/releases/download/v${item.version}/Vytra.apk"
               onclick="if(window.location.protocol === 'file:' || window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') { this.href = '${item.archivePath || 'Vytra.apk'}'; }"
               class="download-link" download>
              <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
              Download (${item.size})
            </a>
          </div>
        </div>
      `).join('')}
    </div>
  </div>
</body>
</html>`;
}

function generateCommitsHtml(commits, gitInfo) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Vytra - Commit Activity & Engineering Log</title>
  <link rel="icon" type="image/png" href="logo.png">
  <link rel="apple-touch-icon" href="logo.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary: #38240D;
      --primary-light: #F5EBE0;
      --accent: #D4A373;
      --bg: #FAF7F2;
      --card-bg: #FFFFFF;
      --text: #1E1A17;
      --text-muted: #7E7469;
      --border: #EDE4D8;
      --success: #2E7D32;
      --danger: #C62828;
      --radius: 20px;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Plus Jakarta Sans', sans-serif;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
      padding: 32px 16px 80px;
    }
    .container {
      max-width: 900px;
      margin: 0 auto;
    }
    header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 24px;
      padding-bottom: 24px;
      border-bottom: 1.5px solid var(--border);
      flex-wrap: wrap;
      gap: 16px;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 14px;
    }
    .brand-icon {
      width: 50px;
      height: 50px;
      background: var(--primary);
      border-radius: 14px;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 8px 16px rgba(56, 36, 13, 0.18);
      padding: 7px;
      overflow: hidden;
      flex-shrink: 0;
    }
    .brand-icon img {
      width: 100%;
      height: 100%;
      object-fit: contain;
    }
    .brand-title h1 {
      font-size: 24px;
      font-weight: 900;
      color: var(--primary);
      letter-spacing: -0.5px;
    }
    .brand-title p {
      font-size: 13px;
      color: var(--text-muted);
      font-weight: 500;
    }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: #E8F5E9;
      color: var(--success);
      padding: 8px 16px;
      border-radius: 99px;
      font-size: 13px;
      font-weight: 700;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      background: var(--success);
      border-radius: 50%;
      animation: pulse 1.8s infinite;
    }
    @keyframes pulse {
      0% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.4; transform: scale(1.3); }
      100% { opacity: 1; transform: scale(1); }
    }
    .portal-nav {
      display: inline-flex;
      background: #EDE4D8;
      padding: 5px;
      border-radius: 14px;
      gap: 6px;
      margin-bottom: 28px;
      border: 1px solid var(--border);
    }
    .nav-tab {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 18px;
      border-radius: 10px;
      text-decoration: none;
      font-size: 13.5px;
      font-weight: 700;
      color: var(--text-muted);
      transition: all 0.2s ease;
    }
    .nav-tab svg {
      stroke: currentColor;
    }
    .nav-tab:hover {
      color: var(--primary);
    }
    .nav-tab.active {
      background: var(--card-bg);
      color: var(--primary);
      box-shadow: 0 4px 10px rgba(56, 36, 13, 0.08);
    }
    .search-card {
      background: var(--card-bg);
      border: 1.5px solid var(--border);
      border-radius: var(--radius);
      padding: 20px 24px;
      margin-bottom: 28px;
      box-shadow: 0 6px 16px rgba(56, 36, 13, 0.05);
    }
    .search-input-wrapper {
      position: relative;
      display: flex;
      align-items: center;
      margin-bottom: 16px;
    }
    .search-icon {
      position: absolute;
      left: 16px;
      stroke: var(--text-muted);
      pointer-events: none;
    }
    .search-input {
      width: 100%;
      padding: 13px 44px 13px 44px;
      background: var(--bg);
      border: 1.5px solid var(--border);
      border-radius: 12px;
      font-family: inherit;
      font-size: 14px;
      font-weight: 500;
      color: var(--text);
      outline: none;
      transition: border-color 0.2s, background 0.2s;
    }
    .search-input:focus {
      border-color: var(--accent);
      background: #FFFFFF;
    }
    .clear-btn {
      position: absolute;
      right: 14px;
      background: none;
      border: none;
      color: var(--text-muted);
      cursor: pointer;
      font-size: 16px;
      font-weight: 700;
      display: none;
      padding: 4px;
    }
    .stats-bar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 12px;
      font-size: 13px;
      color: var(--text-muted);
    }
    .stats-group {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }
    .stat-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: var(--bg);
      padding: 5px 12px;
      border-radius: 8px;
      border: 1px solid var(--border);
      font-weight: 600;
      font-size: 12.5px;
    }
    .github-link {
      color: var(--primary);
      text-decoration: none;
      font-weight: 700;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: color 0.2s;
    }
    .github-link:hover {
      color: var(--accent);
    }
    .commits-timeline {
      display: flex;
      flex-direction: column;
      gap: 14px;
    }
    .commit-card {
      background: var(--card-bg);
      border-radius: 16px;
      border: 1.5px solid var(--border);
      padding: 20px 22px;
      box-shadow: 0 4px 12px rgba(56, 36, 13, 0.04);
      transition: all 0.2s ease;
    }
    .commit-card:hover {
      border-color: var(--accent);
      box-shadow: 0 8px 20px rgba(56, 36, 13, 0.08);
      transform: translateY(-1px);
    }
    .commit-header {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 16px;
      margin-bottom: 12px;
      flex-wrap: wrap;
    }
    .commit-subject {
      font-size: 15px;
      font-weight: 700;
      color: var(--primary);
      line-height: 1.45;
      flex: 1;
      min-width: 260px;
    }
    .commit-date {
      font-size: 12px;
      color: var(--text-muted);
      font-weight: 500;
      white-space: nowrap;
    }
    .commit-meta {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }
    .meta-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: var(--bg);
      padding: 4px 10px;
      border-radius: 7px;
      border: 1px solid var(--border);
      font-size: 12px;
      font-weight: 600;
      color: var(--text-muted);
    }
    .hash-badge {
      text-decoration: none;
      color: var(--primary);
      background: var(--primary-light);
      border-color: transparent;
      transition: all 0.2s;
    }
    .hash-badge:hover {
      background: var(--accent);
      color: white;
    }
    .copy-sha-btn {
      background: none;
      border: 1px solid var(--border);
      padding: 4px 8px;
      border-radius: 7px;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 5px;
      font-size: 11.5px;
      font-weight: 600;
      color: var(--text-muted);
      font-family: inherit;
      transition: all 0.2s;
    }
    .copy-sha-btn:hover {
      border-color: var(--primary);
      color: var(--primary);
    }
    .diff-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 12px;
      font-weight: 700;
      margin-left: auto;
    }
    .diff-files {
      color: var(--text-muted);
    }
    .diff-add {
      color: var(--success);
      background: #E8F5E9;
      padding: 2px 6px;
      border-radius: 5px;
    }
    .diff-del {
      color: var(--danger);
      background: #FFEBEE;
      padding: 2px 6px;
      border-radius: 5px;
    }
    .empty-state {
      text-align: center;
      padding: 48px 24px;
      background: var(--card-bg);
      border-radius: var(--radius);
      border: 1.5px dashed var(--border);
      color: var(--text-muted);
      display: none;
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div class="brand">
        <div class="brand-icon">
          <img src="logo_transparent.png" alt="Vytra Logo">
        </div>
        <div class="brand-title">
          <h1>Vytra Build Monitor</h1>
          <p>Internal Development Release Registry</p>
        </div>
      </div>
      <div class="status-badge">
        <span class="status-dot"></span>
        Branch: ${escapeHtml(gitInfo.branch || 'master')}
      </div>
    </header>

    <nav class="portal-nav">
      <a href="index.html" class="nav-tab">
        <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
        Releases & Builds
      </a>
      <a href="commits.html" class="nav-tab active">
        <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"></circle><line x1="1.05" y1="12" x2="7" y2="12"></line><line x1="17.01" y1="12" x2="22.96" y2="12"></line></svg>
        Commit Activity
      </a>
    </nav>

    <div class="search-card">
      <div class="search-input-wrapper">
        <svg class="search-icon" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
        <input type="text" id="commitSearch" class="search-input" placeholder="Filter commits by title, author, or commit hash..." autocomplete="off">
        <button id="clearBtn" class="clear-btn" onclick="clearSearch()">✕</button>
      </div>
      <div class="stats-bar">
        <div class="stats-group">
          <div class="stat-pill"><span id="visibleCount">${commits.length}</span> commits recorded</div>
          <div class="stat-pill">HEAD: <code>${gitInfo.commit || 'HEAD'}</code></div>
        </div>
        <a href="https://github.com/VytraOrg/Vytra/commits" target="_blank" class="github-link">
          <span>GitHub History</span>
          <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path><polyline points="15 3 21 3 21 9"></polyline><line x1="10" y1="14" x2="21" y2="3"></line></svg>
        </a>
      </div>
    </div>

    <div class="commits-timeline" id="commitsList">
      ${commits.map(c => `
        <div class="commit-card" data-search="${(c.subject + ' ' + c.author + ' ' + c.shortHash + ' ' + c.hash).toLowerCase()}">
          <div class="commit-header">
            <span class="commit-subject">${escapeHtml(c.subject)}</span>
            <span class="commit-date">${c.date}</span>
          </div>
          <div class="commit-meta">
            <div class="meta-badge">
              <svg viewBox="0 0 24 24" width="12" height="12" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
              ${escapeHtml(c.author)}
            </div>
            <a href="https://github.com/VytraOrg/Vytra/commit/${c.hash}" target="_blank" class="meta-badge hash-badge" title="View commit diff on GitHub">
              <code>${c.shortHash}</code>
              <svg viewBox="0 0 24 24" width="10" height="10" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path><polyline points="15 3 21 3 21 9"></polyline><line x1="10" y1="14" x2="21" y2="3"></line></svg>
            </a>
            <button class="copy-sha-btn" onclick="copySha('${c.hash}', this)" title="Copy commit SHA">
              <svg viewBox="0 0 24 24" width="11" height="11" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
              <span>Copy SHA</span>
            </button>
            ${c.files !== '0' ? `
              <div class="diff-badge">
                <span class="diff-files">${c.files} files</span>
                ${c.insertions !== '0' ? `<span class="diff-add">+${c.insertions}</span>` : ''}
                ${c.deletions !== '0' ? `<span class="diff-del">-${c.deletions}</span>` : ''}
              </div>
            ` : ''}
          </div>
        </div>
      `).join('')}
    </div>

    <div id="emptyState" class="empty-state">
      <p>No commits match your search query.</p>
    </div>
  </div>

  <script>
    function copySha(hash, btn) {
      navigator.clipboard.writeText(hash).then(() => {
        const original = btn.innerHTML;
        btn.innerHTML = '<span style="color:var(--success);font-weight:700;">Copied!</span>';
        setTimeout(() => { btn.innerHTML = original; }, 1600);
      }).catch(() => {
        prompt('Commit SHA:', hash);
      });
    }

    const searchInput = document.getElementById('commitSearch');
    const clearBtn = document.getElementById('clearBtn');
    const cards = document.querySelectorAll('.commit-card');
    const countEl = document.getElementById('visibleCount');
    const emptyState = document.getElementById('emptyState');

    function clearSearch() {
      searchInput.value = '';
      filter();
      searchInput.focus();
    }

    function filter() {
      const q = searchInput.value.toLowerCase().trim();
      clearBtn.style.display = q ? 'inline-block' : 'none';
      let visible = 0;
      cards.forEach(card => {
        const text = card.getAttribute('data-search') || '';
        const match = !q || text.includes(q);
        card.style.display = match ? 'block' : 'none';
        if (match) visible++;
      });
      countEl.textContent = visible;
      emptyState.style.display = visible === 0 ? 'block' : 'none';
    }

    searchInput.addEventListener('input', filter);
  </script>
</body>
</html>`;
}

function updateChangelog(history) {
  let md = `# 📦 Vytra Release Changelog\n\nAll builds, versions, and change logs are automatically tracked here.\n\n`;
  for (const item of history) {
    md += `## [v${item.version}] - Build ${item.buildNumber} (${item.date})\n`;
    md += `- **Commit**: \`${item.commit}\` (${item.branch})\n`;
    md += `- **APK**: [\`${item.apkName}\`](releases/${item.archivePath || item.apkName}) (${item.size})\n`;
    md += `### Changes:\n`;
    for (const c of item.changes || []) {
      md += `- ${c}\n`;
    }
    md += `\n---\n\n`;
  }
  fs.writeFileSync(changelogPath, md, 'utf8');
}

async function main() {
  const gitInfo = getGitInfo();

  if (process.argv.includes('--refresh')) {
    const history = loadHistory();
    const html = generateDashboardHtml(history);
    fs.writeFileSync(dashboardPath, html, 'utf8');
    fs.writeFileSync(docsDashboardPath, html, 'utf8');

    const commits = getCommitHistory(80);
    const commitsHtml = generateCommitsHtml(commits, gitInfo);
    fs.writeFileSync(commitsPath, commitsHtml, 'utf8');
    fs.writeFileSync(docsCommitsPath, commitsHtml, 'utf8');

    updateChangelog(history);
    console.log(`✅ Refreshed portals (index.html & commits.html in releases/ and docs/) and CHANGELOG.md`);
    return;
  }

  const customChangesArg = process.argv.slice(2).join(' ').trim();
  const currentVersion = parsePubspecVersion();

  // Increment development version: 1.0.<build>
  const nextBuildNumber = currentVersion.build + 1;
  const nextVersionName = `1.0.${nextBuildNumber}`;

  console.log(`\n=================================================`);
  console.log(`🚀 VYTRA BUILD PIPELINE: v${nextVersionName} (Build ${nextBuildNumber})`);
  console.log(`=================================================`);
  console.log(`📌 Updating pubspec.yaml -> version: ${nextVersionName}+${nextBuildNumber}`);
  updatePubspecVersion(nextVersionName, nextBuildNumber);

  // Compile with Flutter
  console.log(`⚡ Running: flutter build apk --release --build-name=${nextVersionName} --build-number=${nextBuildNumber}`);
  execSync(`flutter build apk --release --build-name=${nextVersionName} --build-number=${nextBuildNumber}`, {
    cwd: frontendDir,
    stdio: 'inherit',
  });

  const sourceApk = path.join(frontendDir, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
  if (!fs.existsSync(sourceApk)) {
    console.error(`❌ Build failed: output APK not found at ${sourceApk}`);
    process.exit(1);
  }

  // File size
  const stats = fs.statSync(sourceApk);
  const sizeMb = (stats.size / (1024 * 1024)).toFixed(1) + ' MB';

  // Copy to releases/Vytra.apk and archive
  const targetLatest = path.join(releasesDir, 'Vytra.apk');
  const targetArchive = path.join(archivesDir, `Vytra-v${nextVersionName}.apk`);

  fs.copyFileSync(sourceApk, targetLatest);
  fs.copyFileSync(sourceApk, targetArchive);
  console.log(`✅ Saved latest: releases/Vytra.apk`);
  console.log(`✅ Saved archive: releases/archives/Vytra-v${nextVersionName}.apk`);

  // Parse changes
  let changesList = [];
  if (customChangesArg) {
    changesList = customChangesArg.split(/;|\n/).map(s => s.trim()).filter(Boolean);
  } else if (gitInfo.commitMsg) {
    changesList = [gitInfo.commitMsg];
  } else {
    changesList = ['Development release update'];
  }

  const now = new Date();
  const dateStr = now.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }) + ', ' +
    now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });

  const newRecord = {
    version: nextVersionName,
    buildNumber: nextBuildNumber,
    timestamp: now.toISOString(),
    date: dateStr,
    commit: gitInfo.commit,
    branch: gitInfo.branch,
    size: sizeMb,
    apkName: 'Vytra.apk',
    archivePath: `archives/Vytra-v${nextVersionName}.apk`,
    changes: changesList,
  };

  const history = loadHistory();
  history.unshift(newRecord);

  fs.writeFileSync(historyPath, JSON.stringify(history, null, 2), 'utf8');
  console.log(`✅ Updated releases/build_history.json`);

  const html = generateDashboardHtml(history);
  fs.writeFileSync(dashboardPath, html, 'utf8');
  fs.writeFileSync(docsDashboardPath, html, 'utf8');

  const commits = getCommitHistory(80);
  const commitsHtml = generateCommitsHtml(commits, gitInfo);
  fs.writeFileSync(commitsPath, commitsHtml, 'utf8');
  fs.writeFileSync(docsCommitsPath, commitsHtml, 'utf8');
  console.log(`✅ Generated releases/ (index.html, commits.html) & docs/ (GitHub Pages)`);

  updateChangelog(history);
  console.log(`✅ Updated CHANGELOG.md`);

  console.log(`\n🎉 BUILD COMPLETE!`);
  console.log(`📱 APK: releases/Vytra.apk (${sizeMb})`);
  console.log(`🌐 Monitor Dashboard: releases/index.html & docs/index.html`);
  console.log(`🚀 GitHub Release Tag: v${nextVersionName}`);
  console.log(`📦 GitHub Release URL: https://github.com/VytraOrg/Vytra/releases/new?tag=v${nextVersionName}`);
  console.log(`=================================================\n`);
}

main().catch(err => {
  console.error(`❌ Build pipeline failed:`, err);
  process.exit(1);
});

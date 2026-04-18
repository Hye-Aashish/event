// ── Config ────────────────────────────────────────────────────────
const API = 'http://localhost:3000/api';
let allEvents = [];

// ── Utility ──────────────────────────────────────────────────────
async function apiFetch(path, opts = {}) {
  try {
    const res = await fetch(API + path, {
      headers: { 'Content-Type': 'application/json' },
      ...opts,
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || `HTTP ${res.status}`);
    }
    return res.json();
  } catch (e) {
    showToast('❌ ' + e.message, 'error');
    throw e;
  }
}

function showToast(msg, type = 'success') {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className = `toast show ${type}`;
  setTimeout(() => t.className = 'toast', 3000);
}

function openModal(id) { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }

function badge(status) {
  const map = {
    active: 'badge-success', published: 'badge-success', approved: 'badge-success',
    pending: 'badge-warning', draft: 'badge-warning',
    used: 'badge-info',       season: 'badge-info',     regular: 'badge-muted',
    expired: 'badge-muted',   transferred: 'badge-muted', cancelled: 'badge-muted',
    success: 'badge-success', duplicate: 'badge-warning', invalid_sig: 'badge-danger',
    fraud: 'badge-danger',    time_invalid: 'badge-warning',
  };
  return `<span class="badge ${map[status] || 'badge-muted'}">${status}</span>`;
}

function fmt(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' });
}

// ── Navigation ────────────────────────────────────────────────────
function navigate(page, el) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  document.getElementById('page-' + page).classList.add('active');
  if (el) el.classList.add('active');
  document.getElementById('pageTitle').textContent =
    { dashboard: 'Dashboard', events: 'Events', zones: 'Zones', tickets: 'Tickets',
      users: 'Users', sponsors: 'Sponsors', scanlogs: 'Scan Logs' }[page];

  const loaders = { events: loadEvents, zones: loadZones, tickets: loadTickets,
                    users: loadUsers, sponsors: loadSponsors, scanlogs: loadScanLogs,
                    dashboard: loadDashboard };
  if (loaders[page]) loaders[page]();
}

// ── Dashboard ─────────────────────────────────────────────────────
async function loadDashboard() {
  try {
    const [events, adminStats] = await Promise.allSettled([
      apiFetch('/events'),
      apiFetch('/admin/stats'),
    ]);

    const evts = events.status === 'fulfilled' ? events.value : [];
    allEvents = evts;

    document.getElementById('stat-events').textContent = evts.length;

    if (adminStats.status === 'fulfilled') {
      const s = adminStats.value;
      document.getElementById('stat-tickets').textContent = s.totalTickets ?? '--';
      document.getElementById('stat-users').textContent   = s.totalUsers   ?? '--';
      document.getElementById('stat-scans').textContent   = s.totalScans   ?? '--';
    }

    // Initialize Chart
    if (adminStats.status === 'fulfilled' && adminStats.value.chartData) {
      renderSalesChart(adminStats.value.chartData);
    }

    // Recent scans... (existing code)

    // Recent scans (try first event)
    const rs = document.getElementById('recentScans');
    if (evts.length) {
      try {
        const logs = await apiFetch(`/gate/logs/${evts[0]._id}`);
        if (!logs.length) rs.innerHTML = '<div class="loading">No scans yet</div>';
        else {
          rs.innerHTML = logs.slice(0, 6).map(l => `
            <div class="list-item">
              <div>
                <div class="list-item-title">Ticket #${String(l.ticketId).slice(-6)}</div>
                <div class="list-item-sub">${fmt(l.createdAt)} · ${l.message || ''}</div>
              </div>
              ${badge(l.status)}
            </div>`).join('');
        }
      } catch { rs.innerHTML = '<div class="loading">No scan data</div>'; }
    } else {
      rs.innerHTML = '<div class="loading">Create an event first</div>';
    }
  } catch (e) {}
}

// ── Events ────────────────────────────────────────────────────────
async function loadEvents() {
  const tb = document.getElementById('eventsTable');
  tb.innerHTML = '<tr><td colspan="6" class="loading">Loading...</td></tr>';
  try {
    const events = await apiFetch('/events');
    allEvents = events;
    populateEventDropdowns(events);
    if (!events.length) {
      tb.innerHTML = '<tr><td colspan="6" class="loading">No events yet. Click + New Event</td></tr>';
      return;
    }
    tb.innerHTML = events.map(e => `
      <tr>
        <td><strong>${e.name}</strong><br><small style="color:var(--muted)">${e.description?.slice(0,40) || ''}</small></td>
        <td>${e.venue}</td>
        <td>${(e.eventDates || []).join('<br>')}</td>
        <td>${badge(e.status)}</td>
        <td>${e.gstEnabled ? `<span class="badge badge-success">${e.gstPercentage}%</span>` : '<span class="badge badge-muted">Off</span>'}</td>
        <td>
          <div class="table-actions">
            <button class="btn btn-sm" onclick="editEvent('${e._id}')">✏️ Edit</button>
            <button class="btn btn-outline btn-sm" onclick="navigate('zones', null); document.getElementById('zoneEventFilter').value='${e._id}'; loadZones();">🏟️ Zones</button>
            <button class="btn btn-danger btn-sm" onclick="deleteEvent('${e._id}')">🗑️</button>
          </div>
        </td>
      </tr>`).join('');
  } catch (e) { tb.innerHTML = '<tr><td colspan="6" class="loading">Failed to load</td></tr>'; }
}

function openEventModal(reset = true) {
  if (reset) {
    document.getElementById('editEventId').value = '';
    document.getElementById('eventModalTitle').textContent = 'Create New Event';
    ['eventName','eventVenue','eventDesc','eventDates','eventGst','eventMaxSponsor',
     'priceRegularVIP','priceRegularGeneral','priceRegularPremium',
     'priceSeasonVIP','priceSeasonGeneral','priceSeasonPremium'].forEach(id => {
      document.getElementById(id).value = '';
    });
    document.getElementById('eventStatus').value = 'draft';
    document.getElementById('eventGstEnabled').value = 'false';
    document.getElementById('eventGst').value = 18;
    document.getElementById('eventMaxSponsor').value = 100;
    document.getElementById('eventImageUrl').value = '';
    document.getElementById('imagePreview').style.display = 'none';
  }
  openModal('eventModal');
}

async function editEvent(id) {
  try {
    const e = await apiFetch(`/events/${id}`);
    document.getElementById('editEventId').value = e._id;
    document.getElementById('eventModalTitle').textContent = 'Edit Event';
    document.getElementById('eventName').value  = e.name || '';
    document.getElementById('eventVenue').value = e.venue || '';
    document.getElementById('eventDesc').value  = e.description || '';
    document.getElementById('eventDates').value = (e.eventDates || []).join(',');
    document.getElementById('eventStatus').value = e.status || 'draft';
    document.getElementById('eventGstEnabled').value = String(e.gstEnabled || false);
    document.getElementById('eventGst').value = e.gstPercentage || 18;
    document.getElementById('eventMaxSponsor').value = e.maxSponsorTickets || 0;
    document.getElementById('priceRegularVIP').value     = e.ticketPricing?.regular?.VIP     || '';
    document.getElementById('priceRegularGeneral').value = e.ticketPricing?.regular?.General || '';
    document.getElementById('priceRegularPremium').value = e.ticketPricing?.regular?.Premium || '';
    document.getElementById('priceSeasonVIP').value      = e.ticketPricing?.season?.VIP      || '';
    document.getElementById('priceSeasonGeneral').value  = e.ticketPricing?.season?.General  || '';
    document.getElementById('priceSeasonPremium').value  = e.ticketPricing?.season?.Premium  || '';
    
    if (e.imageUrl) {
      document.getElementById('eventImageUrl').value = e.imageUrl;
      document.getElementById('previewImg').src = API.replace('/api', '') + e.imageUrl; 
      document.getElementById('imagePreview').style.display = 'block';
    } else {
      document.getElementById('imagePreview').style.display = 'none';
    }
    
    openModal('eventModal');
}

async function saveEvent() {
  const id = document.getElementById('editEventId').value;
  const body = {
    name:        document.getElementById('eventName').value,
    venue:       document.getElementById('eventVenue').value,
    description: document.getElementById('eventDesc').value,
    eventDates:  document.getElementById('eventDates').value.split(',').map(d => d.trim()).filter(Boolean),
    imageUrl:    document.getElementById('eventImageUrl').value,
    status:      document.getElementById('eventStatus').value,
    gstEnabled:  document.getElementById('eventGstEnabled').value === 'true',
    gstPercentage: Number(document.getElementById('eventGst').value),
    maxSponsorTickets: Number(document.getElementById('eventMaxSponsor').value),
    ticketPricing: {
      regular: {
        VIP:     Number(document.getElementById('priceRegularVIP').value)     || 0,
        General: Number(document.getElementById('priceRegularGeneral').value) || 0,
        Premium: Number(document.getElementById('priceRegularPremium').value) || 0,
      },
      season: {
        VIP:     Number(document.getElementById('priceSeasonVIP').value)     || 0,
        General: Number(document.getElementById('priceSeasonGeneral').value) || 0,
        Premium: Number(document.getElementById('priceSeasonPremium').value) || 0,
      },
    },
  };

  try {
    if (id) {
      await apiFetch(`/events/${id}`, { method: 'PUT', body: JSON.stringify(body) });
      showToast('✅ Event updated!');
    } else {
      await apiFetch('/events', { method: 'POST', body: JSON.stringify(body) });
      showToast('🎉 Event created!');
    }
    closeModal('eventModal');
    loadEvents();
  } catch {}
}

async function deleteEvent(id) {
  if (!confirm('Delete this event?')) return;
  await apiFetch(`/events/${id}`, { method: 'DELETE' });
  showToast('🗑️ Event deleted');
  loadEvents();
}

// ── Zones ─────────────────────────────────────────────────────────
async function loadZones() {
  const tb = document.getElementById('zonesTable');
  tb.innerHTML = '<tr><td colspan="6" class="loading">Loading...</td></tr>';
  try {
    const eventId = document.getElementById('zoneEventFilter').value;
    const path = eventId ? `/events/${eventId}/zones` : '/zones';
    const zones = await apiFetch(path);
    if (!zones.length) {
      tb.innerHTML = '<tr><td colspan="6" class="loading">No zones yet</td></tr>'; return;
    }
    tb.innerHTML = zones.map(z => `
      <tr>
        <td><strong>${z.name}</strong></td>
        <td>${z.eventId?.name || z.eventId || '—'}</td>
        <td>${z.capacity}</td>
        <td>
          <div style="display:flex;align-items:center;gap:8px">
            <div style="background:rgba(255,255,255,0.1);border-radius:4px;height:6px;width:80px;overflow:hidden">
              <div style="width:${Math.min(100, (z.currentCount/z.capacity)*100)||0}%;height:100%;background:linear-gradient(90deg,var(--pink),var(--purple))"></div>
            </div>
            <span style="font-size:12px">${z.currentCount}/${z.capacity}</span>
          </div>
        </td>
        <td>${badge(z.isActive ? 'active' : 'cancelled')}</td>
        <td>
          <div class="table-actions">
            <button class="btn btn-sm" onclick="editZone('${z._id}')">✏️ Edit</button>
          </div>
        </td>
      </tr>`).join('');
  } catch { tb.innerHTML = '<tr><td colspan="6" class="loading">Failed to load</td></tr>'; }
}

async function saveZone() {
  const body = {
    name:        document.getElementById('zoneName').value,
    eventId:     document.getElementById('zoneEventId').value,
    capacity:    Number(document.getElementById('zoneCapacity').value),
    availableSeats: Number(document.getElementById('zoneCapacity').value),
    price:       Number(document.getElementById('zonePrice').value),
    type:        document.getElementById('zoneType').value,
    color:       document.getElementById('zoneColor').value,
    autoVerifySeasonPass: document.getElementById('zoneAutoVerify').value === 'true',
    allowedTicketCategories: document.getElementById('zoneCategories').value.split(',').map(c => c.trim()).filter(Boolean),
  };
  const id = document.getElementById('editZoneId').value;
  try {
    if (id) {
      await apiFetch(`/events/zones/${id}`, { method: 'PUT', body: JSON.stringify(body) });
      showToast('✅ Zone updated!');
    } else {
      await apiFetch('/events/zones', { method: 'POST', body: JSON.stringify(body) });
      showToast('🎉 Zone created!');
    }
    closeModal('zoneModal');
    loadZones();
  } catch {}
}

async function editZone(id) {
  try {
    const zones = await apiFetch('/zones');
    const z = zones.find(z => z._id === id);
    if (!z) return;
    document.getElementById('editZoneId').value = z._id;
    document.getElementById('zoneName').value = z.name;
    document.getElementById('zoneEventId').value = z.eventId?._id || z.eventId;
    document.getElementById('zoneCapacity').value = z.capacity;
    document.getElementById('zonePrice').value = z.price || 0;
    document.getElementById('zoneType').value = z.type || 'daily';
    document.getElementById('zoneColor').value = z.color || '#FF0080';
    document.getElementById('zoneAutoVerify').value = String(z.autoVerifySeasonPass);
    document.getElementById('zoneCategories').value = (z.allowedTicketCategories || []).join(',');
    openModal('zoneModal');
  } catch {}
}

// ── Tickets ──────────────────────────────────────────────────────
async function loadTickets() {
  const tb = document.getElementById('ticketsTable');
  tb.innerHTML = '<tr><td colspan="8" class="loading">Loading...</td></tr>';
  try {
    const eventId  = document.getElementById('ticketEventFilter').value;
    const type     = document.getElementById('ticketTypeFilter').value;
    const status   = document.getElementById('ticketStatusFilter').value;

    let params = new URLSearchParams();
    if (eventId) params.append('eventId', eventId);
    if (type)    params.append('type', type);
    if (status)  params.append('status', status);

    const tickets = await apiFetch(`/tickets/all?${params.toString()}`);
    allTickets = tickets;
    if (!tickets.length) {
      tb.innerHTML = '<tr><td colspan="8" class="loading">No tickets found</td></tr>'; return;
    }
    tb.innerHTML = tickets.map(t => `
      <tr>
        <td style="font-family:monospace;font-size:11px;color:var(--muted)">${String(t._id).slice(-8)}</td>
        <td>${t.userId?.phoneNumber || t.userId || '—'}</td>
        <td>${t.eventId?.name || '—'}</td>
        <td>${badge(t.type)}</td>
        <td>${t.category}</td>
        <td>${badge(t.status)}</td>
        <td>${t.type === 'season' ? badge(t.verificationStatus || 'pending') : '—'}</td>
        <td>₹${t.totalAmount || 0}</td>
      </tr>`).join('');
  } catch { tb.innerHTML = '<tr><td colspan="8" class="loading">Failed to load</td></tr>'; }
}

// ── Users ─────────────────────────────────────────────────────────
async function loadUsers() {
  const tb = document.getElementById('usersTable');
  tb.innerHTML = '<tr><td colspan="6" class="loading">Loading...</td></tr>';
  try {
    const users = await apiFetch('/admin/users');
    allUsers = users;
    if (!users.length) { tb.innerHTML = '<tr><td colspan="6" class="loading">No users yet</td></tr>'; return; }
    tb.innerHTML = users.map(u => `
      <tr>
        <td>${u.phoneNumber}</td>
        <td>${u.name || '—'}</td>
        <td>${badge(u.role)}</td>
        <td>${u.isVerified ? '<span class="badge badge-success">Yes</span>' : '<span class="badge badge-muted">No</span>'}</td>
        <td>${fmt(u.createdAt)}</td>
        <td>
          <div class="table-actions">
            <select class="select-input" style="padding:4px 8px;font-size:12px" onchange="updateUserRole('${u._id}',this.value)">
              <option value="">Change Role</option>
              <option value="user">User</option>
              <option value="scanner">Scanner</option>
              <option value="zone_manager">Zone Manager</option>
              <option value="admin">Admin</option>
            </select>
          </div>
        </td>
      </tr>`).join('');
  } catch { tb.innerHTML = '<tr><td colspan="6" class="loading">Failed to load</td></tr>'; }
}

async function updateUserRole(id, role) {
  if (!role) return;
  try {
    await apiFetch(`/admin/users/${id}/role`, { method: 'PUT', body: JSON.stringify({ role }) });
    showToast('✅ Role updated!');
    loadUsers();
  } catch {}
}

// ── Sponsors ──────────────────────────────────────────────────────
async function loadSponsors() {
  const tb = document.getElementById('sponsorsTable');
  tb.innerHTML = '<tr><td colspan="6" class="loading">Loading...</td></tr>';
  try {
    const sponsors = await apiFetch('/sponsors/all');
    if (!sponsors.length) { tb.innerHTML = '<tr><td colspan="6" class="loading">No sponsors yet</td></tr>'; return; }
    tb.innerHTML = sponsors.map(s => `
      <tr>
        <td><strong>${s.name}</strong><br><small style="color:var(--muted)">${s.contactName}</small></td>
        <td>${s.eventId?.name || '—'}</td>
        <td>${badge(s.limitType)}</td>
        <td>
          <div style="font-size:12px">
            Tickets: ${s.ticketsUsed}/${s.ticketQuota}<br>
            Credit: ₹${s.creditUsed}/₹${s.creditLimit}
          </div>
        </td>
        <td>${badge(s.status)}</td>
        <td>
          <div class="table-actions">
            <button class="btn btn-danger btn-sm" onclick="suspendSponsor('${s._id}')">Suspend</button>
          </div>
        </td>
      </tr>`).join('');
  } catch { tb.innerHTML = '<tr><td colspan="6" class="loading">Failed to load</td></tr>'; }
}

async function saveSponsor() {
  const body = {
    name:         document.getElementById('sponsorName').value,
    contactName:  document.getElementById('sponsorContact').value,
    phone:        document.getElementById('sponsorPhone').value,
    email:        document.getElementById('sponsorEmail').value,
    eventId:      document.getElementById('sponsorEventId').value,
    limitType:    document.getElementById('sponsorLimitType').value,
    ticketQuota:  Number(document.getElementById('sponsorQuota').value),
    creditLimit:  Number(document.getElementById('sponsorCredit').value),
  };
  try {
    await apiFetch('/sponsors', { method: 'POST', body: JSON.stringify(body) });
    showToast('🤝 Sponsor created!');
    closeModal('sponsorModal');
    loadSponsors();
  } catch {}
}

async function suspendSponsor(id) {
  await apiFetch(`/sponsors/${id}`, { method: 'PUT', body: JSON.stringify({ status: 'suspended' }) });
  showToast('⛔ Sponsor suspended');
  loadSponsors();
}

// ── Scan Logs ────────────────────────────────────────────────────
async function loadScanLogs() {
  const eventId = document.getElementById('scanEventFilter').value;
  const tb = document.getElementById('scanLogsTable');
  if (!eventId) { tb.innerHTML = '<tr><td colspan="5" class="loading">Select an event</td></tr>'; return; }
  tb.innerHTML = '<tr><td colspan="5" class="loading">Loading...</td></tr>';
  try {
    const logs = await apiFetch(`/gate/logs/${eventId}`);
    if (!logs.length) { tb.innerHTML = '<tr><td colspan="5" class="loading">No scan logs</td></tr>'; return; }
    tb.innerHTML = logs.map(l => `
      <tr>
        <td style="font-size:12px">${fmt(l.createdAt)}</td>
        <td style="font-family:monospace;font-size:11px">${String(l.ticketId).slice(-8)}</td>
        <td>${badge(l.status)}</td>
        <td>${l.zoneId?.name || '—'}</td>
        <td style="color:var(--muted);font-size:12px">${l.message || ''}</td>
      </tr>`).join('');
  } catch { tb.innerHTML = '<tr><td colspan="5" class="loading">Failed to load</td></tr>'; }
}

// ── Dropdown Helper ──────────────────────────────────────────────
function populateEventDropdowns(events) {
  const dropdowns = ['zoneEventFilter','zoneEventId','sponsorEventId','ticketEventFilter','scanEventFilter'];
  dropdowns.forEach(id => {
    const el = document.getElementById(id);
    if (!el) return;
    const current = el.value;
    const placeholder = el.options[0].text;
    el.innerHTML = `<option value="">${placeholder}</option>` +
      events.map(e => `<option value="${e._id}">${e.name}</option>`).join('');
    el.value = current;
  });
}

// ── Search & Charts ──────────────────────────────────────────────
let salesChartInstance = null;
function renderSalesChart(data) {
  const ctx = document.getElementById('salesChart');
  if (!ctx) return;
  
  if (salesChartInstance) salesChartInstance.destroy();
  
  salesChartInstance = new Chart(ctx, {
    type: 'line',
    data: {
      labels: data.labels || [],
      datasets: [{
        label: 'Tickets Sold',
        data: data.values || [],
        borderColor: '#FF0080',
        backgroundColor: 'rgba(255, 0, 128, 0.1)',
        fill: true,
        tension: 0.4
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        y: { beginAtZero: true, grid: { color: 'rgba(255,255,255,0.05)' } },
        x: { grid: { display: false } }
      }
    }
  });
}

let allUsers = [];
let allTickets = [];

function filterUsers() {
  const q = document.getElementById('userSearch').value.toLowerCase();
  const tb = document.getElementById('usersTable');
  const filtered = allUsers.filter(u => 
    u.phoneNumber.toLowerCase().includes(q) || 
    (u.name && u.name.toLowerCase().includes(q))
  );
  renderUserTable(filtered);
}

function filterTickets() {
  const q = document.getElementById('ticketSearch').value.toLowerCase();
  const tb = document.getElementById('ticketsTable');
  const filtered = allTickets.filter(t => 
    String(t._id).toLowerCase().includes(q) || 
    (t.userId?.phoneNumber && t.userId?.phoneNumber.toLowerCase().includes(q))
  );
  renderTicketTable(filtered);
}

function renderUserTable(users) {
  const tb = document.getElementById('usersTable');
  tb.innerHTML = users.map(u => `
    <tr>
      <td>${u.phoneNumber}</td>
      <td>${u.name || '—'}</td>
      <td>${badge(u.role)}</td>
      <td>${u.isVerified ? '<span class="badge badge-success">Yes</span>' : '<span class="badge badge-muted">No</span>'}</td>
      <td>${fmt(u.createdAt)}</td>
      <td>
        <div class="table-actions">
          <select class="select-input" style="padding:4px 8px;font-size:12px" onchange="updateUserRole('${u._id}',this.value)">
            <option value="">Change Role</option>
            <option value="user">User</option>
            <option value="scanner">Scanner</option>
            <option value="admin">Admin</option>
          </select>
        </div>
      </td>
    </tr>`).join('');
}

function renderTicketTable(tickets) {
  const tb = document.getElementById('ticketsTable');
  tb.innerHTML = tickets.map(t => `
    <tr>
      <td style="font-family:monospace;font-size:11px;color:var(--muted)">${String(t._id).slice(-8)}</td>
      <td>${t.userId?.phoneNumber || t.userId || '—'}</td>
      <td>${t.eventId?.name || '—'}</td>
      <td>${badge(t.type)}</td>
      <td>${t.category}</td>
      <td>${badge(t.status)}</td>
      <td>${t.type === 'season' ? badge(t.verificationStatus || 'pending') : '—'}</td>
      <td>₹${t.totalAmount || 0}</td>
    </tr>`).join('');
}

// ── API Health Check ─────────────────────────────────────────────
async function checkApiStatus() {
  const dot  = document.querySelector('.status-dot');
  const text = document.getElementById('apiStatusText');
  try {
    await fetch(API + '/events', { signal: AbortSignal.timeout(3000) });
    dot.style.background = 'var(--green)';
    dot.style.boxShadow  = '0 0 8px var(--green)';
    text.textContent = 'Connected';
  } catch {
    dot.style.background = '#FF4444';
    dot.style.boxShadow  = '0 0 8px #FF4444';
    text.textContent = 'Offline';
  }
}

// ── Init ─────────────────────────────────────────────────────────
// ── Image Upload ─────────────────────────────────────────────
document.getElementById('eventImageFile').addEventListener('change', async (e) => {
  const file = e.target.files[0];
  if (!file) return;

  const formData = new FormData();
  formData.append('image', file);

  try {
    showToast('📤 Uploading image...', 'info');
    const res = await fetch(API + '/events/upload', {
      method: 'POST',
      body: formData
    });
    const data = await res.json();
    if (data.url) {
      document.getElementById('eventImageUrl').value = data.url;
      document.getElementById('previewImg').src = API.replace('/api', '') + data.url;
      document.getElementById('imagePreview').style.display = 'block';
      showToast('✅ Image uploaded!');
    }
  } catch (err) {
    showToast('❌ Upload failed', 'error');
  }
});

window.addEventListener('DOMContentLoaded', () => {
  checkApiStatus();
  setInterval(checkApiStatus, 15000);
  loadDashboard();
});

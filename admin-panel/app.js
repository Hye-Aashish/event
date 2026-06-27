// ── Config ────────────────────────────────────────────────────────
// In local development, we point to localhost.
// In production, change this to your actual Render backend URL (e.g. https://event-backend.onrender.com/api)
const API = window.location.hostname.includes('localhost') || window.location.hostname.includes('127.0.0.1')
  ? 'http://localhost:3000/api'
  : 'https://navratri-app-backend.onrender.com/api'; // <-- REPLACE with your live Render backend URL!
let allEvents = [];

// ── Utility ──────────────────────────────────────────────────────
async function apiFetch(path, opts = {}) {
  const token = localStorage.getItem('admin_token');
  const headers = { 'Content-Type': 'application/json' };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  try {
    const res = await fetch(API + path, {
      headers,
      ...opts,
    });
    if (!res.ok) {
      if (res.status === 401) {
        adminLogout();
      }
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
    approve: 'badge-success', rejected: 'badge-danger', none: 'badge-muted',
    active: 'badge-success', published: 'badge-success', approved: 'badge-success',
    pending: 'badge-warning', draft: 'badge-warning',
    used: 'badge-info', season: 'badge-info', regular: 'badge-muted',
    expired: 'badge-muted', transferred: 'badge-muted', cancelled: 'badge-muted',
    success: 'badge-success', duplicate: 'badge-warning', invalid_sig: 'badge-danger',
    fraud: 'badge-danger', time_invalid: 'badge-warning',
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
    {
      dashboard: 'Dashboard', events: 'Events', zones: 'Zones', tickets: 'Tickets',
      users: 'Users', verifications: 'Verifications', sponsors: 'Sponsors', scanlogs: 'Scan Logs',
      logs: 'Activity Logs', scanners: 'Scanners', settings: 'Settings'
    }[page];

  const loaders = {
    events: loadEvents,
    zones: async () => { await ensureEventsLoaded(); loadZones(); },
    tickets: async () => { await ensureEventsLoaded(); loadTickets(); },
    sponsors: async () => { await ensureEventsLoaded(); loadSponsors(); },
    scanlogs: async () => { await ensureEventsLoaded(); loadScanLogs(); },
    users: loadUsers,
    verifications: loadVerifications,
    logs: () => switchLogTab(currentLogTab),
    scanners: loadScanners,
    dashboard: loadDashboard,
    settings: loadSettings
  };
  if (loaders[page]) loaders[page]();
}

// ── Dashboard ─────────────────────────────────────────────────────
async function loadDashboard() {
  try {
    const [events, adminStats] = await Promise.allSettled([
      apiFetch('/events/all-admin'),
      apiFetch('/admin/stats'),
    ]);

    const evts = events.status === 'fulfilled' ? events.value : [];
    allEvents = evts;

    document.getElementById('stat-events').textContent = evts.length;

    if (adminStats.status === 'fulfilled') {
      const s = adminStats.value;
      document.getElementById('stat-tickets').textContent = s.totalTickets ?? '--';
      document.getElementById('stat-users').textContent = s.totalUsers ?? '--';
      document.getElementById('stat-scans').textContent = s.totalScans ?? '--';
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
  } catch (e) { }
}

// ── Events ────────────────────────────────────────────────────────
async function loadEvents() {
  const tb = document.getElementById('eventsTable');
  tb.innerHTML = '<tr><td colspan="6" class="loading">Loading...</td></tr>';
  try {
    const events = await apiFetch('/events/all-admin');
    allEvents = events;
    populateEventDropdowns(events);
    if (!events.length) {
      tb.innerHTML = '<tr><td colspan="6" class="loading">No events yet. Click + New Event</td></tr>';
      return;
    }
    tb.innerHTML = events.map(e => `
      <tr>
        <td><strong>${e.name}</strong><br><small style="color:var(--muted)">${e.description?.slice(0, 40) || ''}</small></td>
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
    ['eventName', 'eventVenue', 'eventDesc', 'eventDates', 'eventGst', 'eventMaxSponsor',
      'priceRegularVIP', 'priceRegularGeneral', 'priceRegularPremium',
      'priceSeasonVIP', 'priceSeasonGeneral', 'priceSeasonPremium'].forEach(id => {
        document.getElementById(id).value = '';
      });
    document.getElementById('eventStatus').value = 'draft';
    document.getElementById('eventGstEnabled').value = 'false';
    document.getElementById('eventGstInclusive').value = 'false';
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
    document.getElementById('eventName').value = e.name || '';
    document.getElementById('eventVenue').value = e.venue || '';
    document.getElementById('eventDesc').value = e.description || '';
    document.getElementById('eventDates').value = (e.eventDates || []).join(',');
    document.getElementById('eventStatus').value = e.status || 'draft';
    document.getElementById('eventGstEnabled').value = String(e.gstEnabled || false);
    document.getElementById('eventGstInclusive').value = String(e.gstInclusive || false);
    document.getElementById('eventGst').value = e.gstPercentage || 18;
    document.getElementById('eventMaxSponsor').value = e.maxSponsorTickets || 0;
    document.getElementById('priceRegularVIP').value = e.ticketPricing?.regular?.VIP || '';
    document.getElementById('priceRegularGeneral').value = e.ticketPricing?.regular?.General || '';
    document.getElementById('priceRegularPremium').value = e.ticketPricing?.regular?.Premium || '';
    document.getElementById('priceSeasonVIP').value = e.ticketPricing?.season?.VIP || '';
    document.getElementById('priceSeasonGeneral').value = e.ticketPricing?.season?.General || '';
    document.getElementById('priceSeasonPremium').value = e.ticketPricing?.season?.Premium || '';

    if (e.imageUrl) {
      document.getElementById('eventImageUrl').value = e.imageUrl;
      document.getElementById('previewImg').src = API.replace('/api', '') + e.imageUrl;
      document.getElementById('imagePreview').style.display = 'block';
    } else {
      document.getElementById('imagePreview').style.display = 'none';
    }

    openModal('eventModal');
  } catch (e) {
    showToast('❌ Failed to load event details', 'error');
  }
}

async function saveEvent() {
  const id = document.getElementById('editEventId').value;
  const body = {
    name: document.getElementById('eventName').value,
    venue: document.getElementById('eventVenue').value,
    description: document.getElementById('eventDesc').value,
    eventDates: document.getElementById('eventDates').value.split(',').map(d => d.trim()).filter(Boolean),
    imageUrl: document.getElementById('eventImageUrl').value,
    status: document.getElementById('eventStatus').value,
    gstEnabled: document.getElementById('eventGstEnabled').value === 'true',
    gstInclusive: document.getElementById('eventGstInclusive').value === 'true',
    gstPercentage: Number(document.getElementById('eventGst').value),
    maxSponsorTickets: Number(document.getElementById('eventMaxSponsor').value),
    ticketPricing: {
      regular: {
        VIP: Number(document.getElementById('priceRegularVIP').value) || 0,
        General: Number(document.getElementById('priceRegularGeneral').value) || 0,
        Premium: Number(document.getElementById('priceRegularPremium').value) || 0,
      },
      season: {
        VIP: Number(document.getElementById('priceSeasonVIP').value) || 0,
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
  } catch { }
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
              <div style="width:${Math.min(100, (z.currentCount / z.capacity) * 100) || 0}%;height:100%;background:linear-gradient(90deg,var(--pink),var(--purple))"></div>
            </div>
            <span style="font-size:12px">${z.currentCount}/${z.capacity}</span>
          </div>
        </td>
        <td>
          <div style="font-size: 12px;">
            ${z.dailyPrice ? `D: ₹${z.dailyPrice}` : ''}
            ${z.seasonPrice ? `${z.dailyPrice ? '<br>' : ''}S: ₹${z.seasonPrice}` : ''}
            ${!z.dailyPrice && !z.seasonPrice ? '—' : ''}
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

function openZoneModal(reset = true) {
  if (reset) {
    document.getElementById('editZoneId').value = '';
    document.getElementById('zoneName').value = '';
    document.getElementById('zoneEventId').value = '';
    document.getElementById('zoneCapacity').value = '';
    document.getElementById('zoneDailyPrice').value = '';
    document.getElementById('zoneSeasonPrice').value = '';
    document.getElementById('zoneType').value = 'daily';
    document.getElementById('zoneColor').value = '#FF0080';
    document.getElementById('zoneAutoVerify').value = 'false';
    document.getElementById('zoneIsMultipleAllowed').value = 'true';
    document.getElementById('zoneCategories').value = '';
  }
  openModal('zoneModal');
}

async function saveZone() {
  const body = {
    name: document.getElementById('zoneName').value,
    eventId: document.getElementById('zoneEventId').value,
    capacity: Number(document.getElementById('zoneCapacity').value),
    availableSeats: Number(document.getElementById('zoneCapacity').value),
    dailyPrice: Number(document.getElementById('zoneDailyPrice').value),
    seasonPrice: Number(document.getElementById('zoneSeasonPrice').value),
    type: document.getElementById('zoneType').value,
    color: document.getElementById('zoneColor').value,
    autoVerifySeasonPass: document.getElementById('zoneAutoVerify').value === 'true',
    isMultipleAllowed: document.getElementById('zoneIsMultipleAllowed').value === 'true',
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
  } catch { }
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
    document.getElementById('zoneDailyPrice').value = z.dailyPrice || 0;
    document.getElementById('zoneSeasonPrice').value = z.seasonPrice || 0;
    document.getElementById('zoneType').value = z.type || 'daily';
    document.getElementById('zoneColor').value = z.color || '#FF0080';
    document.getElementById('zoneAutoVerify').value = String(z.autoVerifySeasonPass);
    document.getElementById('zoneIsMultipleAllowed').value = z.isMultipleAllowed !== false ? 'true' : 'false';
    document.getElementById('zoneCategories').value = (z.allowedTicketCategories || []).join(',');
    openModal('zoneModal');
  } catch { }
}

// ── Tickets ──────────────────────────────────────────────────────
async function loadTickets() {
  const tb = document.getElementById('ticketsTable');
  tb.innerHTML = '<tr><td colspan="8" class="loading">Loading...</td></tr>';
  try {
    const eventId = document.getElementById('ticketEventFilter').value;
    const type = document.getElementById('ticketTypeFilter').value;
    const status = document.getElementById('ticketStatusFilter').value;

    let params = new URLSearchParams();
    if (eventId) params.append('eventId', eventId);
    if (type) params.append('type', type);
    if (status) params.append('status', status);

    const tickets = await apiFetch(`/tickets/all?${params.toString()}`);
    allTickets = tickets;
    renderTicketTable(tickets);
  } catch { tb.innerHTML = '<tr><td colspan="11" class="loading">Failed to load</td></tr>'; }
}

async function verifyTicketAction(ticketId) {
  if (!confirm('Mark this season pass as verified?')) return;
  try {
    await apiFetch(`/admin/tickets/${ticketId}/verify`, { method: 'PATCH' });
    showToast('✅ Ticket verified successfully!');
    loadTickets();
  } catch (e) { }
}

// ── Users ─────────────────────────────────────────────────────────
async function loadUsers() {
  const tb = document.getElementById('usersTable');
  tb.innerHTML = '<tr><td colspan="7" class="loading">Loading...</td></tr>';
  try {
    const users = await apiFetch('/admin/users');
    allUsers = users;
    filterUsers();
  } catch { tb.innerHTML = '<tr><td colspan="7" class="loading">Failed to load</td></tr>'; }
}

async function updateUserRole(id, role) {
  if (!role) return;
  try {
    await apiFetch(`/admin/users/${id}/role`, { method: 'PUT', body: JSON.stringify({ role }) });
    showToast('✅ Role updated!');
    loadUsers();
  } catch { }
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
    name: document.getElementById('sponsorName').value,
    contactName: document.getElementById('sponsorContact').value,
    phone: document.getElementById('sponsorPhone').value,
    email: document.getElementById('sponsorEmail').value,
    eventId: document.getElementById('sponsorEventId').value,
    limitType: document.getElementById('sponsorLimitType').value,
    ticketQuota: Number(document.getElementById('sponsorQuota').value),
    creditLimit: Number(document.getElementById('sponsorCredit').value),
  };
  try {
    await apiFetch('/sponsors', { method: 'POST', body: JSON.stringify(body) });
    showToast('🤝 Sponsor created!');
    closeModal('sponsorModal');
    loadSponsors();
  } catch { }
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
  tb.innerHTML = '<tr><td colspan="7" class="loading">Loading logs...</td></tr>';
  try {
    const params = new URLSearchParams();
    params.append('type', 'scan');
    if (eventId) {
      params.append('eventId', eventId);
    }
    const logs = await apiFetch(`/admin/logs?${params.toString()}`);
    if (!logs.length) {
      tb.innerHTML = '<tr><td colspan="7" class="loading">No scan logs found</td></tr>';
      return;
    }
    tb.innerHTML = logs.map(l => {
      const ownerName = l.ticketId?.userId?.name || '—';
      const ownerPhone = l.ticketId?.userId?.phoneNumber || '—';

      let scannerName = '—';
      let scannerPhone = '—';
      if (l.scannerId) {
        if (typeof l.scannerId === 'object') {
          scannerName = l.scannerId.name || 'Scanner';
          scannerPhone = l.scannerId.phoneNumber || '—';
        } else if (typeof l.scannerId === 'string') {
          const foundUser = allUsers.find(u => u._id === l.scannerId);
          if (foundUser) {
            scannerName = foundUser.name || 'Scanner';
            scannerPhone = foundUser.phoneNumber || '—';
          } else {
            scannerName = 'Scanner (' + l.scannerId.slice(-4) + ')';
          }
        }
      }

      return `
        <tr>
          <td>${fmt(l.createdAt)}</td>
          <td>
            <strong>${ownerName}</strong><br>
            <small style="color:var(--muted)">${ownerPhone}</small>
          </td>
          <td>
            <strong>${scannerName}</strong><br>
            <small style="color:var(--muted)">${scannerPhone}</small>
          </td>
          <td>${badge(l.status)}</td>
          <td>${l.zoneId?.name || '—'}</td>
          <td>${l.eventId?.name || '—'}</td>
          <td style="color:var(--muted);font-size:12px">${l.message || '—'}</td>
        </tr>
      `;
    }).join('');
  } catch (e) {
    tb.innerHTML = `<tr><td colspan="7" class="loading" style="color:var(--error)">Failed to load logs: ${e.message}</td></tr>`;
  }
}

// ── Verifications ────────────────────────────────────────────────
let pendingVerifications = [];
async function loadVerifications() {
  const tb = document.getElementById('verificationsTable');
  tb.innerHTML = '<tr><td colspan="4" class="loading">Loading...</td></tr>';
  try {
    const data = await apiFetch('/admin/verifications');
    pendingVerifications = data;
    if (!data.length) {
      tb.innerHTML = '<tr><td colspan="4" class="loading">No pending verifications.</td></tr>';
      return;
    }
    tb.innerHTML = data.map(u => `
      <tr>
        <td><strong>${u.name || 'Guest'}</strong></td>
        <td>${u.phoneNumber || u.phone}</td>
        <td>${fmt(u.updatedAt)}</td>
        <td>
          <button class="btn btn-sm btn-primary" onclick="openVerifyDetail('${u._id}')">👁️ Review</button>
        </td>
      </tr>`).join('');
  } catch (e) {
    tb.innerHTML = '<tr><td colspan="4" class="loading">Failed to load verifications</td></tr>';
  }
}

function openVerifyDetail(userId) {
  const user = pendingVerifications.find(u => u._id === userId);
  if (!user) return;

  document.getElementById('verifyUserId').value = user._id;
  document.getElementById('verifyReason').value = '';

  const baseUrl = API.replace('/api', '');
  document.getElementById('selfieImg').src = baseUrl + user.verificationSelfie;
  document.getElementById('idCardImg').src = baseUrl + user.verificationIdCard;

  openModal('verifyDetailModal');
}

async function updateUserVerification(status) {
  const id = document.getElementById('verifyUserId').value;
  const reason = document.getElementById('verifyReason').value;

  if (status === 'rejected' && !reason) {
    showToast('⚠️ Please provide a reason for rejection', 'error');
    return;
  }

  try {
    await apiFetch(`/admin/verifications/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status, reason })
    });

    showToast(`✅ User verification ${status}!`);
    closeModal('verifyDetailModal');
    loadVerifications();
  } catch (e) { }
}

async function updateSettings(body) {
  try {
    await apiFetch('/admin/settings', { method: 'PATCH', body: JSON.stringify(body) });
    showToast('⚙️ Settings updated!');
  } catch { }
}

async function loadSettings() {
  try {
    const s = await apiFetch('/admin/settings');
    if (s) {
      document.getElementById('setRazorpayKeyId').value = s.razorpayKeyId || '';
      document.getElementById('setRazorpayKeySecret').value = s.razorpayKeySecret || '';
      document.getElementById('setDefaultGst').value = s.defaultGstPercentage || 18;
      document.getElementById('setMaxTicketsPerOrder').value = s.maxTicketsPerOrder || 10;
    } else {
      console.warn('Settings not found on server');
    }
  } catch (e) {
    console.error('Failed to load settings:', e);
    showToast('❌ Failed to load settings', 'error');
  }
}

async function saveSettings() {
  const body = {
    razorpayKeyId: document.getElementById('setRazorpayKeyId').value,
    razorpayKeySecret: document.getElementById('setRazorpayKeySecret').value,
    defaultGstPercentage: Number(document.getElementById('setDefaultGst').value),
    maxTicketsPerOrder: Number(document.getElementById('setMaxTicketsPerOrder').value) || 10,
  };
  await updateSettings(body);
}

function zoomImage(src) {
  window.open(src, '_blank');
}

let eventsLoadedPromise = null;
async function ensureEventsLoaded() {
  if (allEvents && allEvents.length) {
    populateEventDropdowns(allEvents);
    return allEvents;
  }
  if (!eventsLoadedPromise) {
    eventsLoadedPromise = apiFetch('/events/all-admin')
      .then(events => {
        allEvents = events;
        populateEventDropdowns(events);
        eventsLoadedPromise = null;
        return events;
      })
      .catch(err => {
        eventsLoadedPromise = null;
        throw err;
      });
  }
  return eventsLoadedPromise;
}

// ── Dropdown Helper ──────────────────────────────────────────────
function populateEventDropdowns(events) {
  const dropdowns = ['zoneEventFilter', 'zoneEventId', 'sponsorEventId', 'ticketEventFilter', 'scanEventFilter'];
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
  const q = document.getElementById('userSearch').value.toLowerCase().trim();
  const role = document.getElementById('userRoleFilter').value;
  const filtered = allUsers.filter(u => {
    const matchesQuery = u.phoneNumber.toLowerCase().includes(q) ||
      (u.name && u.name.toLowerCase().includes(q)) ||
      (u.email && u.email.toLowerCase().includes(q));
    const matchesRole = !role || u.role === role;
    return matchesQuery && matchesRole;
  });
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
  if (!users.length) {
    tb.innerHTML = '<tr><td colspan="7" class="loading">No users found</td></tr>';
    return;
  }
  tb.innerHTML = users.map(u => `
    <tr>
      <td>${u.phoneNumber}</td>
      <td>${u.name || '—'}</td>
      <td>${u.email || '—'}</td>
      <td>${badge(u.role)}</td>
      <td>${u.isVerified ? '<span class="badge badge-success">Yes</span>' : '<span class="badge badge-muted">No</span>'}</td>
      <td>${fmt(u.createdAt)}</td>
      <td>
        <div class="table-actions">
          <button class="btn btn-sm btn-primary" onclick="openUserDetail('${u._id}')" style="padding:4px 8px;font-size:12px">👁️ Details</button>
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
}

function renderTicketTable(tickets) {
  const tb = document.getElementById('ticketsTable');

  if (!tickets.length) {
    tb.innerHTML = '<tr><td colspan="11" class="loading">No tickets found</td></tr>';
    return;
  }

  tb.innerHTML = tickets.map(t => {
    const qty = t.quantity || 1;
    const needsVerification = t.type === 'season' && t.verificationStatus !== 'approved';

    return `
      <tr>
        <td style="font-family:monospace;font-size:11px;color:var(--muted)">
          ${String(t._id).slice(-8)}
        </td>
        <td>${t.currentOwner?.phoneNumber || t.userId?.phoneNumber || t.currentOwner || t.userId || '—'}</td>
        <td>${t.eventId?.name || '—'}</td>
        <td>${t.zoneId?.name || '—'}</td>
        <td>${badge(t.type)}</td>
        <td>${t.category}</td>
        <td>${badge(t.status)}</td>
        <td>${t.type === 'season' ? badge(t.verificationStatus || 'pending') : '—'}</td>
        <td>
          <span class="badge ${qty > 1 ? 'badge-info' : 'badge-muted'}">${qty}x</span>
        </td>
        <td>
          <strong>₹${t.totalAmount || 0}</strong>
          ${t.basePrice || t.gstAmount ? `<br><small style="color:var(--muted);font-size:10px;display:block;margin-top:2px">Base: ₹${t.basePrice || 0} | GST: ₹${t.gstAmount || 0}</small>` : ''}
        </td>
        <td>
          ${needsVerification
        ? `<button class="btn btn-sm btn-success" onclick="verifyTicketAction('${t._id}')">Verify</button>`
        : '—'}
        </td>
      </tr>`;
  }).join('');
}

// ── API Health Check ─────────────────────────────────────────────
async function checkApiStatus() {
  const dot = document.querySelector('.status-dot');
  const text = document.getElementById('apiStatusText');
  try {
    await fetch(API + '/events', { signal: AbortSignal.timeout(3000) });
    dot.style.background = 'var(--green)';
    dot.style.boxShadow = '0 0 8px var(--green)';
    text.textContent = 'Connected';
  } catch {
    dot.style.background = '#FF4444';
    dot.style.boxShadow = '0 0 8px #FF4444';
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

  const token = localStorage.getItem('admin_token');
  const headers = {};
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  try {
    showToast('📤 Uploading image...', 'info');
    const res = await fetch(API + '/events/upload', {
      method: 'POST',
      headers,
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

// ── Admin Login/Logout ─────────────────────────────────────────────
function showPhoneStep() {
  document.getElementById('loginStepPhone').style.display = 'block';
  document.getElementById('loginStepOtp').style.display = 'none';
}

async function sendAdminOtp() {
  const phone = document.getElementById('loginPhone').value.trim();
  if (!phone || phone.length < 10) {
    showToast('⚠️ Enter a valid 10-digit number', 'error');
    return;
  }
  try {
    showToast('📤 Requesting OTP...', 'info');
    const res = await fetch(API + '/auth/send-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone: '+91' + phone })
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'Failed to send OTP');
    }
    document.getElementById('adminOtpPhone').textContent = '+91' + phone;
    document.getElementById('loginStepPhone').style.display = 'none';
    document.getElementById('loginStepOtp').style.display = 'block';
    showToast('📱 OTP sent to ' + phone);
  } catch (e) {
    showToast('❌ ' + e.message, 'error');
  }
}

async function verifyAdminOtp() {
  const phone = document.getElementById('loginPhone').value.trim();
  const otp = document.getElementById('loginOtp').value.trim();
  if (!otp || otp.length < 6) {
    showToast('⚠️ Enter a valid 6-digit OTP', 'error');
    return;
  }
  try {
    showToast('🔑 Verifying OTP...', 'info');
    const res = await fetch(API + '/auth/verify-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone: '+91' + phone, otp })
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || 'OTP verification failed');
    }
    const data = await res.json();
    if (data.user?.role !== 'admin') {
      showToast('❌ Access Denied: Administrator role required', 'error');
      return;
    }
    localStorage.setItem('admin_token', data.access_token);
    localStorage.setItem('admin_user', JSON.stringify(data.user));
    document.getElementById('loginOverlay').style.display = 'none';
    document.getElementById('adminNameDisplay').textContent = data.user.name || 'Admin';
    showToast('🔓 Access Granted. Welcome!');
    loadDashboard();
  } catch (e) {
    showToast('❌ ' + e.message, 'error');
  }
}

// ── Analytics & Activity Logs State & Logic ──────────────────────
let currentLogTab = 'scan';
let currentUserDetailData = null;
let currentScannerDetailData = null;

function closeDetailPanel(id) {
  document.getElementById(id).classList.remove('open');
}

function switchLogTab(tab) {
  currentLogTab = tab;
  document.querySelectorAll('#logTabBar .tab-btn').forEach(btn => btn.classList.remove('active'));
  document.getElementById(`logTab-${tab}`).classList.add('active');

  // Update table headers based on tab
  const head = document.getElementById('logsTableHead').querySelector('tr');
  if (tab === 'scan') {
    head.innerHTML = `
      <th>Time</th>
      <th>Ticket Owner</th>
      <th>Scanner</th>
      <th>Status</th>
      <th>Zone</th>
      <th>Event</th>
      <th>Message</th>
    `;
  } else if (tab === 'transfer') {
    head.innerHTML = `
      <th>Time</th>
      <th>Passes (Qty)</th>
      <th>From User</th>
      <th>To User</th>
      <th>Event · Zone</th>
      <th>Type</th>
      <th>OTP Verified</th>
    `;
  } else if (tab === 'purchase') {
    head.innerHTML = `
      <th>Time</th>
      <th>User</th>
      <th>Event · Zone</th>
      <th>Type</th>
      <th>Qty</th>
      <th>Total Amount</th>
      <th>Status</th>
    `;
  } else if (tab === 'admin') {
    head.innerHTML = `
      <th>Time</th>
      <th>Admin</th>
      <th>Action</th>
      <th>Target Resource</th>
      <th>Changes</th>
    `;
  } else if (tab === 'auth') {
    head.innerHTML = `
      <th>Time</th>
      <th>User</th>
      <th>Role</th>
      <th>Event</th>
      <th>IP Address</th>
      <th>Device</th>
    `;
  }

  loadCurrentLogTab();
}

function resolveUserIdFilter(queryText) {
  if (!queryText) return '';
  const q = queryText.toLowerCase().trim();
  const found = allUsers.find(u =>
    u._id.toLowerCase() === q ||
    u.phoneNumber.toLowerCase().includes(q) ||
    (u.name && u.name.toLowerCase().includes(q))
  );
  return found ? found._id : queryText;
}

async function loadCurrentLogTab() {
  const tb = document.getElementById('logsTableBody');
  if (!tb) return;
  tb.innerHTML = '<tr><td colspan="6" class="loading">Loading logs...</td></tr>';

  const userFilterText = document.getElementById('logUserFilter').value;
  const role = document.getElementById('logRoleFilter').value;
  const dateFrom = document.getElementById('logDateFrom').value;
  const dateTo = document.getElementById('logDateTo').value;

  let userId = '';
  if (userFilterText) {
    userId = resolveUserIdFilter(userFilterText);
  }

  if (currentLogTab === 'purchase') {
    // Show tickets grouped by razorpayOrderId as purchase events
    try {
      const allTickets = await apiFetch('/tickets/all');

      // Group by order
      const orderMap = {};
      allTickets.forEach(t => {
        const key = t.razorpayOrderId || t._id;
        if (!orderMap[key]) {
          orderMap[key] = { ...t, qty: 0, totalAmt: 0 };
        }
        orderMap[key].qty += t.quantity || 1;
        orderMap[key].totalAmt += t.totalAmount || 0;
      });

      let orders = Object.values(orderMap);

      // Apply client-side filters (User, Dates)
      if (userId) {
        orders = orders.filter(o => {
          const ownerId = o.currentOwner?._id || o.currentOwner || o.userId?._id || o.userId;
          return ownerId === userId;
        });
      }
      if (dateFrom) {
        const fromTime = new Date(dateFrom).getTime();
        orders = orders.filter(o => new Date(o.createdAt).getTime() >= fromTime);
      }
      if (dateTo) {
        const toTime = new Date(dateTo + 'T23:59:59Z').getTime();
        orders = orders.filter(o => new Date(o.createdAt).getTime() <= toTime);
      }

      orders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

      if (!orders.length) {
        tb.innerHTML = `<tr><td colspan="7" class="loading">No purchases found matching filters</td></tr>`;
        return;
      }

      tb.innerHTML = orders.map(o => `
        <tr>
          <td>${fmt(o.createdAt)}</td>
          <td>
            <strong>${o.currentOwner?.name || o.userId?.name || '—'}</strong><br>
            <small style="color:var(--muted)">${o.currentOwner?.phoneNumber || o.userId?.phoneNumber || '—'}</small>
          </td>
          <td style="font-size:12px">${o.eventId?.name || '—'} · ${o.zoneId?.name || '—'}</td>
          <td>${badge(o.type)}</td>
          <td><span class="badge ${o.qty > 1 ? 'badge-info' : 'badge-muted'}">${o.qty}x</span></td>
          <td><strong>₹${o.totalAmt}</strong></td>
          <td>${badge(o.status)}</td>
        </tr>`).join('');
    } catch (e) {
      tb.innerHTML = `<tr><td colspan="7" class="loading" style="color:var(--error)">Failed to load purchases: ${e.message}</td></tr>`;
    }
    return;
  }

  const params = new URLSearchParams();
  params.append('type', currentLogTab);
  if (userId) params.append('userId', userId);
  if (role) params.append('role', role);
  if (dateFrom) params.append('dateFrom', dateFrom);
  if (dateTo) params.append('dateTo', dateTo);

  try {
    const logs = await apiFetch(`/admin/logs?${params.toString()}`);
    if (!logs.length) {
      tb.innerHTML = `<tr><td colspan="7" class="loading">No logs found matching filters</td></tr>`;
      return;
    }

    if (currentLogTab === 'scan') {
      tb.innerHTML = logs.map(l => {
        const ownerName = l.ticketId?.userId?.name || '—';
        const ownerPhone = l.ticketId?.userId?.phoneNumber || '—';

        let scannerName = '—';
        let scannerPhone = '—';
        if (l.scannerId) {
          if (typeof l.scannerId === 'object') {
            scannerName = l.scannerId.name || 'Scanner';
            scannerPhone = l.scannerId.phoneNumber || '—';
          } else if (typeof l.scannerId === 'string') {
            const foundUser = allUsers.find(u => u._id === l.scannerId);
            if (foundUser) {
              scannerName = foundUser.name || 'Scanner';
              scannerPhone = foundUser.phoneNumber || '—';
            } else {
              scannerName = 'Scanner (' + l.scannerId.slice(-4) + ')';
            }
          }
        }

        return `
          <tr>
            <td>${fmt(l.createdAt)}</td>
            <td>
              <strong>${ownerName}</strong><br>
              <small style="color:var(--muted)">${ownerPhone}</small>
            </td>
            <td>
              <strong>${scannerName}</strong><br>
              <small style="color:var(--muted)">${scannerPhone}</small>
            </td>
            <td>${badge(l.status)}</td>
            <td>${l.zoneId?.name || '—'}</td>
            <td>${l.eventId?.name || '—'}</td>
            <td style="color:var(--muted);font-size:12px">${l.message || '—'}</td>
          </tr>
        `;
      }).join('');
    } else if (currentLogTab === 'transfer') {
      tb.innerHTML = logs.map(l => {
        const qty = l.metadata?.quantity || 1;
        const isBatch = qty > 1;
        const otpVerified = l.metadata?.otpVerified !== false;
        return `
          <tr>
            <td>${fmt(l.createdAt)}</td>
            <td>
              ${isBatch
            ? `<span class="badge badge-info">${qty} Passes (batch)</span>`
            : `<span class="badge badge-muted">1 Pass</span>`}
            </td>
            <td>
              <strong>${l.fromUserId?.name || '—'}</strong><br>
              <small style="color:var(--muted)">${l.fromUserId?.phoneNumber || '—'}</small>
            </td>
            <td>
              <strong>${l.toUserId?.name || '—'}</strong><br>
              <small style="color:var(--muted)">${l.toUserId?.phoneNumber || l.toPhone || '—'}</small>
            </td>
            <td style="font-size:12px">${l.ticketId?.eventId?.name || '—'} · ${l.ticketId?.zoneId?.name || l.ticketId?.category || '—'}</td>
            <td>${badge(l.ticketId?.type || '—')}</td>
            <td>${otpVerified ? '<span class="badge badge-success">Yes</span>' : '<span class="badge badge-muted">No</span>'}</td>
          </tr>
        `;
      }).join('');
    } else if (currentLogTab === 'admin') {
      tb.innerHTML = logs.map(l => `
        <tr>
          <td>${fmt(l.createdAt)}</td>
          <td>
            <strong>${l.adminId?.name || 'Admin'}</strong><br>
            <small style="color:var(--muted)">${l.adminId?.phoneNumber || '—'}</small>
          </td>
          <td><span class="badge badge-log-admin">${l.action}</span></td>
          <td>
            <span style="color:var(--muted);font-size:11px">${l.targetType || '—'}</span><br>
            <strong>${l.targetName || l.targetId || '—'}</strong>
          </td>
          <td>${formatChanges(l.changes)}</td>
        </tr>
      `).join('');
    } else if (currentLogTab === 'auth') {
      tb.innerHTML = logs.map(l => `
        <tr>
          <td>${fmt(l.createdAt)}</td>
          <td>
            <strong>${l.userId?.name || '—'}</strong><br>
            <small style="color:var(--muted)">${l.userId?.phoneNumber || l.phone || '—'}</small>
          </td>
          <td>${badge(l.role || l.userId?.role)}</td>
          <td><span class="badge ${getAuthEventBadgeClass(l.event)}">${l.event}</span></td>
          <td>${l.ipAddress || '—'}</td>
          <td style="font-size:11px;color:var(--muted)">${l.deviceId || '—'}</td>
        </tr>
      `).join('');
    }
  } catch (e) {
    tb.innerHTML = `<tr><td colspan="6" class="loading" style="color:var(--error)">Failed to load logs: ${e.message}</td></tr>`;
  }
}

function clearLogFilters() {
  document.getElementById('logUserFilter').value = '';
  document.getElementById('logRoleFilter').value = '';
  document.getElementById('logDateFrom').value = '';
  document.getElementById('logDateTo').value = '';
  loadCurrentLogTab();
}

function formatChanges(changes) {
  if (!changes) return '—';
  try {
    let html = '<div style="font-size:11px; max-width: 300px; overflow-x: auto;">';
    if (changes.before && changes.after) {
      for (const k of Object.keys(changes.after)) {
        const beforeVal = typeof changes.before[k] === 'object' ? JSON.stringify(changes.before[k]) : changes.before[k];
        const afterVal = typeof changes.after[k] === 'object' ? JSON.stringify(changes.after[k]) : changes.after[k];
        html += `<div><strong>${k}</strong>: <span style="color:var(--muted);text-decoration:line-through">${beforeVal !== undefined ? beforeVal : 'none'}</span> ➔ <span style="color:var(--green)">${afterVal}</span></div>`;
      }
    } else {
      html += `<pre style="margin:0">${JSON.stringify(changes, null, 2)}</pre>`;
    }
    html += '</div>';
    return html;
  } catch (e) {
    return '—';
  }
}

function getAuthEventBadgeClass(event) {
  const map = {
    login_success: 'badge-login',
    logout: 'badge-logout',
    otp_requested: 'badge-otp-req',
    otp_failed: 'badge-otp-fail'
  };
  return map[event] || 'badge-muted';
}

// ── Scanners page ────────────────────────────────────────────────
async function loadScanners() {
  const grid = document.getElementById('scannerGrid');
  if (!grid) return;
  grid.innerHTML = '<div class="loading">Loading scanners...</div>';
  try {
    const scanners = await apiFetch('/admin/scanners');
    if (!scanners.length) {
      grid.innerHTML = '<div class="loading">No scanners found</div>';
      return;
    }

    const cardsHtml = await Promise.all(scanners.map(async s => {
      let stats = { total: 0, success: 0, duplicate: 0, fraud: 0, invalid_sig: 0, time_invalid: 0 };
      try {
        const analytics = await apiFetch(`/admin/analytics/scanner/${s._id}`);
        stats = analytics.summary;
      } catch (err) {
        console.error('Error fetching analytics for scanner ' + s._id, err);
      }

      const successRate = stats.total > 0 ? Math.round((stats.success / stats.total) * 100) : 0;

      return `
        <div class="scanner-card" onclick="openScannerDetail('${s._id}')">
          <div class="scanner-card-head">
            <div class="scanner-card-avatar">📲</div>
            <div>
              <div style="font-weight:700;font-size:15px">${s.name || 'Scanner User'}</div>
              <div style="color:var(--muted);font-size:12px">${s.phoneNumber}</div>
            </div>
          </div>
          <div style="font-size:12px;color:var(--muted);margin-bottom:12px">
            Role: ${badge(s.role)} <br>
            Joined: ${fmt(s.createdAt)}
          </div>
          <div class="scanner-card-stats">
            <div class="scanner-stat">
              <strong>${stats.total}</strong>
              Total Scans
            </div>
            <div class="scanner-stat">
              <strong>${stats.success}</strong>
              Success
            </div>
            <div class="scanner-stat">
              <strong>${successRate}%</strong>
              Success Rate
            </div>
          </div>
        </div>
      `;
    }));

    grid.innerHTML = cardsHtml.join('');
  } catch (e) {
    grid.innerHTML = '<div class="loading">Failed to load scanners</div>';
  }
}

// ── User Detail Slide-In Panel ───────────────────────────────────
// ── User Detail Slide-In Panel ───────────────────────────────────
async function openUserDetail(userId) {
  const user = allUsers.find(u => u._id === userId);
  const overlay = document.getElementById('userDetailOverlay');
  const nameEl = document.getElementById('userDetailName');
  const metaEl = document.getElementById('userDetailMeta');
  const bodyEl = document.getElementById('userDetailBody');

  if (user) {
    nameEl.textContent = user.name || 'User Detail';
    metaEl.textContent = `${user.phoneNumber} · Role: ${user.role.toUpperCase()}`;
  }

  bodyEl.innerHTML = '<div class="loading">Loading analytics & history...</div>';
  overlay.classList.add('open');

  try {
    if (user && (user.role === 'scanner' || user.role === 'zone_manager')) {
      const data = await apiFetch(`/admin/analytics/scanner/${userId}`);
      currentUserDetailData = { role: user.role, user, ...data };

      const sum = data.summary;
      const successRate = sum.total > 0 ? Math.round((sum.success / sum.total) * 100) : 0;

      bodyEl.innerHTML = `
        <div class="profile-info-row">
          <div class="profile-avatar">📲</div>
          <div class="profile-details">
            <div class="profile-name">${user?.name || 'Scanner User'}</div>
            <div class="profile-sub">
              <span>📞 ${user?.phoneNumber}</span>
              <span>📧 ${user?.email || 'No email'}</span>
              <span>📅 Joined: ${fmt(user?.createdAt)}</span>
            </div>
          </div>
        </div>
        
        ${renderAdminManagementCard(user)}
        
        <div class="analytics-grid">
          <div class="analytics-card pink-glow">
            <div class="ac-icon">📡</div>
            <div class="ac-value">${sum.total}</div>
            <div class="ac-label">Total Scans</div>
          </div>
          <div class="analytics-card green-glow">
            <div class="ac-icon">✅</div>
            <div class="ac-value">${sum.success}</div>
            <div class="ac-label">Success Rate (${successRate}%)</div>
          </div>
          <div class="analytics-card orange-glow">
            <div class="ac-icon">⚠️</div>
            <div class="ac-value">${sum.duplicate}</div>
            <div class="ac-label">Duplicates</div>
          </div>
          <div class="analytics-card red-glow">
            <div class="ac-icon">🚫</div>
            <div class="ac-value">${sum.fraud + sum.invalid_sig + sum.time_invalid}</div>
            <div class="ac-label">Fraud/Invalid</div>
          </div>
        </div>
        
        <div class="tab-bar">
          <button class="tab-btn active" id="udTabBtn-scans" onclick="switchUserDetailTab('scans')">📡 Recent Scans (${data.scanLogs.length})</button>
          <button class="tab-btn" id="udTabBtn-auth" onclick="switchUserDetailTab('auth')">🔑 Auth Logs (${data.authLogs.length})</button>
        </div>
        
        <div id="udTabContent" style="margin-top: 15px;">
          ${renderScannerDetailScansHtml(data.scanLogs)}
        </div>
      `;
    } else if (user && user.role === 'admin') {
      const [adminLogs, authLogs] = await Promise.all([
        apiFetch(`/admin/logs?type=admin&userId=${userId}`),
        apiFetch(`/admin/logs?type=auth&userId=${userId}`),
      ]);

      currentUserDetailData = { role: 'admin', user, adminLogs, authLogs };

      bodyEl.innerHTML = `
        <div class="profile-info-row">
          <div class="profile-avatar">🛡️</div>
          <div class="profile-details">
            <div class="profile-name">${user?.name || 'Administrator'}</div>
            <div class="profile-sub">
              <span>📞 ${user?.phoneNumber}</span>
              <span>📧 ${user?.email || 'No email'}</span>
              <span>📅 Joined: ${fmt(user?.createdAt)}</span>
            </div>
          </div>
        </div>
        
        <div class="analytics-grid two-col-grid">
          <div class="analytics-card pink-glow">
            <div class="ac-icon">🛠️</div>
            <div class="ac-value">${adminLogs.length}</div>
            <div class="ac-label">Admin Actions</div>
          </div>
          <div class="analytics-card blue-glow">
            <div class="ac-icon">🔑</div>
            <div class="ac-value">${authLogs.length}</div>
            <div class="ac-label">Logins/Auth Logs</div>
          </div>
        </div>
        
        <div class="tab-bar">
          <button class="tab-btn active" id="udTabBtn-actions" onclick="switchUserDetailTab('actions')">🛡️ Admin Actions (${adminLogs.length})</button>
          <button class="tab-btn" id="udTabBtn-auth" onclick="switchUserDetailTab('auth')">🔑 Auth Logs (${authLogs.length})</button>
        </div>
        
        <div id="udTabContent" style="margin-top: 15px;">
          ${renderAdminDetailActionsHtml(adminLogs)}
        </div>
      `;
    } else {
      const data = await apiFetch(`/admin/analytics/user/${userId}`);
      currentUserDetailData = { role: 'user', user, ...data };

      const sum = data.summary;

      bodyEl.innerHTML = `
        <div class="profile-info-row">
          <div class="profile-avatar">👤</div>
          <div class="profile-details">
            <div class="profile-name">${user?.name || 'Guest User'}</div>
            <div class="profile-sub">
              <span>📞 ${user?.phoneNumber}</span>
              <span>📧 ${user?.email || 'No email'}</span>
              <span>📅 Joined: ${fmt(user?.createdAt)}</span>
              <span>Verified: ${user?.isVerified ? '<span class="badge badge-success">Yes</span>' : '<span class="badge badge-muted">No</span>'}</span>
            </div>
          </div>
        </div>
        
        ${renderAdminManagementCard(user)}
        
        <div class="analytics-grid">
          <div class="analytics-card pink-glow">
            <div class="ac-icon">🎟️</div>
            <div class="ac-value">${sum.totalPurchased}</div>
            <div class="ac-label">Purchased</div>
          </div>
          <div class="analytics-card purple-glow">
            <div class="ac-icon">💸</div>
            <div class="ac-value">₹${sum.totalSpent}</div>
            <div class="ac-label">Total Spent</div>
          </div>
          <div class="analytics-card orange-glow">
            <div class="ac-icon">📤</div>
            <div class="ac-value">${sum.totalTransferredOut}</div>
            <div class="ac-label">Transferred Out</div>
          </div>
          <div class="analytics-card green-glow">
            <div class="ac-icon">📥</div>
            <div class="ac-value">${sum.totalTransferredIn}</div>
            <div class="ac-label">Transferred In</div>
          </div>
        </div>
        
        <div class="tab-bar">
          <button class="tab-btn active" id="udTabBtn-tickets" onclick="switchUserDetailTab('tickets')">🎟️ Current Tickets (${data.currentTickets.length})</button>
          <button class="tab-btn" id="udTabBtn-transfers" onclick="switchUserDetailTab('transfers')">🔄 Transfers</button>
          <button class="tab-btn" id="udTabBtn-auth" onclick="switchUserDetailTab('auth')">🔑 Auth Logs (${data.authLogs.length})</button>
        </div>
        
        <div id="udTabContent" style="margin-top: 15px;">
          ${renderUserDetailTicketsHtml(data.currentTickets)}
        </div>
      `;
    }
  } catch (e) {
    bodyEl.innerHTML = `<div class="loading" style="color:var(--error)">Error loading user details: ${e.message}</div>`;
  }
}

function switchUserDetailTab(tab) {
  if (!currentUserDetailData) return;

  document.querySelectorAll('#userDetailBody .tab-btn').forEach(btn => btn.classList.remove('active'));
  const activeBtn = document.getElementById(`udTabBtn-${tab}`);
  if (activeBtn) activeBtn.classList.add('active');

  const contentEl = document.getElementById('udTabContent');
  if (!contentEl) return;

  if (tab === 'tickets') {
    contentEl.innerHTML = renderUserDetailTicketsHtml(currentUserDetailData.currentTickets);
  } else if (tab === 'transfers') {
    contentEl.innerHTML = renderUserDetailTransfersHtml(currentUserDetailData.transfersOut, currentUserDetailData.transfersIn);
  } else if (tab === 'auth') {
    contentEl.innerHTML = renderUserDetailAuthHtml(currentUserDetailData.authLogs);
  } else if (tab === 'scans') {
    contentEl.innerHTML = renderScannerDetailScansHtml(currentUserDetailData.scanLogs);
  } else if (tab === 'actions') {
    contentEl.innerHTML = renderAdminDetailActionsHtml(currentUserDetailData.adminLogs);
  }
}

function renderUserDetailTicketsHtml(tickets) {
  if (!tickets.length) return '<div class="loading">No tickets held currently</div>';

  return `
    <div class="table-wrap">
      <table class="data-table">
        <thead>
          <tr>
            <th>Ticket ID</th>
            <th>Event</th>
            <th>Category</th>
            <th>Type</th>
            <th>Qty</th>
            <th>Status</th>
            <th>Scanned?</th>
          </tr>
        </thead>
        <tbody>
          ${tickets.map(t => {
    const qty = t.quantity || 1;
    return `
              <tr>
                <td style="font-family:monospace;font-size:11px">${String(t._id).slice(-8)}</td>
                <td>${t.eventId?.name || '—'}</td>
                <td>${t.category}</td>
                <td>${badge(t.type)}</td>
                <td><span class="badge ${qty > 1 ? 'badge-info' : 'badge-muted'}">${qty}x</span></td>
                <td>${badge(t.status)}</td>
                <td>${t.isScanned ? '<span class="badge badge-success">Yes</span>' : '<span class="badge badge-muted">No</span>'}</td>
              </tr>
            `;
  }).join('')}
        </tbody>
      </table>
    </div>
  `;
}

function renderUserDetailTransfersHtml(outTransfers, inTransfers) {
  if (!outTransfers.length && !inTransfers.length) return '<div class="loading">No transfers recorded</div>';

  let html = '';
  if (outTransfers.length) {
    html += `
      <h4 style="margin: 15px 0 10px 0; font-size: 13px; font-weight: 700; color: #FF8C5A">📤 Transferred Out</h4>
      <div class="table-wrap" style="margin-bottom: 20px;">
        <table class="data-table">
          <thead>
            <tr>
              <th>Time</th>
              <th>Passes</th>
              <th>Event · Zone</th>
              <th>Sent To</th>
              <th>Type</th>
              <th>OTP</th>
            </tr>
          </thead>
          <tbody>
            ${outTransfers.map(tr => {
      const qty = tr.metadata?.quantity || 1;
      const otpOk = tr.metadata?.otpVerified !== false;
      return `
              <tr>
                <td>${fmt(tr.createdAt)}</td>
                <td>
                  ${qty > 1
          ? `<span class="badge badge-info">${qty}x</span>`
          : `<span class="badge badge-muted">1x</span>`}
                </td>
                <td style="font-size:12px">${tr.ticketId?.eventId?.name || '—'} · ${tr.ticketId?.zoneId?.name || tr.ticketId?.category || '—'}</td>
                <td>${tr.toUserId?.name || '—'} <br><small style="color:var(--muted)">${tr.toUserId?.phoneNumber || tr.toPhone || '—'}</small></td>
                <td>${badge(tr.ticketId?.type || '—')}</td>
                <td>${otpOk ? '<span class="badge badge-success">✓</span>' : '<span class="badge badge-muted">—</span>'}</td>
              </tr>
              `;
    }).join('')}
          </tbody>
        </table>
      </div>
    `;
  }

  if (inTransfers.length) {
    html += `
      <h4 style="margin: 15px 0 10px 0; font-size: 13px; font-weight: 700; color: var(--green)">📥 Received</h4>
      <div class="table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>Time</th>
              <th>Passes</th>
              <th>Event · Zone</th>
              <th>Received From</th>
              <th>Type</th>
            </tr>
          </thead>
          <tbody>
            ${inTransfers.map(tr => {
      const qty = tr.metadata?.quantity || 1;
      return `
              <tr>
                <td>${fmt(tr.createdAt)}</td>
                <td>
                  ${qty > 1
          ? `<span class="badge badge-info">${qty}x</span>`
          : `<span class="badge badge-muted">1x</span>`}
                </td>
                <td style="font-size:12px">${tr.ticketId?.eventId?.name || '—'} · ${tr.ticketId?.zoneId?.name || tr.ticketId?.category || '—'}</td>
                <td>${tr.fromUserId?.name || '—'} <br><small style="color:var(--muted)">${tr.fromUserId?.phoneNumber || '—'}</small></td>
                <td>${badge(tr.ticketId?.type || '—')}</td>
              </tr>
              `;
    }).join('')}
          </tbody>
        </table>
      </div>
    `;
  }

  return html;
}

function renderUserDetailAuthHtml(authLogs) {
  if (!authLogs.length) return '<div class="loading">No auth events recorded</div>';
  return `
    <div class="table-wrap">
      <table class="data-table">
        <thead>
          <tr>
            <th>Time</th>
            <th>Event</th>
            <th>IP Address</th>
            <th>Device ID</th>
          </tr>
        </thead>
        <tbody>
          ${authLogs.map(log => `
            <tr>
              <td>${fmt(log.createdAt)}</td>
              <td><span class="badge ${getAuthEventBadgeClass(log.event)}">${log.event}</span></td>
              <td>${log.ipAddress || '—'}</td>
              <td style="font-size:11px;color:var(--muted)">${log.deviceId || '—'}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>
  `;
}

// ── Scanner Detail Slide-In Panel ────────────────────────────────
async function openScannerDetail(scannerId) {
  const overlay = document.getElementById('scannerDetailOverlay');
  const nameEl = document.getElementById('scannerDetailName');
  const metaEl = document.getElementById('scannerDetailMeta');
  const bodyEl = document.getElementById('scannerDetailBody');

  nameEl.textContent = 'Scanner Detail';
  metaEl.textContent = 'Loading...';
  bodyEl.innerHTML = '<div class="loading">Loading analytics & history...</div>';
  overlay.classList.add('open');

  try {
    const data = await apiFetch(`/admin/analytics/scanner/${scannerId}`);
    currentScannerDetailData = data;

    const scannerUser = allUsers.find(u => u._id === scannerId) || (data.scanLogs[0]?.scannerId);

    nameEl.textContent = scannerUser?.name || 'Scanner Detail';
    metaEl.textContent = `${scannerUser?.phoneNumber || ''} · Role: ${scannerUser?.role?.toUpperCase() || 'SCANNER'}`;

    const sum = data.summary;
    const successRate = sum.total > 0 ? Math.round((sum.success / sum.total) * 100) : 0;

    bodyEl.innerHTML = `
      <div class="profile-info-row">
        <div class="profile-avatar">📲</div>
        <div class="profile-details">
          <div class="profile-name">${scannerUser?.name || 'Scanner User'}</div>
          <div class="profile-sub">
            <span>📞 ${scannerUser?.phoneNumber || '—'}</span>
            <span>📧 ${scannerUser?.email || 'No email'}</span>
            <span>📅 Joined: ${fmt(scannerUser?.createdAt)}</span>
          </div>
        </div>
      </div>
      
      <div class="analytics-grid">
        <div class="analytics-card pink-glow">
          <div class="ac-icon">📡</div>
          <div class="ac-value">${sum.total}</div>
          <div class="ac-label">Total Scans</div>
        </div>
        <div class="analytics-card green-glow">
          <div class="ac-icon">✅</div>
          <div class="ac-value">${sum.success}</div>
          <div class="ac-label">Success Rate (${successRate}%)</div>
        </div>
        <div class="analytics-card orange-glow">
          <div class="ac-icon">⚠️</div>
          <div class="ac-value">${sum.duplicate}</div>
          <div class="ac-label">Duplicates</div>
        </div>
        <div class="analytics-card red-glow">
          <div class="ac-icon">🚫</div>
          <div class="ac-value">${sum.fraud + sum.invalid_sig + sum.time_invalid}</div>
          <div class="ac-label">Fraud/Invalid</div>
        </div>
      </div>
      
      <div class="tab-bar">
        <button class="tab-btn active" id="sdTabBtn-scans" onclick="switchScannerDetailTab('scans')">📡 Recent Scans (${data.scanLogs.length})</button>
        <button class="tab-btn" id="sdTabBtn-auth" onclick="switchScannerDetailTab('auth')">🔑 Auth Logs (${data.authLogs.length})</button>
      </div>
      
      <div id="sdTabContent" style="margin-top: 15px;">
        ${renderScannerDetailScansHtml(data.scanLogs)}
      </div>
    `;

  } catch (e) {
    bodyEl.innerHTML = `<div class="loading" style="color:var(--error)">Error loading scanner details: ${e.message}</div>`;
  }
}

function switchScannerDetailTab(tab) {
  if (!currentScannerDetailData) return;

  document.querySelectorAll('#scannerDetailBody .tab-btn').forEach(btn => btn.classList.remove('active'));
  const activeBtn = document.getElementById(`sdTabBtn-${tab}`);
  if (activeBtn) activeBtn.classList.add('active');

  const contentEl = document.getElementById('sdTabContent');
  if (!contentEl) return;

  if (tab === 'scans') {
    contentEl.innerHTML = renderScannerDetailScansHtml(currentScannerDetailData.scanLogs);
  } else if (tab === 'auth') {
    contentEl.innerHTML = renderScannerDetailAuthHtml(currentScannerDetailData.authLogs);
  }
}

function renderScannerDetailScansHtml(scanLogs) {
  if (!scanLogs.length) return '<div class="loading">No scans recorded</div>';
  return `
    <div class="table-wrap">
      <table class="data-table">
        <thead>
          <tr>
            <th>Time</th>
            <th>Ticket ID</th>
            <th>Owner</th>
            <th>Event</th>
            <th>Zone</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          ${scanLogs.map(log => {
    const ownerName = log.ticketId?.userId?.name || '—';
    const ownerPhone = log.ticketId?.userId?.phoneNumber || '—';
    return `
              <tr>
                <td>${fmt(log.createdAt)}</td>
                <td style="font-family:monospace;font-size:11px">${String(log.ticketId?._id || log.ticketId).slice(-8)}</td>
                <td>
                  <strong>${ownerName}</strong><br>
                  <small style="color:var(--muted)">${ownerPhone}</small>
                </td>
                <td>${log.eventId?.name || '—'}</td>
                <td>${log.zoneId?.name || '—'}</td>
                <td>${badge(log.status)}</td>
              </tr>
            `;
  }).join('')}
        </tbody>
      </table>
    </div>
  `;
}

function renderScannerDetailAuthHtml(authLogs) {
  if (!authLogs.length) return '<div class="loading">No auth events recorded</div>';
  return `
    <div class="table-wrap">
      <table class="data-table">
        <thead>
          <tr>
            <th>Time</th>
            <th>Event</th>
            <th>IP Address</th>
            <th>Device ID</th>
          </tr>
        </thead>
        <tbody>
          ${authLogs.map(log => `
            <tr>
              <td>${fmt(log.createdAt)}</td>
              <td><span class="badge ${getAuthEventBadgeClass(log.event)}">${log.event}</span></td>
              <td>${log.ipAddress || '—'}</td>
              <td style="font-size:11px;color:var(--muted)">${log.deviceId || '—'}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>
  `;
}

function renderAdminDetailActionsHtml(adminLogs) {
  if (!adminLogs.length) return '<div class="loading">No admin actions recorded</div>';
  return `
    <div class="table-wrap">
      <table class="data-table">
        <thead>
          <tr>
            <th>Time</th>
            <th>Action</th>
            <th>Target Resource</th>
            <th>Changes</th>
          </tr>
        </thead>
        <tbody>
          ${adminLogs.map(l => `
            <tr>
              <td>${fmt(l.createdAt)}</td>
              <td><span class="badge badge-log-admin">${l.action}</span></td>
              <td>
                <span style="color:var(--muted);font-size:11px">${l.targetType || '—'}</span><br>
                <strong>${l.targetName || l.targetId || '—'}</strong>
              </td>
              <td>${formatChanges(l.changes)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>
  `;
}

function adminLogout() {
  localStorage.removeItem('admin_token');
  localStorage.removeItem('admin_user');
  document.getElementById('loginOverlay').style.display = 'flex';
  document.getElementById('loginPhone').value = '';
  document.getElementById('loginOtp').value = '';
  showPhoneStep();
  showToast('🚪 Logged out');
}

window.addEventListener('DOMContentLoaded', () => {
  const token = localStorage.getItem('admin_token');
  const userStr = localStorage.getItem('admin_user');
  if (token && userStr) {
    try {
      const user = JSON.parse(userStr);
      document.getElementById('adminNameDisplay').textContent = user.name || 'Admin';
      document.getElementById('loginOverlay').style.display = 'none';
      checkApiStatus();
      setInterval(checkApiStatus, 15000);
      loadDashboard();
    } catch (e) {
      adminLogout();
    }
  } else {
    adminLogout();
  }
});

function renderAdminManagementCard(user) {
  if (!user || user.role === 'admin') return '';
  const currentStatus = user.status || 'active';
  const isActive = currentStatus === 'active';
  const isBanned = currentStatus === 'banned';
  const isDeactivated = currentStatus === 'deactivated';
  const isDeleted = currentStatus === 'deleted';

  if (isDeleted) {
    return `
      <div class="admin-actions-card" style="background: rgba(255, 68, 68, 0.05); border: 1px solid rgba(255, 68, 68, 0.15); border-radius: 12px; padding: 16px; margin: 20px 0;">
        <h4 style="margin:0 0 6px 0; font-size:13px; font-weight:700; color:#FF4444; letter-spacing:0.5px; text-transform:uppercase;">Account Deleted</h4>
        <div style="font-size:12px; color:var(--text-muted)">This account has been anonymized and deleted. No further actions can be performed.</div>
      </div>
    `;
  }

  return `
    <div class="admin-actions-card" style="background: rgba(255,255,255,0.02); border: 1px solid var(--border); border-radius: 12px; padding: 16px; margin: 20px 0;">
      <h4 style="margin:0 0 12px 0; font-size:13px; font-weight:700; color:var(--text-muted); letter-spacing:0.5px; text-transform:uppercase;">Admin Management</h4>
      <div style="display:flex; gap:10px; flex-wrap:wrap;">
        ${isActive
      ? `<button class="btn btn-sm btn-outline" style="border-color:#FFA726; color:#FFA726; background:transparent;" onclick="updateUserStatus('${user._id}', 'deactivated')">⏸️ Deactivate</button>`
      : `<button class="btn btn-sm btn-success" onclick="updateUserStatus('${user._id}', 'active')">▶️ Reactivate</button>`
    }
        ${!isBanned
      ? `<button class="btn btn-sm btn-danger" style="background:#ef5350; color:#fff; border-color:#ef5350;" onclick="updateUserStatus('${user._id}', 'banned')">🚫 Ban User</button>`
      : ''
    }
        <button class="btn btn-sm btn-danger btn-outline" style="border-color:#e53935; color:#e53935; background:transparent;" onclick="adminDeleteUser('${user._id}')">🗑️ Delete Account</button>
      </div>
      ${!isActive
      ? `<div style="margin-top:10px; font-size:12px; color:#FFA726;">⚠️ Current Status: <strong>${currentStatus.toUpperCase()}</strong></div>`
      : ''
    }
    </div>
  `;
}

async function updateUserStatus(userId, status) {
  if (!confirm(`Are you sure you want to change this user's status to ${status}?`)) return;
  try {
    await apiFetch(`/admin/users/${userId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status })
    });
    showToast(`✅ User status updated to ${status}!`);
    closeModal('userDetailOverlay');
    loadUsers();
  } catch (e) {
    showToast('❌ Failed to update status: ' + e.message, 'error');
  }
}

async function adminDeleteUser(userId) {
  if (!confirm("⚠️ WARNING: Deleting this account will permanently erase the user's name, email, and phone number from our system. This action is irreversible. Are you sure you want to delete this user?")) return;
  try {
    await apiFetch(`/admin/users/${userId}`, {
      method: 'DELETE'
    });
    showToast('🗑️ User account deleted successfully!');
    closeModal('userDetailOverlay');
    loadUsers();
  } catch (e) {
    showToast('❌ Failed to delete user: ' + e.message, 'error');
  }
}

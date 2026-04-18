// ── Config ────────────────────────────────────────
const API = 'http://localhost:3000/api';

// ── State ─────────────────────────────────────────
let state = {
  user: null,
  token: null,
  events: [],
  currentEvent: null,
  booking: { type: 'regular', category: 'General', zoneId: '', qty: 1, step: 1 },
};

// ── Persist Auth ──────────────────────────────────
function loadStoredAuth() {
  const t = localStorage.getItem('nav_token');
  const u = localStorage.getItem('nav_user');
  if (t && u) {
    state.token = t;
    state.user  = JSON.parse(u);
    onLogin();
  }
}

// ── API Helper ────────────────────────────────────
async function api(path, opts = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (state.token) headers['Authorization'] = `Bearer ${state.token}`;
  const res = await fetch(API + path, { headers, ...opts });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.message || `Error ${res.status}`);
  return data;
}

// ── Toast ─────────────────────────────────────────
function toast(msg, type = 'success') {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className = `toast show ${type}`;
  setTimeout(() => t.className = 'toast', 3200);
}

// ── Modal ─────────────────────────────────────────
function openModal(id)  { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }

// ── Page Navigation ───────────────────────────────
function showPage(name) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
  document.getElementById('page-' + name)?.classList.add('active');
  const nl = document.getElementById('nl-' + name);
  if (nl) nl.classList.add('active');
  window.scrollTo(0, 0);

  if (name === 'home')      loadHome();
  if (name === 'events')    loadAllEvents();
  if (name === 'mytickets') loadMyTickets();
}

// ───────────────────────────────────────────────────
// HOME
// ───────────────────────────────────────────────────
async function loadHome() {
  try {
    const [events, stats] = await Promise.allSettled([
      api('/events'),
      api('/admin/stats'),
    ]);

    const evts = events.status === 'fulfilled' ? events.value : [];
    state.events = evts;

    // Stats
    document.getElementById('hs-events').textContent  = evts.length;
    if (stats.status === 'fulfilled') {
      document.getElementById('hs-tickets').textContent = stats.value.totalTickets ?? '0';
    }

    // Featured (published first, max 3)
    const featured = evts.filter(e => e.status === 'published').slice(0, 3);
    renderEventCards('featuredEvents', featured.length ? featured : evts.slice(0, 3));
  } catch (e) {
    document.getElementById('featuredEvents').innerHTML = '<div class="center-loader">Could not load events</div>';
  }
}

// ───────────────────────────────────────────────────
// EVENTS
// ───────────────────────────────────────────────────
async function loadAllEvents() {
  document.getElementById('allEventsList').innerHTML = '<div class="event-skeleton"></div><div class="event-skeleton"></div>';
  try {
    const events = await api('/events');
    state.events = events;
    renderEventCards('allEventsList', events);
  } catch {
    document.getElementById('allEventsList').innerHTML = '<div class="center-loader">Failed to load events</div>';
  }
}

function renderEventCards(containerId, events) {
  const el = document.getElementById(containerId);
  if (!events.length) {
    el.innerHTML = `
      <div class="empty-state" style="grid-column:1/-1">
        <div class="empty-icon">🎪</div>
        <h3>No events yet</h3>
        <p>Check back soon for upcoming Navratri events</p>
      </div>`;
    return;
  }

  el.innerHTML = events.map(e => {
    const prices = e.ticketPricing?.regular;
    const minPrice = prices ? Math.min(...Object.values(prices).filter(Boolean)) : 0;
    const dates   = (e.eventDates || []).slice(0, 3);

    return `
      <div class="event-card" onclick="openEvent('${e._id}')">
        <div class="event-banner-placeholder">🪔</div>
        <div class="event-body">
          <div class="event-name">${e.name}</div>
          <div class="event-venue">📍 ${e.venue}</div>
          <div class="event-dates">
            ${dates.map(d => `<span class="date-chip">${d}</span>`).join('')}
            ${e.eventDates?.length > 3 ? `<span class="date-chip">+${e.eventDates.length - 3} more</span>` : ''}
          </div>
          <div class="event-footer">
            <div class="event-price">From <b>₹${minPrice || 'Free'}</b></div>
            <button class="btn btn-primary" onclick="event.stopPropagation();openEvent('${e._id}')">Book Now</button>
          </div>
        </div>
      </div>`;
  }).join('');
}

// ───────────────────────────────────────────────────
// EVENT DETAIL
// ───────────────────────────────────────────────────
async function openEvent(eventId) {
  showPage('event-detail');
  const el = document.getElementById('eventDetailContent');
  el.innerHTML = '<div class="center-loader">Loading event details...</div>';

  try {
    const [event, zones] = await Promise.all([
      api(`/events/${eventId}`),
      api(`/events/${eventId}/zones`),
    ]);
    state.currentEvent = event;

    const prices  = event.ticketPricing?.regular  || {};
    const sPrices = event.ticketPricing?.season || {};

    el.innerHTML = `
      <div class="glass-card" style="margin-bottom:24px">
        <div class="event-banner-placeholder" style="border-radius:12px 12px 0 0;margin:-24px -24px 24px -24px;height:260px;font-size:80px"></div>
        <h2 style="font-size:28px;font-weight:800;margin-bottom:8px">${event.name}</h2>
        <p style="color:var(--muted);margin-bottom:20px">${event.description || ''}</p>
        <div style="display:flex;flex-wrap:wrap;gap:20px;margin-bottom:24px">
          <div><div style="font-size:12px;color:var(--muted);margin-bottom:4px">VENUE</div><div style="font-weight:600">📍 ${event.venue}</div></div>
          <div><div style="font-size:12px;color:var(--muted);margin-bottom:4px">DATES</div><div style="font-weight:600">${(event.eventDates||[]).join(' · ')}</div></div>
        </div>
        ${event.status !== 'published' ? '<div style="background:rgba(255,200,0,.1);border:1px solid rgba(255,200,0,.3);color:#FFD600;padding:12px 18px;border-radius:10px;margin-bottom:16px">⚠️ This event is not available for booking yet</div>' : ''}
        <button class="btn btn-hero" style="font-size:15px" ${event.status !== 'published' ? 'disabled style="opacity:.4;cursor:not-allowed"' : ''} onclick="openBookingModal()">🎟️ Book Tickets</button>
      </div>

      <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:16px">
        ${Object.entries(prices).filter(([,v])=>v>0).map(([cat,price]) => `
          <div class="glass-card">
            <div style="font-size:13px;color:var(--muted);font-weight:600">REGULAR · ${cat}</div>
            <div style="font-size:26px;font-weight:800;margin-top:6px">₹${price}</div>
          </div>`).join('')}
        ${Object.entries(sPrices).filter(([,v])=>v>0).map(([cat,price]) => `
          <div class="glass-card" style="border-color:rgba(121,40,202,.2)">
            <div style="font-size:13px;color:#A855F7;font-weight:600">SEASON · ${cat}</div>
            <div style="font-size:26px;font-weight:800;margin-top:6px">₹${price}</div>
          </div>`).join('')}
      </div>`;

    // Populate zone dropdown in booking modal
    const zoneSelect = document.getElementById('bookZone');
    zoneSelect.innerHTML = zones.map(z => `<option value="${z._id}" data-price="${z.price || 0}">${z.name} - ₹${z.price || 0}</option>`).join('') || '<option value="">No zones available</option>';

    // Add change listener to update price when zone changes
    zoneSelect.onchange = () => updatePrice();

  } catch (e) {
    el.innerHTML = '<div class="center-loader">Failed to load event</div>';
  }
}

function openBookingModal() {
  if (!state.user) {
    toast('🔐 Please login first!', 'error');
    showPage('login');
    return;
  }
  state.booking = { type: 'regular', category: 'General', qty: 1, step: 1. };
  selectType('regular');
  updatePrice();
  showStep(1);
  openModal('bookingModal');
}

// ───────────────────────────────────────────────────
// BOOKNG FLOW
// ───────────────────────────────────────────────────
function selectType(t) {
  state.booking.type = t;
  document.getElementById('to-regular').classList.toggle('selected', t === 'regular');
  document.getElementById('to-season').classList.toggle('selected', t === 'season');
  updatePrice();
}

function changeQty(delta) {
  state.booking.qty = Math.max(1, Math.min(10, state.booking.qty + delta));
  document.getElementById('qtyDisplay').textContent = state.booking.qty;
  updatePrice();
}

function updatePrice() {
  const ev  = state.currentEvent;
  if (!ev) return;
  
  const zoneSelect = document.getElementById('bookZone');
  const selectedZonePrice = zoneSelect?.selectedOptions[0]?.getAttribute('data-price');
  
  const cat = document.getElementById('bookCategory')?.value || 'General';
  const tp  = state.booking.type;
  const qty = state.booking.qty || 1;

  // Use zone price if available, otherwise fallback to event ticket pricing
  const base   = selectedZonePrice ? Number(selectedZonePrice) : (ev.ticketPricing?.[tp]?.[cat] || 0);
  const gst    = ev.gstEnabled ? Math.round(base * (ev.gstPercentage / 100)) : 0;
  const total  = (base + gst) * qty;

  document.getElementById('ps-base').textContent  = `₹${base * qty}`;
  document.getElementById('ps-gst').textContent   = `₹${gst * qty}`;
  document.getElementById('ps-total').textContent = `₹${total}`;
  document.getElementById('pay-qty').textContent  = `${qty}x ${tp} · ${cat}`;
  document.getElementById('pay-total').textContent = `₹${total}`;
}

function showStep(step) {
  [1,2,3].forEach(s => {
    const el = document.getElementById('bookStep' + s);
    if (el) el.style.display = s === step ? 'block' : 'none';
  });
  const footer = document.getElementById('bookingFooter');
  if (step === 3) footer.style.display = 'none';
  else footer.style.display = 'flex';
  const btn = document.getElementById('bookNextBtn');
  if (step === 1) btn.textContent = 'Continue →';
  if (step === 2) btn.textContent = '💳 Pay Now';
}

async function bookingNext() {
  const step = state.booking.step;

  if (step === 1) {
    state.booking.category = document.getElementById('bookCategory').value;
    state.booking.zoneId   = document.getElementById('bookZone').value;
    state.booking.step = 2;
    showStep(2);

  } else if (step === 2) {
    // Initiate Razorpay order
    try {
      const ev  = state.currentEvent;
      const body = {
        userId:   state.user._id,
        eventId:  ev._id,
        zoneId:   state.booking.zoneId,
        type:     state.booking.type,
        category: state.booking.category,
        quantity: state.booking.qty,
      };

      const { order, totalAmount } = await api('/tickets/order', {
        method: 'POST',
        body: JSON.stringify(body),
      });

      // Open Razorpay checkout
      const options = {
        key:      'rzp_test_placeholder', // Replace with real key
        amount:   order.amount,
        currency: 'INR',
        order_id: order.id,
        name:     'Navratri 2024',
        description: `${state.booking.qty}x ${state.booking.type} ticket`,
        handler: async (response) => {
          await api('/tickets/verify-payment', {
            method: 'POST',
            body: JSON.stringify({
              ...response,
              userId:   state.user._id,
              eventId:  ev._id,
              zoneId:   state.booking.zoneId,
              type:     state.booking.type,
              category: state.booking.category,
              quantity: state.booking.qty,
            }),
          });
          state.booking.step = 3;
          showStep(3);
          toast('🎉 Booking confirmed!');
        },
        theme: { color: '#FF0080' },
      };

      if (window.Razorpay) {
        new window.Razorpay(options).open();
      } else {
        // If Razorpay SDK not loaded, simulate for demo
        toast('⚠️ Razorpay SDK not loaded. Simulating booking...');
        setTimeout(() => { state.booking.step = 3; showStep(3); toast('🎉 Booking simulated!'); }, 1200);
      }

    } catch (e) {
      toast('❌ ' + e.message, 'error');
    }
  }
}

// ───────────────────────────────────────────────────
// AUTH
// ───────────────────────────────────────────────────
async function requestOtp() {
  const phone = document.getElementById('phoneInput').value.trim();
  if (!phone || phone.length < 10) { toast('Enter a valid 10-digit number', 'error'); return; }

  try {
    await api('/auth/request-otp', {
      method: 'POST',
      body: JSON.stringify({ phoneNumber: '+91' + phone }),
    });
    document.getElementById('otpPhone').textContent = '+91' + phone;
    document.getElementById('stepPhone').style.display = 'none';
    document.getElementById('stepOtp').style.display   = 'block';
    toast('📱 OTP sent!');
  } catch (e) { toast(e.message, 'error'); }
}

async function verifyOtp() {
  const phone = document.getElementById('phoneInput').value.trim();
  const otp   = document.getElementById('otpInput').value.trim();

  try {
    const { access_token, user } = await api('/auth/verify-otp', {
      method: 'POST',
      body: JSON.stringify({ phoneNumber: '+91' + phone, otp }),
    });
    state.token = access_token;
    state.user  = user;
    localStorage.setItem('nav_token', access_token);
    localStorage.setItem('nav_user',  JSON.stringify(user));
    onLogin();
    toast('✅ Logged in!');
    showPage('home');
  } catch (e) { toast(e.message || 'Invalid OTP', 'error'); }
}

function onLogin() {
  document.getElementById('guestActions').style.display = 'none';
  document.getElementById('userActions').style.display  = 'flex';
  document.getElementById('userPhone').textContent = state.user?.phoneNumber || '';
  document.getElementById('nl-mytickets').style.display = 'inline-flex';
}

function logout() {
  localStorage.removeItem('nav_token');
  localStorage.removeItem('nav_user');
  state.user = null; state.token = null;
  document.getElementById('guestActions').style.display = 'flex';
  document.getElementById('userActions').style.display  = 'none';
  document.getElementById('nl-mytickets').style.display = 'none';
  toast('👋 Logged out');
  showPage('home');
}

// ───────────────────────────────────────────────────
// MY TICKETS
// ───────────────────────────────────────────────────
async function loadMyTickets() {
  if (!state.user) { showPage('login'); return; }
  const el = document.getElementById('myTicketsList');
  el.innerHTML = '<div class="center-loader">Loading your tickets...</div>';

  try {
    const tickets = await api(`/tickets/my/${state.user._id}`);

    if (!tickets.length) {
      el.innerHTML = `
        <div class="empty-state">
          <div class="empty-icon">🎟️</div>
          <h3>No tickets yet</h3>
          <p>Browse events and book your first ticket!</p>
          <button class="btn btn-primary" onclick="showPage('events')">Browse Events</button>
        </div>`;
      return;
    }

    el.innerHTML = `<div class="tickets-list">${tickets.map(t => ticketCard(t)).join('')}</div>`;
  } catch (e) { el.innerHTML = '<div class="center-loader">Failed to load tickets</div>'; }
}

function ticketCard(t) {
  const event = t.eventId;
  const zone  = t.zoneId;
  const isVerified = t.isVerified;
  const needsVerify = t.type === 'season' && !isVerified;

  return `
    <div class="ticket-card">
      <div class="ticket-top">
        <div>
          <div class="ticket-event">🎪 ${event?.name || 'Event'}</div>
          <div class="ticket-meta">📍 ${event?.venue || ''} · 🏟️ ${zone?.name || ''}</div>
        </div>
        <div style="display:flex;flex-direction:column;align-items:flex-end;gap:6px">
          <span class="badge badge-${t.type}">${t.type}</span>
          <span class="badge badge-${t.status}">${t.status}</span>
        </div>
      </div>
      <div class="ticket-mid">
        <span class="badge" style="background:rgba(255,255,255,.05);color:var(--muted)">📁 ${t.category}</span>
        <span class="badge" style="background:rgba(255,255,255,.05);color:var(--muted)">₹${t.totalAmount}</span>
        ${t.type === 'season' ? `<span class="badge ${isVerified ? 'badge-active' : 'badge-pending'}">${isVerified ? '✅ Verified' : '⏳ Pending Verification'}</span>` : ''}
      </div>
      <div class="ticket-actions">
        ${t.status === 'active' && (t.type === 'regular' || isVerified) ?
          `<button class="btn btn-success" onclick="viewQr('${t._id}')">📱 Show QR</button>` : ''}
        ${needsVerify ?
          `<button class="btn btn-primary" onclick="openVerify('${t._id}')">🪪 Verify Identity</button>` : ''}
        ${t.transferable && t.status === 'active' ?
          `<button class="btn btn-sm" onclick="openTransfer('${t._id}')">↗️ Transfer</button>` : ''}
      </div>
    </div>`;
}

// ───────────────────────────────────────────────────
// QR VIEW
// ───────────────────────────────────────────────────
async function viewQr(ticketId) {
  showPage('ticket-qr');
  const el = document.getElementById('ticketQrContent');
  el.innerHTML = '<div class="center-loader">Generating QR...</div>';

  try {
    const qrData = await api(`/tickets/${ticketId}/qr/${state.user._id}`);
    const qrString = JSON.stringify(qrData);

    el.innerHTML = `
      <div class="qr-card glass-card">
        <h3 style="font-size:20px;font-weight:800;margin-bottom:4px">Your Entry QR</h3>
        <p class="muted small">Show this at the gate for entry</p>
        <div class="qr-wrap">
          <canvas id="qrCanvas"></canvas>
        </div>
        <div class="qr-info">
          <div class="qr-info-item"><label>Ticket ID</label><span>${String(ticketId).slice(-8).toUpperCase()}</span></div>
          <div class="qr-info-item"><label>Type</label><span>${qrData.t?.toUpperCase()}</span></div>
          <div class="qr-info-item"><label>Event Date</label><span>${qrData.d}</span></div>
          <div class="qr-info-item"><label>System</label><span>${qrData.sys === 'm' ? 'Main' : 'Private'}</span></div>
        </div>
        <p class="muted small" style="margin-top:16px;text-align:center">⚠️ Do not share this QR code</p>
      </div>`;

    QRCode.toCanvas(document.getElementById('qrCanvas'), qrString, {
      width: 220, margin: 1,
      color: { dark: '#000000', light: '#FFFFFF' },
    });
  } catch (e) {
    el.innerHTML = `<div class="center-loader">❌ ${e.message}</div>`;
  }
}

// ───────────────────────────────────────────────────
// TRANSFER
// ───────────────────────────────────────────────────
function openTransfer(ticketId) {
  const phone = prompt('Enter recipient mobile number (+91XXXXXXXXXX):');
  if (!phone) return;
  api(`/tickets/${ticketId}/transfer`, {
    method: 'POST',
    body: JSON.stringify({ fromUserId: state.user._id, toPhone: phone }),
  }).then(() => {
    toast('✅ Ticket transferred!');
    loadMyTickets();
  }).catch(e => toast('❌ ' + e.message, 'error'));
}

// ───────────────────────────────────────────────────
// SEASON PASS VERIFICATION
// ───────────────────────────────────────────────────
function openVerify(ticketId) {
  showPage('verify');
  const el = document.getElementById('verifyContent');
  el.innerHTML = `
    <div class="verify-card">
      <div class="glass-card" style="margin-bottom:20px">
        <h3 style="font-size:20px;font-weight:800;margin-bottom:8px">Identity Verification</h3>
        <p class="muted">Season pass requires one-time identity verification. Upload your selfie and ID proof to get approved.</p>
      </div>

      <div class="verify-step" id="vs-selfie" onclick="captureSelfie('${ticketId}')">
        <div class="vs-icon">📸</div>
        <div>
          <div style="font-weight:700;font-size:15px">Take a Selfie</div>
          <div class="muted small">Camera only · Face clearly visible</div>
        </div>
        <div style="margin-left:auto;color:var(--muted)">→</div>
      </div>

      <div class="verify-step" id="vs-id" onclick="uploadId('${ticketId}')">
        <div class="vs-icon">🪪</div>
        <div>
          <div style="font-weight:700;font-size:15px">Upload ID Proof</div>
          <div class="muted small">Aadhaar / PAN / Driving License</div>
        </div>
        <div style="margin-left:auto;color:var(--muted)">→</div>
      </div>

      <input type="file" id="selfieInput" accept="image/*" capture="user" style="display:none" onchange="onSelfieSelected(event,'${ticketId}')" />
      <input type="file" id="idInput" accept="image/*" style="display:none" onchange="onIdSelected(event,'${ticketId}')" />

      <div id="verifyStatus" style="margin-top:16px"></div>

      <button class="btn btn-primary full-width" style="margin-top:20px" id="submitVerifyBtn" disabled onclick="submitVerification('${ticketId}')">
        Submit for Verification
      </button>
    </div>`;
}

let verifyData = { selfie: false, id: false };

function captureSelfie(ticketId) { document.getElementById('selfieInput').click(); }
function uploadId(ticketId)      { document.getElementById('idInput').click(); }

function onSelfieSelected(e, ticketId) {
  verifyData.selfie = true;
  const step = document.getElementById('vs-selfie');
  step.classList.add('done');
  step.querySelector('.vs-icon').textContent = '✅';
  checkVerifyReady();
}

function onIdSelected(e, ticketId) {
  verifyData.id = true;
  const step = document.getElementById('vs-id');
  step.classList.add('done');
  step.querySelector('.vs-icon').textContent = '✅';
  checkVerifyReady();
}

function checkVerifyReady() {
  const btn = document.getElementById('submitVerifyBtn');
  if (btn) btn.disabled = !(verifyData.selfie && verifyData.id);
}

async function submitVerification(ticketId) {
  try {
    // In production: upload files to cloud storage, then send URLs to API
    await api(`/tickets/${ticketId}/submit-verification`, {
      method: 'POST',
      body: JSON.stringify({
        userId: state.user._id,
        selfieUrl: 'https://placeholder.selfie.url',
        idProofUrl: 'https://placeholder.id.url',
      }),
    });
    document.getElementById('verifyStatus').innerHTML = `
      <div class="glass-card" style="border-color:rgba(255,200,0,.3);color:#FFD600">
        ⏳ Submitted for review. Admin will approve within 24 hours.
      </div>`;
    toast('📤 Verification submitted!');
  } catch (e) { toast('❌ ' + e.message, 'error'); }
}

// ── Init ──────────────────────────────────────────
window.addEventListener('DOMContentLoaded', () => {
  loadStoredAuth();
  loadHome();
});

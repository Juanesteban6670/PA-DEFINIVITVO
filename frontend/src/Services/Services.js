import api from './Api'

// ── AUTH ──────────────────────────────────────────────────────────────────
export const authService = {
  login:    (data) => api.post('/Auth/Login', data),
  register: (data) => api.post('/Auth/Register', data),
  forgotPassword: (data) => api.post('/Auth/ForgotPassword', data),
  resetPassword:  (data) => api.post('/Auth/ResetPassword', data),
}

// ── INCIDENTS ─────────────────────────────────────────────────────────────
export const incidentService = {
  getAll:       (params) => api.get('/Incidents', { params }),
  getById:      (id)     => api.get(`/Incidents/${id}`),
  getMine:      ()       => api.get('/Incidents/My'),
  create:       (data)   => api.post('/Incidents', data),
  update:       (id, d)  => api.put(`/Incidents/${id}`, d),
  updateStatus: (id, d)  => api.patch(`/Incidents/${id}/Status`, d),
  delete:       (id)     => api.delete(`/Incidents/${id}`),
  getHistory:   (id)     => api.get(`/Incidents/${id}/History`),
  getComments:     (id)              => api.get(`/Incidents/${id}/Comments`),
  getAllComments:   (id)              => api.get(`/Incidents/${id}/Comments/All`),
  addComment:      (id, d)           => api.post(`/Incidents/${id}/Comments`, d),
  updateComment:   (id, cId, content) => api.put(`/Incidents/${id}/Comments/${cId}`, null, { params: { content } }),
  deleteComment:   (id, cId)         => api.delete(`/Incidents/${id}/Comments/${cId}`),

  uploadFiles: (files) => {
    const fd = new FormData()
    files.forEach(f => fd.append('files', f))
    return api.post('/Files/Upload', fd, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
  },
}

// ── ZONES ─────────────────────────────────────────────────────────────────
export const zoneService = {
  getAll:     ()       => api.get('/Zones'),
  getById:    (id)     => api.get(`/Zones/${id}`),
  create:     (data)   => api.post('/Zones', data),
  update:     (id, d)  => api.put(`/Zones/${id}`, d),
  updateRisk: (id, d)  => api.patch(`/Zones/${id}/Risk`, d),
  delete:     (id)     => api.delete(`/Zones/${id}`),
}

// ── NOTIFICATIONS ─────────────────────────────────────────────────────────
export const notificationService = {
  getAll:        ()   => api.get('/Notifications'),
  getUnread:     ()   => api.get('/Notifications/Unread'),
  countUnread:   ()   => api.get('/Notifications/Unread/Count'),
  markAsRead:    (id) => api.patch(`/Notifications/${id}/Read`),
  markAllAsRead: ()   => api.patch('/Notifications/ReadAll'),
  delete:        (id) => api.delete(`/Notifications/${id}`),
}

// ── EMERGENCY CONTACTS ────────────────────────────────────────────────────
export const emergencyService = {
  getAll:  ()       => api.get('/EmergencyContacts'),
  create:  (data)   => api.post('/EmergencyContacts', data),
  update:  (id, d)  => api.put(`/EmergencyContacts/${id}`, d),
  delete:  (id)     => api.delete(`/EmergencyContacts/${id}`),
}

// ── LOGS ──────────────────────────────────────────────────────────────────
export const logService = {
  getAll: (params) => api.get('/Logs', { params }),
}

// ── REPORTS ───────────────────────────────────────────────────────────────
export const reportService = {
  getAll:   (params) => api.get('/Reports', { params }),
  generate: (data)   => api.post('/Reports', data),
}

// ── AI (GROQ) ─────────────────────────────────────────────────────────────
export const aiService = {
  chat:          (data) => api.post('/Ai/Chat', data),
  classify:      (data) => api.post('/Ai/Classify', data),
  summary:       ()     => api.get('/Ai/Summary'),
  zonesAnalysis: ()     => api.get('/Ai/Zones/Analysis'),
}

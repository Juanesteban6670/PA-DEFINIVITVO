import axios from 'axios'
import toast from 'react-hot-toast'

const api = axios.create({
  //baseURL: 'https://cartagena-segura-production.up.railway.app/api',
  baseURL: 'http://localhost:8080/api',
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' },
})

// ── Request: adjunta JWT automáticamente ──────────────────────────────────
api.interceptors.request.use(config => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// ── Response: maneja errores globalmente ──────────────────────────────────
api.interceptors.response.use(
  res => res,
  err => {
    const status = err.response?.status
    const msg = err.response?.data?.message || 'Error inesperado'
    const url = err.config?.url || ''

    // Rutas de auth — dejar que cada página maneje sus propios errores
    if (url.includes('/Auth/')) return Promise.reject(err)

    if (status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      window.location.href = '/Login'
      toast.error('Sesión expirada, inicia sesión nuevamente')
    } else if (status === 403) {
      toast.error('No tienes permisos para esta acción')
    } else if (status === 404) {
      toast.error('Recurso no encontrado')
    } else if (status >= 500) {
      toast.error('Error del servidor, intenta más tarde')
    } else {
      toast.error(msg)
    }

    return Promise.reject(err)
  }
)

export default api

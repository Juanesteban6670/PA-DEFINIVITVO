import { useEffect, useState, useRef } from 'react'
import { Bell, X, Check, CheckCheck, Trash2, Loader2 } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { notificationService } from '@/Services/Services'
import useAuthStore from '@/Store/AuthStore'
import toast from 'react-hot-toast'

const TYPE_ICON = {
  INCIDENT_CREATED:        '🆕',
  INCIDENT_STATUS_CHANGED: '🔄',
  INCIDENT_RESOLVED:       '✅',
  INCIDENT_REJECTED:       '❌',
  SYSTEM:                  '⚙️',
}

const STATUS_MAP = {
  'PENDING': 'PENDIENTE',
  'IN_PROGRESS': 'EN CURSO',
  'RESOLVED': 'RESUELTO',
  'REJECTED': 'RECHAZADO'
}

export default function NotificationPanel() {
  const [open, setOpen]       = useState(false)
  const [notifs, setNotifs]   = useState([])
  const [unread, setUnread]   = useState(0)
  const [loading, setLoading] = useState(false)
  const panelRef              = useRef(null)
  const prevUnreadRef         = useRef(0)
  const navigate              = useNavigate()
  const { isAdmin }           = useAuthStore()

  // 1. Ya no pedimos permiso automáticamente al montar (los celulares lo bloquean)
  
  // 2. Función para mostrar notificación nativa
  const showPush = (title, body, data) => {
    // Traducir estados en el cuerpo del mensaje
    let translatedBody = body
    Object.keys(STATUS_MAP).forEach(key => {
      translatedBody = translatedBody.replace(key, STATUS_MAP[key])
    })

    // Si tenemos Service Worker, usamos su registro (mejor para móviles)
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.ready.then(reg => {
        reg.showNotification(title, {
          body: translatedBody,
          icon: '/AppIcon.png',
          badge: '/AppIcon.png',
          vibrate: [100, 50, 100],
          tag: 'cartagena-segura',
          renotify: true,
          data: data
        });
      });
      return;
    }

    // Fallback para navegadores antiguos o si el SW falla
    if (Notification.permission === 'granted') {
      try {
        new Notification(title, { 
          body: translatedBody, 
          icon: '/AppIcon.png', 
          tag: 'cartagena-segura', 
          renotify: true 
        });
      } catch (e) {
        console.error("Error al disparar notificación nativa:", e);
      }
    }
  }

  // 3. Polling para nuevas notificaciones
  useEffect(() => {
    const checkNew = async () => {
      try {
        const r = await notificationService.countUnread()
        const count = Number(r.data?.data ?? 0)

        if (count > prevUnreadRef.current && prevUnreadRef.current !== 0) {
          const res = await notificationService.getUnread()
          const unreads = res.data?.data ?? []
          if (unreads.length > 0) {
            const latest = unreads[0]
            showPush(latest.title, latest.message, latest)
          }
        }
        
        setUnread(count)
        prevUnreadRef.current = count
      } catch (err) { }
    }

    checkNew()
    const interval = setInterval(checkNew, 10000) // 10 segundos
    return () => clearInterval(interval)
  }, [isAdmin, navigate])

  useEffect(() => {
    const handler = e => { if (panelRef.current && !panelRef.current.contains(e.target)) setOpen(false) }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const loadNotifs = () => {
    setLoading(true)
    notificationService.getAll()
      .then(r => setNotifs(r.data?.data ?? r.data ?? []))
      .catch(() => {})
      .finally(() => setLoading(false))
  }

  const handleOpen = () => { 
    setOpen(o => !o)
    if (!open) {
      loadNotifs()
      // SOLICITAR PERMISO AQUÍ (Gesto de usuario)
      if ('Notification' in window) {
        if (Notification.permission === 'default') {
          Notification.requestPermission().then(perm => {
            if (perm === 'granted') toast.success('¡Notificaciones activadas!')
          })
        }
      } else {
        toast.error('Tu navegador no soporta notificaciones push')
      }
    }
  }

  const markRead = async id => {
    try {
      await notificationService.markAsRead(id)
      setNotifs(n => n.map(x => x.id === id ? { ...x, read: true } : x))
      setUnread(u => Math.max(0, u - 1))
    } catch {}
  }

  const markAll = async () => {
    try {
      await notificationService.markAllAsRead()
      setNotifs(n => n.map(x => ({ ...x, read: true })))
      setUnread(0)
      toast.success('Todas marcadas como leídas')
    } catch {}
  }

  const del = async id => {
    try {
      await notificationService.delete(id)
      const wasUnread = notifs.find(x => x.id === id && !x.read)
      setNotifs(n => n.filter(x => x.id !== id))
      if (wasUnread) setUnread(u => Math.max(0, u - 1))
    } catch {}
  }

  const handleNotifClick = (n) => {
    console.log("Notificación tocada:", n)
    
    // Intentamos marcar como leída, pero no bloqueamos la navegación si falla (ej. por el 403)
    if (!n.read) markRead(n.id)
    
    setOpen(false)

    // Buscamos el ID del incidente en los campos posibles (Segun tu backend es relatedEntityId)
    const incId = n.relatedEntityId || n.entityId || n.incidentId || n.targetId || n.referenceId || n.objectId
    console.log("ID del incidente detectado:", incId)

    if (!incId) {
      console.warn("No se encontró un ID de incidente en la notificación. Verifica los campos en la consola arriba.")
      return
    }

    const path = isAdmin() ? '/Admin/Incidents' : '/App/Incidents'
    navigate(`${path}?id=${incId}`)
  }

  return (
    <div style={{ position: 'relative', fontFamily: "'DM Sans', system-ui, sans-serif" }} ref={panelRef}>
      <style>{`
        @keyframes bellRing { 0%,100%{transform:rotate(0)}10%,30%{transform:rotate(-12deg)}20%,40%{transform:rotate(12deg)}50%{transform:rotate(0)} }
        .bell-animate { animation: bellRing 0.6s ease-in-out; }
        .notif-row { transition: all 0.2s; }
        .notif-row:hover { background: #F8FAFC !important; }
      `}</style>

      {/* Bell */}
      <button onClick={handleOpen}
        style={{ position: 'relative', width: 36, height: 36, borderRadius: 10, border: '1px solid #F1F5F9', background: open ? '#F1F5F9' : '#F8FAFC', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.2s' }}>
        <Bell size={16} style={{ color: '#64748B' }} className={unread > 0 ? 'bell-animate' : ''} />
        {unread > 0 && (
          <span style={{ position: 'absolute', top: -4, right: -4, minWidth: 18, height: 18, borderRadius: 100, background: '#EF4444', color: '#fff', fontSize: 10, fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '0 4px', border: '2px solid #fff' }}>
            {unread > 9 ? '9+' : unread}
          </span>
        )}
      </button>

      {/* Panel */}
      {open && (
        <div className="animate-modal-in" style={{ position: 'absolute', right: 0, top: 44, width: 340, background: '#fff', borderRadius: 20, boxShadow: '0 20px 60px rgba(0,0,0,0.15)', border: '1px solid #F1F5F9', overflow: 'hidden', zIndex: 2000 }}>

          {/* Header */}
          <div style={{ padding: '14px 16px', borderBottom: '1px solid #F8FAFC', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <p style={{ fontSize: 14, fontWeight: 700, color: '#0F172A' }}>Notificaciones</p>
              {unread > 0 && <p style={{ fontSize: 11, color: '#94A3B8' }}>{unread} sin leer</p>}
            </div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              {unread > 0 && (
                <button onClick={markAll}
                  style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, fontWeight: 700, color: '#1D4ED8', background: 'rgba(29,78,216,0.08)', border: 'none', padding: '5px 10px', borderRadius: 8, cursor: 'pointer', fontFamily: 'inherit' }}>
                  <CheckCheck size={11} /> Leer todas
                </button>
              )}
              <button onClick={() => setOpen(false)}
                style={{ width: 26, height: 26, borderRadius: 8, border: '1px solid #E2E8F0', background: '#F8FAFC', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <X size={12} style={{ color: '#64748B' }} />
              </button>
            </div>
          </div>

          {/* List */}
          <div style={{ maxHeight: 340, overflowY: 'auto' }}>
            {loading ? (
              <div style={{ padding: 32, textAlign: 'center' }}>
                <Loader2 size={20} style={{ color: '#CBD5E1', animation: 'spin 1s linear infinite', display: 'inline-block' }} />
              </div>
            ) : notifs.length === 0 ? (
              <div style={{ padding: '40px 20px', textAlign: 'center' }}>
                <Bell size={28} style={{ color: '#E2E8F0', display: 'block', margin: '0 auto 10px' }} />
                <p style={{ fontSize: 13, color: '#94A3B8', fontWeight: 600 }}>Sin notificaciones</p>
                <p style={{ fontSize: 11, color: '#CBD5E1', marginTop: 4 }}>Te avisaremos cuando haya novedades</p>
              </div>
            ) : notifs.map((n, i) => (
              <div key={n.id} className="notif-row"
                onClick={() => handleNotifClick(n)}
                style={{ display: 'flex', gap: 12, padding: '12px 14px', borderBottom: i < notifs.length - 1 ? '1px solid #F8FAFC' : 'none', background: !n.read ? 'rgba(29,78,216,0.03)' : '#fff', cursor: 'pointer' }}>
                <div style={{ width: 36, height: 36, borderRadius: 12, background: !n.read ? 'rgba(29,78,216,0.08)' : '#F8FAFC', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16, flexShrink: 0 }}>
                  {TYPE_ICON[n.type] ?? '🔔'}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                    <p style={{ fontSize: 13, fontWeight: 700, color: '#0F172A', flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{n.title}</p>
                    {!n.read && <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#1D4ED8', flexShrink: 0 }} />}
                  </div>
                  <p style={{ fontSize: 11, color: '#64748B', lineHeight: 1.5, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{n.message}</p>
                  {n.createdAt && (
                    <p style={{ fontSize: 10, color: '#CBD5E1', marginTop: 4 }}>
                      {new Date(n.createdAt).toLocaleString('es-CO', { dateStyle: 'short', timeStyle: 'short' })}
                    </p>
                  )}
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4, flexShrink: 0 }} onClick={e => e.stopPropagation()}>
                  {!n.read && (
                    <button onClick={() => markRead(n.id)}
                      style={{ width: 24, height: 24, borderRadius: 7, border: 'none', background: 'rgba(29,78,216,0.08)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Check size={11} style={{ color: '#1D4ED8' }} />
                    </button>
                  )}
                  <button onClick={() => del(n.id)}
                    style={{ width: 24, height: 24, borderRadius: 7, border: 'none', background: 'rgba(239,68,68,0.08)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Trash2 size={11} style={{ color: '#EF4444' }} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

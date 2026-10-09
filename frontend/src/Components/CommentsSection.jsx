import { useEffect, useState, useRef } from 'react'
import { incidentService } from '@/Services/Services'
import useAuthStore from '@/Store/AuthStore'
import {
  MessageCircle, Send, Loader2, Trash2, Shield, Clock,
  ChevronDown, ChevronUp, AlertTriangle
} from 'lucide-react'
import toast from 'react-hot-toast'

/* ── Helpers ─────────────────────────────────────────────────────────── */
function timeAgo(dateStr) {
  if (!dateStr) return ''
  const now = new Date()
  const date = new Date(dateStr)
  const diff = Math.floor((now - date) / 1000)
  if (diff < 60)   return 'Hace un momento'
  if (diff < 3600)  return `Hace ${Math.floor(diff / 60)} min`
  if (diff < 86400) return `Hace ${Math.floor(diff / 3600)}h`
  if (diff < 604800) return `Hace ${Math.floor(diff / 86400)}d`
  return date.toLocaleDateString('es-CO', { day: '2-digit', month: 'short' })
}

function getInitials(name) {
  if (!name) return '?'
  const parts = name.split(' ')
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase()
  return name.slice(0, 2).toUpperCase()
}

const AVATAR_COLORS = [
  '#3B82F6', '#8B5CF6', '#EC4899', '#F59E0B',
  '#10B981', '#EF4444', '#6366F1', '#14B8A6',
]
function avatarColor(name) {
  if (!name) return AVATAR_COLORS[0]
  let hash = 0
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash)
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length]
}

/* ── CommentsSection ─────────────────────────────────────────────────── */
export default function CommentsSection({ incidentId, isAdmin = false }) {
  const [comments, setComments]     = useState([])
  const [loading, setLoading]       = useState(true)
  const [content, setContent]       = useState('')
  const [isInternal, setIsInternal] = useState(false)
  const [sending, setSending]       = useState(false)
  const [expanded, setExpanded]     = useState(true)
  const [deleting, setDeleting]     = useState(null)
  const listRef  = useRef(null)
  const inputRef = useRef(null)

  const user = useAuthStore(s => s.user)
  const currentUsername = user?.username ?? ''

  /* ── Load ── */
  const loadComments = async () => {
    setLoading(true)
    try {
      const res = isAdmin
        ? await incidentService.getAllComments(incidentId)
        : await incidentService.getComments(incidentId)
      setComments(res.data?.data ?? res.data ?? [])
    } catch {
      setComments([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { loadComments() }, [incidentId])

  /* ── Send ── */
  const handleSend = async () => {
    const text = content.trim()
    if (!text) return
    setSending(true)
    try {
      await incidentService.addComment(incidentId, { content: text, isInternal })
      setContent('')
      setIsInternal(false)
      await loadComments()
      toast.success('Comentario enviado')
      // Scroll al final
      setTimeout(() => {
        listRef.current?.scrollTo({ top: listRef.current.scrollHeight, behavior: 'smooth' })
      }, 100)
    } catch {
      toast.error('Error al enviar comentario')
    } finally {
      setSending(false)
    }
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  /* ── Delete ── */
  const handleDelete = async (commentId) => {
    setDeleting(commentId)
    try {
      await incidentService.deleteComment(incidentId, commentId)
      toast.success('Comentario eliminado')
      await loadComments()
    } catch {
      toast.error('Error al eliminar')
    } finally {
      setDeleting(null)
    }
  }

  return (
    <div style={{ borderRadius: 16, border: '1px solid #E2E8F0', overflow: 'hidden', background: '#fff' }}>
      <style>{`
        @keyframes commentIn { from { opacity:0; transform:translateY(8px) } to { opacity:1; transform:translateY(0) } }
        .comment-item { animation: commentIn 250ms ease-out both; }
        .comment-input { 
          width:100%; padding:10px 14px; background:#F8FAFC; border:1px solid #E2E8F0;
          border-radius:12px; font-size:13px; color:#0F172A; font-family:inherit;
          outline:none; resize:none; transition:all 0.2s; box-sizing:border-box; line-height:1.5;
        }
        .comment-input:focus { border-color:#3B82F6; box-shadow:0 0 0 3px rgba(59,130,246,0.12); background:#fff; }
        .comment-input::placeholder { color:#CBD5E1; }
        .send-btn { 
          transition: all 0.2s; cursor:pointer; border:none; font-family:inherit;
        }
        .send-btn:hover:not(:disabled) { transform: scale(1.05); }
        .send-btn:active:not(:disabled) { transform: scale(0.95); }
        .del-btn { transition: all 0.15s; }
        .del-btn:hover { background: rgba(239,68,68,0.12) !important; }
        .internal-check { accent-color: #F59E0B; cursor: pointer; }
      `}</style>

      {/* ── Header ── */}
      <button
        onClick={() => setExpanded(e => !e)}
        style={{
          width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '14px 16px', background: '#F8FAFC', border: 'none', cursor: 'pointer',
          borderBottom: expanded ? '1px solid #E2E8F0' : 'none', fontFamily: 'inherit',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{
            width: 32, height: 32, borderRadius: 10,
            background: 'linear-gradient(135deg, rgba(59,130,246,0.1), rgba(139,92,246,0.1))',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <MessageCircle size={15} style={{ color: '#3B82F6' }} />
          </div>
          <span style={{ fontSize: 13, fontWeight: 700, color: '#0F172A' }}>
            Comentarios
          </span>
          {!loading && (
            <span style={{
              fontSize: 11, fontWeight: 700, padding: '2px 8px', borderRadius: 8,
              background: 'rgba(59,130,246,0.08)', color: '#3B82F6',
            }}>
              {comments.length}
            </span>
          )}
        </div>
        {expanded
          ? <ChevronUp size={16} style={{ color: '#94A3B8' }} />
          : <ChevronDown size={16} style={{ color: '#94A3B8' }} />
        }
      </button>

      {expanded && (
        <div style={{ display: 'flex', flexDirection: 'column' }}>

          {/* ── Comments List ── */}
          <div
            ref={listRef}
            style={{
              maxHeight: 280, overflowY: 'auto', padding: comments.length > 0 ? '12px 16px' : '0',
              display: 'flex', flexDirection: 'column', gap: 10,
            }}
          >
            {loading ? (
              <div style={{ padding: 32, textAlign: 'center' }}>
                <Loader2 size={18} style={{ color: '#CBD5E1', animation: 'spin 1s linear infinite', display: 'inline-block' }} />
              </div>
            ) : comments.length === 0 ? (
              <div style={{ padding: '28px 20px', textAlign: 'center' }}>
                <MessageCircle size={28} style={{ color: '#E2E8F0', display: 'block', margin: '0 auto 10px' }} />
                <p style={{ fontSize: 13, color: '#94A3B8', fontWeight: 600 }}>Sin comentarios aún</p>
                <p style={{ fontSize: 11, color: '#CBD5E1', marginTop: 4 }}>Sé el primero en comentar</p>
              </div>
            ) : (
              comments.map((c, i) => {
                const isMine = c.username === currentUsername || c.userId === currentUsername
                const color = avatarColor(c.username)

                return (
                  <div
                    key={c.id ?? i}
                    className="comment-item"
                    style={{
                      display: 'flex', gap: 10, alignItems: 'flex-start',
                      animationDelay: `${i * 40}ms`,
                    }}
                  >
                    {/* Avatar */}
                    <div style={{
                      width: 34, height: 34, borderRadius: 10, flexShrink: 0,
                      background: `${color}18`, display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      <span style={{ fontSize: 12, fontWeight: 800, color }}>{getInitials(c.username)}</span>
                    </div>

                    {/* Body */}
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3, flexWrap: 'wrap' }}>
                        <span style={{ fontSize: 12, fontWeight: 700, color: '#0F172A' }}>
                          {c.username ?? 'Usuario'}
                        </span>
                        {c.internal && (
                          <span style={{
                            fontSize: 9, fontWeight: 700, padding: '2px 7px', borderRadius: 6,
                            background: 'rgba(245,158,11,0.1)', color: '#D97706',
                            display: 'flex', alignItems: 'center', gap: 3,
                          }}>
                            <Shield size={8} /> Interno
                          </span>
                        )}
                        <span style={{ fontSize: 10, color: '#CBD5E1', display: 'flex', alignItems: 'center', gap: 3 }}>
                          <Clock size={9} /> {timeAgo(c.createdAt)}
                        </span>
                      </div>
                      <p style={{
                        fontSize: 13, color: '#475569', lineHeight: 1.55,
                        wordBreak: 'break-word',
                      }}>
                        {c.content}
                      </p>
                      {c.updatedAt && (
                        <span style={{ fontSize: 9, color: '#CBD5E1', fontStyle: 'italic' }}>editado</span>
                      )}
                    </div>

                    {/* Delete btn (own comments) */}
                    {isMine && (
                      <button
                        className="del-btn"
                        onClick={() => handleDelete(c.id)}
                        disabled={deleting === c.id}
                        style={{
                          width: 28, height: 28, borderRadius: 8, border: 'none',
                          background: 'rgba(239,68,68,0.06)', display: 'flex', alignItems: 'center',
                          justifyContent: 'center', cursor: 'pointer', flexShrink: 0, marginTop: 2,
                        }}
                      >
                        {deleting === c.id
                          ? <Loader2 size={12} style={{ color: '#EF4444', animation: 'spin 1s linear infinite' }} />
                          : <Trash2 size={12} style={{ color: '#EF4444' }} />
                        }
                      </button>
                    )}
                  </div>
                )
              })
            )}
          </div>

          {/* ── Compose ── */}
          <div style={{
            padding: '12px 16px', borderTop: '1px solid #F1F5F9',
            display: 'flex', flexDirection: 'column', gap: 8,
          }}>
            {/* Internal toggle (admin only) */}
            {isAdmin && (
              <label style={{
                display: 'flex', alignItems: 'center', gap: 6,
                padding: '6px 10px', borderRadius: 8,
                background: isInternal ? 'rgba(245,158,11,0.08)' : 'transparent',
                border: `1px solid ${isInternal ? 'rgba(245,158,11,0.2)' : 'transparent'}`,
                cursor: 'pointer', transition: 'all 0.2s', alignSelf: 'flex-start',
              }}>
                <input
                  type="checkbox"
                  className="internal-check"
                  checked={isInternal}
                  onChange={e => setIsInternal(e.target.checked)}
                  style={{ width: 14, height: 14 }}
                />
                <Shield size={12} style={{ color: isInternal ? '#D97706' : '#CBD5E1' }} />
                <span style={{ fontSize: 11, fontWeight: 600, color: isInternal ? '#D97706' : '#94A3B8' }}>
                  Comentario interno (solo admins)
                </span>
              </label>
            )}

            <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end' }}>
              <textarea
                ref={inputRef}
                className="comment-input"
                rows={1}
                value={content}
                onChange={e => setContent(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder="Escribe un comentario..."
                style={{ flex: 1 }}
              />
              <button
                className="send-btn"
                onClick={handleSend}
                disabled={sending || !content.trim()}
                style={{
                  width: 40, height: 40, borderRadius: 12, flexShrink: 0,
                  background: content.trim()
                    ? 'linear-gradient(135deg, #1D4ED8, #3B82F6)'
                    : '#E2E8F0',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  boxShadow: content.trim() ? '0 4px 12px rgba(29,78,216,0.25)' : 'none',
                }}
              >
                {sending
                  ? <Loader2 size={16} style={{ color: '#fff', animation: 'spin 1s linear infinite' }} />
                  : <Send size={16} style={{ color: content.trim() ? '#fff' : '#94A3B8' }} />
                }
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

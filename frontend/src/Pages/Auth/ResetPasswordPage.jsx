import { useState } from 'react'
import { useNavigate, useSearchParams, Link } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { Eye, EyeOff, Loader2, ShieldCheck, ArrowLeft } from 'lucide-react'
import toast from 'react-hot-toast'
import { authService } from '@/Services/Services'

export default function ResetPasswordPage() {
  const [showPwd, setShowPwd] = useState(false)
  const [loading, setLoading] = useState(false)
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const token = searchParams.get('token')

  const { register, handleSubmit, watch, formState: { errors } } = useForm()
  const password = watch('newPassword')

  const onSubmit = async (data) => {
    if (!token) {
      toast.error('Token de restablecimiento no encontrado')
      return
    }

    setLoading(true)
    try {
      await authService.resetPassword({ token, newPassword: data.newPassword })
      toast.success('Contraseña actualizada correctamente')
      navigate('/Login', { replace: true })
    } catch (err) {
      const msg = err?.response?.data?.message || 'Error al restablecer la contraseña'
      toast.error(msg)
    } finally {
      setLoading(false)
    }
  }

  if (!token) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-[#080d14]">
        <div className="text-center bg-white/10 backdrop-blur border border-white/20 p-8 rounded-2xl max-w-sm">
          <h2 className="text-xl font-bold text-white mb-4">Enlace Inválido</h2>
          <p className="text-white/60 text-sm mb-6">Este enlace de restablecimiento no es válido o ha expirado.</p>
          <Link to="/Login" className="text-blue-400 font-semibold hover:underline">Volver al Inicio</Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative"
      style={{ backgroundImage: 'url(/LoginBg.png)', backgroundSize: 'cover', backgroundPosition: 'center' }}>
      <div className="absolute inset-0 bg-black/60" />
      
      <div className="relative w-full max-w-sm sm:max-w-md animate-slide-up">
        <div className="text-center mb-6 sm:mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-white/10 border border-white/20 rounded-2xl mb-4 backdrop-blur">
             <ShieldCheck className="text-blue-400 w-10 h-10" />
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold text-white tracking-tight">Nueva Contraseña</h1>
          <p className="text-white/60 text-xs sm:text-sm mt-1">Crea una contraseña segura para tu cuenta</p>
        </div>

        <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl sm:rounded-3xl shadow-2xl p-6 sm:p-8">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-white/80 mb-1.5">Nueva Contraseña</label>
              <div className="relative">
                <input type={showPwd ? 'text' : 'password'}
                  className="w-full px-4 py-2.5 bg-white/10 border border-white/20 rounded-xl text-sm text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-white/30 focus:border-transparent transition-all duration-200 pr-10"
                  placeholder="••••••••"
                  {...register('newPassword', { 
                    required: 'La contraseña es requerida',
                    minLength: { value: 8, message: 'Mínimo 8 caracteres' }
                  })} />
                <button type="button" onClick={() => setShowPwd(!showPwd)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-white/40 hover:text-white/80">
                  {showPwd ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
              {errors.newPassword && <p className="text-red-400 text-xs mt-1">{errors.newPassword.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-white/80 mb-1.5">Confirmar Contraseña</label>
              <input type="password"
                className="w-full px-4 py-2.5 bg-white/10 border border-white/20 rounded-xl text-sm text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-white/30 focus:border-transparent transition-all duration-200"
                placeholder="••••••••"
                {...register('confirmPassword', { 
                  required: 'Confirma tu contraseña',
                  validate: value => value === password || 'Las contraseñas no coinciden'
                })} />
              {errors.confirmPassword && <p className="text-red-400 text-xs mt-1">{errors.confirmPassword.message}</p>}
            </div>

            <button type="submit" disabled={loading}
              className="w-full mt-2 px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold rounded-xl transition-all duration-200 disabled:opacity-50 flex items-center justify-center gap-2">
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              {loading ? 'Actualizando...' : 'Cambiar contraseña'}
            </button>
          </form>

          <div className="mt-6 pt-6 border-t border-white/10 text-center">
             <Link to="/Login" className="inline-flex items-center gap-2 text-sm text-white/60 hover:text-white transition-colors">
                <ArrowLeft className="w-4 h-4" />
                Cancelar y volver
             </Link>
          </div>
        </div>
      </div>
    </div>
  )
}

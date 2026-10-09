import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { Loader2, ArrowLeft, Mail } from 'lucide-react'
import toast from 'react-hot-toast'
import { authService } from '@/Services/Services'

export default function ForgotPasswordPage() {
  const [loading, setLoading] = useState(false)
  const [sent, setSent] = useState(false)
  const { register, handleSubmit, formState: { errors } } = useForm()

  const onSubmit = async (data) => {
    setLoading(true)
    try {
      await authService.forgotPassword(data)
      setSent(true)
      toast.success('Enlace de recuperación enviado')
    } catch (err) {
      const msg = err?.response?.data?.message || 'Error al enviar el correo'
      toast.error(msg)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative"
      style={{ backgroundImage: 'url(/LoginBg.png)', backgroundSize: 'cover', backgroundPosition: 'center' }}>
      <div className="absolute inset-0 bg-black/60" />
      
      <div className="relative w-full max-w-sm sm:max-w-md animate-slide-up">
        <div className="text-center mb-6 sm:mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-white/10 border border-white/20 rounded-2xl mb-4 backdrop-blur">
            <img src="/LogoFull.png" alt="Cartagena Segura" className="w-10 h-10 object-contain" />
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold text-white tracking-tight">Recuperar Acceso</h1>
          <p className="text-white/60 text-xs sm:text-sm mt-1">Ingresa tu correo para restablecer tu contraseña</p>
        </div>

        <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl sm:rounded-3xl shadow-2xl p-6 sm:p-8">
          {!sent ? (
            <>
              <h2 className="text-lg font-bold text-white mb-5">Olvidé mi contraseña</h2>
              <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-white/80 mb-1.5">Correo Electrónico</label>
                  <div className="relative">
                    <input type="email"
                      className="w-full px-4 py-2.5 bg-white/10 border border-white/20 rounded-xl text-sm text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-white/30 focus:border-transparent transition-all duration-200"
                      placeholder="ejemplo@correo.com"
                      {...register('email', { 
                        required: 'El correo es requerido',
                        pattern: { value: /^\S+@\S+$/i, message: 'Correo inválido' }
                      })} />
                  </div>
                  {errors.email && <p className="text-red-400 text-xs mt-1">{errors.email.message}</p>}
                </div>
                
                <button type="submit" disabled={loading}
                  className="w-full mt-2 px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold rounded-xl transition-all duration-200 disabled:opacity-50 flex items-center justify-center gap-2">
                  {loading && <Loader2 className="w-4 h-4 animate-spin" />}
                  {loading ? 'Enviando...' : 'Enviar enlace'}
                </button>
              </form>
            </>
          ) : (
            <div className="text-center py-4">
              <div className="w-16 h-16 bg-green-500/20 border border-green-500/30 rounded-full flex items-center justify-center mx-auto mb-4">
                <Mail className="text-green-400 w-8 h-8" />
              </div>
              <h2 className="text-xl font-bold text-white mb-2">¡Correo Enviado!</h2>
              <p className="text-white/60 text-sm mb-6">
                Hemos enviado un enlace de recuperación a tu correo electrónico. Por favor revisa tu bandeja de entrada (y la carpeta de spam).
              </p>
              <button onClick={() => setSent(false)} className="text-blue-400 text-sm font-semibold hover:underline">
                Intentar con otro correo
              </button>
            </div>
          )}

          <div className="mt-6 pt-6 border-t border-white/10">
            <Link to="/Login" className="flex items-center justify-center gap-2 text-sm text-white/60 hover:text-white transition-colors">
              <ArrowLeft className="w-4 h-4" />
              Volver al inicio de sesión
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}

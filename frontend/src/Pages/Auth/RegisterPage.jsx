import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { Loader2 } from 'lucide-react'
import toast from 'react-hot-toast'
import { authService } from '@/Services/Services'

export default function RegisterPage() {
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const { register, handleSubmit, watch, formState: { errors } } = useForm()

  const onSubmit = async (data) => {
    setLoading(true)
    try {
      await authService.register(data)
      toast.success('¡Registro exitoso! Ya puedes iniciar sesión')
      navigate('/Login')
    } catch (err) {
      const status = err?.response?.status
      const message = err?.response?.data?.message || ''
      const lowerMessage = message.toLowerCase()
      
      // Coincidimos exactamente con las Excepciones arrojadas en AuthService.java
      if ((status === 400 || status === 403) && lowerMessage.includes('username')) {
        toast.error('El nombre de usuario ya está en uso.')
      } else if ((status === 400 || status === 403) && lowerMessage.includes('email')) {
        toast.error('El correo electrónico ya está en uso.')
      } else if ((status === 400 || status === 403) && lowerMessage.includes('telefono')) {
        toast.error('El teléfono ya está en uso.')
      } else if (status === 403 || status === 401) {
        toast.error('No autorizado. Intenta de nuevo.')
      } else if (status === 500) {
        toast.error('Error del servidor. Intenta más tarde.')
      } else {
        toast.error('Error al crear la cuenta. Intenta de nuevo.')
      }
    } finally { setLoading(false) }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative"
      style={{ backgroundImage: 'url(/RegisterBg.png)', backgroundSize: 'cover', backgroundPosition: 'center' }}>
      <div className="absolute inset-0 bg-black/60" />
      <div className="relative w-full max-w-sm sm:max-w-md animate-slide-up">
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-16 h-16 sm:w-20 sm:h-20 bg-white/10 border border-white/20 rounded-2xl mb-4 backdrop-blur">
            <img src="/LogoFull.png" alt="Cartagena Segura" className="w-10 h-10 sm:w-14 sm:h-14 object-contain" />
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold text-white">Cartagena Segura</h1>
          <p className="text-white/60 text-xs sm:text-sm mt-1">Regístrate en la comunidad ciudadana</p>
        </div>
        <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl sm:rounded-3xl shadow-2xl p-6 sm:p-8">
          <h2 className="text-lg sm:text-xl font-bold text-white mb-5">Registrarse</h2>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-white/80 mb-1.5">Usuario</label>
                <input className="w-full px-4 py-2.5 bg-white/10 border border-white/20 rounded-xl text-sm text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-white/30 focus:border-transparent transition-all duration-200"
                  placeholder="usuario123"
                  autoCapitalize="none"
                  autoCorrect="off"
                  {...register('username', { required: 'Requerido' })} />
                {errors.username && <p className="text-red-400 text-xs mt-1">{errors.username.message}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium text-white/80 mb-1.5">Nombre Completo</label>
                <input className="w-full px-4 py-2.5 bg-white/10 border border-white/20 rounded-xl text-sm text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-white/30 focus:border-transparent transition-all duration-200"
                  placeholder="Tu nombre"
                  {...register('fullName', { required: 'Requerido' })} />
                {errors.fullName && <p className="text-red-400 text-xs mt-1">{errors.fullName.message}</p>}
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-white/80 mb-1.5">Email</label>
              <input className="w-full px-4 py-2.5 bg-white/10 border border-white/20 rounded-xl text-sm text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-white/30 focus:border-transparent transition-all duration-200"
                type="email" placeholder="correo@ejemplo.com"
                {...register('email', { required: 'Requerido' })} />
              {errors.email && <p className="text-red-400 text-xs mt-1">{errors.email.message}</p>}
            </div>
            <div>
              <label className="block text-sm font-medium text-white/80 mb-1.5">Teléfono</label>
              <input className="w-full px-4 py-2.5 bg-white/10 border border-white/20 rounded-xl text-sm text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-white/30 focus:border-transparent transition-all duration-200"
                placeholder="+57 300 000 0000"
                {...register('phone')} />
            </div>
            <div>
              <label className="block text-sm font-medium text-white/80 mb-1.5">Contraseña</label>
              <input className="w-full px-4 py-2.5 bg-white/10 border border-white/20 rounded-xl text-sm text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-white/30 focus:border-transparent transition-all duration-200"
                type="password" placeholder="••••••••"
                {...register('password', { required: 'Requerido', minLength: { value: 6, message: 'Mínimo 6 caracteres' } })} />
              {errors.password && <p className="text-red-400 text-xs mt-1">{errors.password.message}</p>}
            </div>
            <button type="submit" disabled={loading}
              className="w-full px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold rounded-xl transition-all duration-200 disabled:opacity-50 flex items-center justify-center gap-2">
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              {loading ? 'Registrando...' : 'Registrarse'}
            </button>
          </form>
          <p className="text-center text-sm text-white/60 mt-5">
            ¿Ya tienes cuenta?{' '}
            <Link to="/Login" className="text-blue-400 font-semibold hover:underline">Inicia sesión</Link>
          </p>
        </div>
      </div>
    </div>
  )
}

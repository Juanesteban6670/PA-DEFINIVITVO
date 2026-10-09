import { create } from 'zustand'

const useAuthStore = create((set) => ({
  user:  JSON.parse(localStorage.getItem('user') || 'null'),
  token: localStorage.getItem('token') || null,

  login: (user, token) => {
    localStorage.setItem('token', token)
    localStorage.setItem('user', JSON.stringify(user))
    set({ user, token })
  },

  logout: () => {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    set({ user: null, token: null })
  },

  isAuthenticated: () => !!localStorage.getItem('token'),
  isAdmin: () => {
    const user = JSON.parse(localStorage.getItem('user') || 'null')
    const roles = user?.roles || []
    return roles.some(r => {
      const name = typeof r === 'string' ? r : r?.name
      return name === 'ADMIN' || name === 'ROLE_ADMIN'
    })
  },
}))

export default useAuthStore

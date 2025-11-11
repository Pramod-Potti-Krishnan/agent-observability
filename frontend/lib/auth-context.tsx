'use client'

import { createContext, useContext, useState, useEffect, ReactNode } from 'react'
import { useRouter } from 'next/navigation'
import apiClient from './api-client'

interface User {
  id: string
  email: string
  full_name: string
  workspace_id: string
}

interface AuthContextType {
  user: User | null
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  register: (data: RegisterData) => Promise<void>
}

interface RegisterData {
  email: string
  password: string
  full_name: string
  workspace_name: string
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const router = useRouter()

  // Check for existing token on mount
  useEffect(() => {
    const token = localStorage.getItem('auth_token')
    if (token) {
      fetchCurrentUser()
    } else {
      setLoading(false)
    }
  }, [])

  const fetchCurrentUser = async () => {
    try {
      const response = await apiClient.get('/api/v1/auth/me')
      const userData = response.data
      setUser(userData)
      // Store workspace_id for API requests
      if (userData.workspace_id) {
        localStorage.setItem('workspace_id', userData.workspace_id)
      }
    } catch (error) {
      // Token invalid, clear it
      localStorage.removeItem('auth_token')
      localStorage.removeItem('workspace_id')
    } finally {
      setLoading(false)
    }
  }

  const login = async (email: string, password: string) => {
    const response = await apiClient.post('/api/v1/auth/login', {
      email,
      password
    })

    const { access_token } = response.data
    localStorage.setItem('auth_token', access_token)

    await fetchCurrentUser()
    router.push('/dashboard')
  }

  const logout = () => {
    localStorage.removeItem('auth_token')
    localStorage.removeItem('workspace_id')
    setUser(null)
    router.push('/login')
  }

  const register = async (data: RegisterData) => {
    await apiClient.post('/api/v1/auth/register', data)
    // Auto-login after registration
    await login(data.email, data.password)
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, register }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}

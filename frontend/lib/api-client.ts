import axios from 'axios'

export const apiClient = axios.create({
  baseURL: '',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000, // 30 seconds
})

// Request interceptor to add auth token and workspace ID
apiClient.interceptors.request.use(
  (config) => {
    if (typeof window !== 'undefined') {
      // Add auth token
      const token = localStorage.getItem('auth_token')
      if (token) {
        config.headers.Authorization = `Bearer ${token}`
      }

      // Add workspace ID header
      const workspaceId = localStorage.getItem('workspace_id')

      // DEBUG: Log what we're sending (remove this after debugging)
      console.log('🔍 API Request:', {
        url: config.url,
        method: config.method,
        hasToken: !!token,
        workspaceId: workspaceId,
        workspaceIdLength: workspaceId?.length || 0,
        headers: {
          'Authorization': token ? 'Bearer ***' : 'missing',
          'X-Workspace-ID': workspaceId || 'missing'
        }
      })

      if (workspaceId) {
        config.headers['X-Workspace-ID'] = workspaceId
      }
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      // Server responded with error status
      const status = error.response.status
      const message = error.response.data?.detail || error.message

      if (status === 401) {
        // Unauthorized - clear token and redirect to login
        if (typeof window !== 'undefined') {
          localStorage.removeItem('auth_token')
          // window.location.href = '/login'
        }
      }

      console.error(`API Error [${status}]:`, message)
    } else if (error.request) {
      // Request made but no response
      console.error('Network Error:', error.message)
    } else {
      // Something else happened
      console.error('Error:', error.message)
    }

    return Promise.reject(error)
  }
)

export default apiClient

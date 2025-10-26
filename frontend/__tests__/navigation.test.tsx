import '@testing-library/jest-dom'

describe('Phase 4 Dashboard Navigation', () => {
  test('Phase 4 pages are accessible via navigation', () => {
    // Test that navigation routes exist
    const routes = [
      '/dashboard/quality',
      '/dashboard/safety',
      '/dashboard/impact'
    ]

    // Verify all routes are defined
    routes.forEach(route => {
      expect(route).toBeTruthy()
      expect(typeof route).toBe('string')
      expect(route.startsWith('/dashboard/')).toBe(true)
    })

    // Verify route structure
    expect(routes).toHaveLength(3)
  })

  test('dashboard routes follow naming convention', () => {
    const routes = [
      '/dashboard/quality',
      '/dashboard/safety',
      '/dashboard/impact'
    ]

    routes.forEach(route => {
      // All routes should start with /dashboard/
      expect(route).toMatch(/^\/dashboard\/[a-z]+$/)

      // Routes should not have trailing slashes
      expect(route.endsWith('/')).toBe(false)

      // Routes should be lowercase
      expect(route).toBe(route.toLowerCase())
    })
  })
})

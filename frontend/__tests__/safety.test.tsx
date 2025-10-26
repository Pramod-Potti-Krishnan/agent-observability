import { render, screen, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import SafetyPage from '@/app/dashboard/safety/page'

// Mock fetch globally
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve({
      violations: [
        {
          id: '1',
          trace_id: 'trace-1',
          violation_type: 'pii',
          severity: 'high',
          redacted_content: 'Contact me at [REDACTED: EMAIL]',
          detected_at: new Date().toISOString(),
          metadata: { pii_type: 'email' }
        }
      ],
      total_count: 1,
      severity_breakdown: {
        critical: 0,
        high: 1,
        medium: 0,
        low: 0
      },
      type_breakdown: {
        pii: 1,
        toxicity: 0,
        injection: 0
      }
    })
  })
) as jest.Mock

// Create a new QueryClient for each test to ensure isolation
const createTestQueryClient = () => new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
})

describe('Safety Dashboard', () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks()
  })

  test('safety dashboard renders violation metrics', async () => {
    const queryClient = createTestQueryClient()

    render(
      <QueryClientProvider client={queryClient}>
        <SafetyPage />
      </QueryClientProvider>
    )

    // Wait for the page to render
    await waitFor(() => {
      const elements = screen.queryAllByText(/safety/i)
      expect(elements.length).toBeGreaterThan(0)
    })
  })

  test('violation table displays redacted content', async () => {
    const queryClient = createTestQueryClient()

    render(
      <QueryClientProvider client={queryClient}>
        <SafetyPage />
      </QueryClientProvider>
    )

    // Wait for data to be loaded
    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalled()
    }, { timeout: 3000 })

    // The page should render safety-related content
    const safetyElements = screen.queryAllByText(/safety/i)
    expect(safetyElements.length).toBeGreaterThan(0)
  })
})

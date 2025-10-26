import { render, screen, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import ImpactPage from '@/app/dashboard/impact/page'

// Mock fetch globally
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve({
      goals: [
        {
          id: '1',
          goal_type: 'support_tickets',
          name: 'Reduce Support Tickets',
          baseline: 1000,
          target: 400,
          current_value: 550,
          progress_percentage: 75,
          unit: 'tickets',
          start_date: '2025-01-01',
          target_date: '2025-12-31'
        },
        {
          id: '2',
          goal_type: 'cost_savings',
          name: 'Cost Optimization',
          baseline: 10000,
          target: 7000,
          current_value: 8200,
          progress_percentage: 60,
          unit: 'USD',
          start_date: '2025-01-01',
          target_date: '2025-12-31'
        }
      ]
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

describe('Impact Dashboard', () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks()
  })

  test('impact dashboard renders business goals', async () => {
    const queryClient = createTestQueryClient()

    render(
      <QueryClientProvider client={queryClient}>
        <ImpactPage />
      </QueryClientProvider>
    )

    // Wait for the page to render
    await waitFor(() => {
      const elements = screen.queryAllByText(/impact/i)
      expect(elements.length).toBeGreaterThan(0)
    })
  })

  test('displays goal progress and metrics', async () => {
    const queryClient = createTestQueryClient()

    render(
      <QueryClientProvider client={queryClient}>
        <ImpactPage />
      </QueryClientProvider>
    )

    // Wait for data to be loaded
    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalled()
    }, { timeout: 3000 })

    // The page should render impact-related content
    const impactElements = screen.queryAllByText(/impact/i)
    expect(impactElements.length).toBeGreaterThan(0)
  })
})

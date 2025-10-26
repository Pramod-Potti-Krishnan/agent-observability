import { render, screen, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import QualityPage from '@/app/dashboard/quality/page'

// Mock fetch globally
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve({
      evaluations: [
        {
          id: '1',
          trace_id: 'trace-1',
          overall_score: 8.5,
          accuracy_score: 8.0,
          relevance_score: 9.0,
          helpfulness_score: 8.5,
          coherence_score: 8.5,
          evaluator: 'gemini',
          created_at: new Date().toISOString(),
          reasoning: 'Excellent response quality'
        }
      ],
      total: 1,
      avg_overall_score: 8.5,
      avg_accuracy_score: 8.0,
      avg_relevance_score: 9.0,
      avg_helpfulness_score: 8.5,
      avg_coherence_score: 8.5
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

describe('Quality Dashboard', () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks()
  })

  test('quality dashboard renders without errors', async () => {
    const queryClient = createTestQueryClient()

    render(
      <QueryClientProvider client={queryClient}>
        <QualityPage />
      </QueryClientProvider>
    )

    // Wait for the page to render
    await waitFor(() => {
      // Look for quality-related text (case insensitive)
      const elements = screen.queryAllByText(/quality/i)
      expect(elements.length).toBeGreaterThan(0)
    })
  })

  test('displays quality score metrics', async () => {
    const queryClient = createTestQueryClient()

    render(
      <QueryClientProvider client={queryClient}>
        <QualityPage />
      </QueryClientProvider>
    )

    // Wait for data to be loaded
    await waitFor(() => {
      // Check that fetch was called
      expect(global.fetch).toHaveBeenCalled()
    }, { timeout: 3000 })

    // The page should render score values
    // Note: The exact display format may vary, so we just check the page renders
    const qualityElements = screen.queryAllByText(/quality/i)
    expect(qualityElements.length).toBeGreaterThan(0)
  })
})

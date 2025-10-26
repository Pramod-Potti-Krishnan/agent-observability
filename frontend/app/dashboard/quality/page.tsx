'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Skeleton } from '@/components/ui/skeleton'
import { QualityScoreCard } from '@/components/quality/QualityScoreCard'
import { QualityTrendChart } from '@/components/quality/QualityTrendChart'
import { CriteriaBreakdown } from '@/components/quality/CriteriaBreakdown'
import { EvaluationTable } from '@/components/quality/EvaluationTable'
import { QualityFilters } from '@/components/quality/QualityFilters'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

interface Evaluation {
  id: string
  workspace_id: string
  trace_id: string
  created_at: string
  evaluator: string
  accuracy_score: number | null
  relevance_score: number | null
  helpfulness_score: number | null
  coherence_score: number | null
  overall_score: number
  reasoning: string | null
  metadata: Record<string, any>
}

interface EvaluationHistory {
  evaluations: Evaluation[]
  total: number
  avg_overall_score: number
  avg_accuracy_score: number
  avg_relevance_score: number
  avg_helpfulness_score: number
  avg_coherence_score: number
}

interface TrendDataPoint {
  date: string
  avg_score: number
}

export default function QualityPage() {
  const { user } = useAuth()
  const [timeRange, setTimeRange] = useState('7d')

  // Fetch evaluation history
  const { data: historyData, isLoading: historyLoading, error: historyError } = useQuery({
    queryKey: ['evaluation-history', timeRange],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/evaluate/history?range=${timeRange}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data as EvaluationHistory
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000, // Refresh every 30 seconds
  })

  // Fetch previous period data for trend calculation
  const { data: previousData } = useQuery({
    queryKey: ['evaluation-history-previous', timeRange],
    queryFn: async () => {
      // Calculate previous period range
      const ranges: Record<string, string> = {
        '24h': '48h',
        '7d': '14d',
        '30d': '60d'
      }
      const prevRange = ranges[timeRange] || '14d'

      const response = await apiClient.get(`/api/v1/evaluate/history?range=${prevRange}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data as EvaluationHistory
    },
    enabled: !!user?.workspace_id && !!historyData,
  })

  // Calculate trend percentage
  const calculateTrend = () => {
    if (!historyData || !previousData) return 0

    const currentAvg = historyData.avg_overall_score || 0
    const previousAvg = previousData.avg_overall_score || 0

    if (previousAvg === 0) return 0

    return ((currentAvg - previousAvg) / previousAvg) * 100
  }

  // Aggregate trend data by date
  const getTrendData = (): TrendDataPoint[] => {
    if (!historyData?.evaluations || historyData.evaluations.length === 0) return []

    // Group evaluations by date
    const grouped = historyData.evaluations.reduce((acc, evaluation) => {
      const date = new Date(evaluation.created_at).toISOString().split('T')[0]
      if (!acc[date]) {
        acc[date] = { total: 0, count: 0 }
      }
      acc[date].total += evaluation.overall_score
      acc[date].count += 1
      return acc
    }, {} as Record<string, { total: number; count: number }>)

    // Convert to array and calculate averages
    return Object.entries(grouped)
      .map(([date, data]) => ({
        date: new Date(date).toISOString(),
        avg_score: data.total / data.count
      }))
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
  }

  // Get criteria breakdown data
  const getCriteriaData = () => ({
    accuracy: historyData?.avg_accuracy_score || 0,
    relevance: historyData?.avg_relevance_score || 0,
    helpfulness: historyData?.avg_helpfulness_score || 0,
    coherence: historyData?.avg_coherence_score || 0
  })

  // Additional KPI metrics
  const totalEvaluations = historyData?.total || 0
  const avgScore = historyData?.avg_overall_score || 0
  const trendPercentage = calculateTrend()

  // Count evaluations by score range
  const getScoreDistribution = () => {
    if (!historyData?.evaluations) return { excellent: 0, good: 0, poor: 0 }

    return historyData.evaluations.reduce((acc, eval_item) => {
      if (eval_item.overall_score >= 8) acc.excellent++
      else if (eval_item.overall_score >= 6) acc.good++
      else acc.poor++
      return acc
    }, { excellent: 0, good: 0, poor: 0 })
  }

  const distribution = getScoreDistribution()

  if (historyError) {
    return (
      <div className="p-8">
        <h1 className="text-3xl font-bold mb-6">Quality Metrics</h1>
        <Alert variant="destructive">
          <AlertDescription>
            Failed to load quality metrics. Please try again later.
          </AlertDescription>
        </Alert>
      </div>
    )
  }

  return (
    <div className="p-8 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Quality Metrics</h1>
          <p className="text-muted-foreground">
            Monitor AI agent output quality with LLM-based evaluations
          </p>
        </div>
        <QualityFilters timeRange={timeRange} onTimeRangeChange={setTimeRange} />
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <QualityScoreCard
          score={avgScore}
          trend={trendPercentage}
          timeRange={timeRange}
          loading={historyLoading}
        />

        <Card className="hover:shadow-lg transition-shadow">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Evaluations
            </CardTitle>
          </CardHeader>
          <CardContent>
            {historyLoading ? (
              <Skeleton className="h-12 w-24" />
            ) : (
              <>
                <div className="text-3xl font-bold">{totalEvaluations.toLocaleString()}</div>
                <p className="text-xs text-muted-foreground mt-1">
                  in last {timeRange}
                </p>
              </>
            )}
          </CardContent>
        </Card>

        <Card className="hover:shadow-lg transition-shadow">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Excellent Scores
            </CardTitle>
          </CardHeader>
          <CardContent>
            {historyLoading ? (
              <Skeleton className="h-12 w-24" />
            ) : (
              <>
                <div className="text-3xl font-bold text-green-600">
                  {distribution.excellent}
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  Score &ge; 8.0 ({totalEvaluations > 0 ? ((distribution.excellent / totalEvaluations) * 100).toFixed(1) : 0}%)
                </p>
              </>
            )}
          </CardContent>
        </Card>

        <Card className="hover:shadow-lg transition-shadow">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Needs Improvement
            </CardTitle>
          </CardHeader>
          <CardContent>
            {historyLoading ? (
              <Skeleton className="h-12 w-24" />
            ) : (
              <>
                <div className="text-3xl font-bold text-red-600">
                  {distribution.poor}
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  Score &lt; 6.0 ({totalEvaluations > 0 ? ((distribution.poor / totalEvaluations) * 100).toFixed(1) : 0}%)
                </p>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Quality Trend Chart */}
      <QualityTrendChart data={getTrendData()} loading={historyLoading} />

      {/* Criteria Breakdown Chart */}
      <CriteriaBreakdown data={getCriteriaData()} loading={historyLoading} />

      {/* Recent Evaluations Table */}
      <EvaluationTable
        evaluations={historyData?.evaluations || []}
        loading={historyLoading}
      />
    </div>
  )
}

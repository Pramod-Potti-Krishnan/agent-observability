'use client'
export const dynamic = 'force-dynamic'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Skeleton } from '@/components/ui/skeleton'
import { Badge } from '@/components/ui/badge'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { useFilters } from '@/lib/filter-context'

// Existing components
import { QualityScoreCard } from '@/components/quality/QualityScoreCard'
import { QualityTrendChart } from '@/components/quality/QualityTrendChart'
import { CriteriaBreakdown } from '@/components/quality/CriteriaBreakdown'
import { EvaluationTable } from '@/components/quality/EvaluationTable'
import { FilterBar } from '@/components/filters/FilterBar'

// New L0 components
import { QualityDistributionChart } from '@/components/quality/QualityDistributionChart'
import { TopFailingAgentsTable } from '@/components/quality/TopFailingAgentsTable'
import { QualityCostTradeoff } from '@/components/quality/QualityCostTradeoff'
import { RubricHeatmap } from '@/components/quality/RubricHeatmap'
import { DriftTimelineChart } from '@/components/quality/DriftTimelineChart'

// Action modals
import { ConfigureRubricModal } from '@/components/quality/actions/ConfigureRubricModal'
import { SetQualityAlertModal } from '@/components/quality/actions/SetQualityAlertModal'
import { PromptOptimizationModal } from '@/components/quality/actions/PromptOptimizationModal'

import { Settings, Bell, Sparkles, TrendingDown, AlertTriangle, Target } from 'lucide-react'

interface QualityOverview {
  avg_score: number
  total_evaluations: number
  at_risk_agents: number
  score_trend: 'improving' | 'stable' | 'degrading'
}

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
  const { filters } = useFilters()

  // Modal states
  const [isRubricModalOpen, setIsRubricModalOpen] = useState(false)
  const [isAlertModalOpen, setIsAlertModalOpen] = useState(false)
  const [isOptimizationModalOpen, setIsOptimizationModalOpen] = useState(false)
  const [selectedAgentId, setSelectedAgentId] = useState<string | undefined>(undefined)

  // Fetch quality overview from new endpoint
  const { data: overviewData, isLoading: overviewLoading, error: overviewError } = useQuery({
    queryKey: ['quality-overview', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/quality/overview?range=${filters.range}`)
      return response.data as QualityOverview
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000,
  })

  // Fetch evaluation history (for backward compatibility with existing components)
  const { data: historyData, isLoading: historyLoading, error: historyError } = useQuery({
    queryKey: ['evaluation-history', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/evaluate/history?range=${filters.range}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data as EvaluationHistory
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 30000,
  })

  // Fetch previous period data for trend calculation
  const { data: previousData } = useQuery({
    queryKey: ['evaluation-history-previous', filters.range],
    queryFn: async () => {
      const ranges: Record<string, string> = {
        '1h': '2h',
        '24h': '48h',
        '7d': '14d',
        '30d': '60d'
      }
      const prevRange = ranges[filters.range] || '14d'

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

    const grouped = historyData.evaluations.reduce((acc, evaluation) => {
      const date = new Date(evaluation.created_at).toISOString().split('T')[0]
      if (!acc[date]) {
        acc[date] = { total: 0, count: 0 }
      }
      acc[date].total += evaluation.overall_score
      acc[date].count += 1
      return acc
    }, {} as Record<string, { total: number; count: number }>)

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

  // KPI metrics with null safety
  const avgScore = overviewData?.avg_score ?? historyData?.avg_overall_score ?? 0
  const totalEvaluations = overviewData?.total_evaluations ?? historyData?.total ?? 0
  const atRiskAgents = overviewData?.at_risk_agents ?? 0
  const trendPercentage = calculateTrend() || 0

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

  if (overviewError || historyError) {
    return (
      <div className="p-8">
        <h1 className="text-3xl font-bold mb-6">Quality Monitoring</h1>
        <Alert variant="destructive">
          <AlertDescription>
            Failed to load quality metrics. Please try again later.
          </AlertDescription>
        </Alert>
      </div>
    )
  }

  return (
    <div>
      {/* Global Filter Bar */}
      <FilterBar />

      <div className="p-8 space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold">Quality Monitoring</h1>
        <p className="text-muted-foreground">
          Monitor and optimize AI agent response quality with evaluation metrics
        </p>
      </div>

      {/* Action Buttons */}
      <div className="flex items-center gap-3">
        <Button variant="outline" size="sm" onClick={() => setIsRubricModalOpen(true)}>
          <Settings className="h-4 w-4 mr-2" />
          Configure Rubric
        </Button>
        <Button variant="outline" size="sm" onClick={() => setIsAlertModalOpen(true)}>
          <Bell className="h-4 w-4 mr-2" />
          Set Alert
        </Button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <QualityScoreCard
          score={avgScore}
          trend={trendPercentage}
          timeRange={filters.range}
          loading={overviewLoading || historyLoading}
        />

        <Card className="hover:shadow-lg transition-shadow">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Evaluations
            </CardTitle>
          </CardHeader>
          <CardContent>
            {overviewLoading ? (
              <Skeleton className="h-12 w-24" />
            ) : (
              <>
                <div className="text-3xl font-bold">{totalEvaluations.toLocaleString()}</div>
                <p className="text-xs text-muted-foreground mt-1">
                  in last {filters.range}
                </p>
              </>
            )}
          </CardContent>
        </Card>

        <Card className="hover:shadow-lg transition-shadow">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              At-Risk Agents
            </CardTitle>
          </CardHeader>
          <CardContent>
            {overviewLoading ? (
              <Skeleton className="h-12 w-24" />
            ) : (
              <>
                <div className="flex items-center gap-2">
                  <div className={`text-3xl font-bold ${atRiskAgents > 0 ? 'text-red-600' : 'text-green-600'}`}>
                    {atRiskAgents}
                  </div>
                  {atRiskAgents > 0 && <AlertTriangle className="h-5 w-5 text-red-600" />}
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  {atRiskAgents > 0 ? 'Agents below quality threshold' : 'All agents performing well'}
                </p>
              </>
            )}
          </CardContent>
        </Card>

        <Card className="hover:shadow-lg transition-shadow">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Quality Trend
            </CardTitle>
          </CardHeader>
          <CardContent>
            {overviewLoading ? (
              <Skeleton className="h-12 w-24" />
            ) : (
              <>
                <div className="flex items-center gap-2">
                  {overviewData?.score_trend === 'improving' && (
                    <>
                      <Target className="h-5 w-5 text-green-600" />
                      <Badge variant="default" className="bg-green-100 text-green-800">Improving</Badge>
                    </>
                  )}
                  {overviewData?.score_trend === 'degrading' && (
                    <>
                      <TrendingDown className="h-5 w-5 text-red-600" />
                      <Badge variant="destructive">Degrading</Badge>
                    </>
                  )}
                  {overviewData?.score_trend === 'stable' && (
                    <Badge variant="secondary">Stable</Badge>
                  )}
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  {trendPercentage > 0 ? '+' : ''}{trendPercentage.toFixed(1)}% vs previous period
                </p>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Quality Drift Timeline - New L0 Component */}
      <DriftTimelineChart />

      {/* Quality Distribution - New L0 Component */}
      <QualityDistributionChart />

      {/* Two-column layout for charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Quality Trend Chart (existing) */}
        <QualityTrendChart data={getTrendData()} loading={historyLoading} />

        {/* Criteria Breakdown (existing) */}
        <CriteriaBreakdown data={getCriteriaData()} loading={historyLoading} />
      </div>

      {/* Top Failing Agents Table - New L0 Component */}
      <TopFailingAgentsTable />

      {/* Quality vs Cost Tradeoff - New L0 Component */}
      <QualityCostTradeoff />

      {/* Rubric Heatmap - New L0 Component */}
      <RubricHeatmap />

      {/* Recent Evaluations Table (existing) */}
      <EvaluationTable
        evaluations={historyData?.evaluations || []}
        loading={historyLoading}
      />

      {/* Action Modals */}
      <ConfigureRubricModal
        isOpen={isRubricModalOpen}
        onClose={() => setIsRubricModalOpen(false)}
      />

      <SetQualityAlertModal
        isOpen={isAlertModalOpen}
        onClose={() => {
          setIsAlertModalOpen(false)
          setSelectedAgentId(undefined)
        }}
        agentId={selectedAgentId}
      />

      <PromptOptimizationModal
        isOpen={isOptimizationModalOpen}
        onClose={() => {
          setIsOptimizationModalOpen(false)
          setSelectedAgentId(undefined)
        }}
        agentId={selectedAgentId || 'sample-agent-id'}
      />
      </div>
    </div>
  )
}

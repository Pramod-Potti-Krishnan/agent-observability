'use client'
export const dynamic = 'force-dynamic'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { KPICard } from '@/components/dashboard/KPICard'
import { FilterBar } from '@/components/filters/FilterBar'
import { useFilters } from '@/lib/filter-context'
import { DepartmentBudget } from '@/components/cost/DepartmentBudget'
import { ProviderComparison } from '@/components/cost/ProviderComparison'
import { CostOptimizationLeaderboard } from '@/components/cost/CostOptimizationLeaderboard'
import { TopCostlyAgentsTable } from '@/components/cost/TopCostlyAgentsTable'
import { CostAttributionSunburst } from '@/components/cost/CostAttributionSunburst'
import { TokenUsageWaterfall } from '@/components/cost/TokenUsageWaterfall'
import { CostForecastChart } from '@/components/cost/CostForecastChart'
import { ProviderCostPerformanceMatrix } from '@/components/cost/ProviderCostPerformanceMatrix'
import { CachingROICalculator } from '@/components/cost/CachingROICalculator'
import { CostAnomalyTimeline } from '@/components/cost/CostAnomalyTimeline'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Skeleton } from '@/components/ui/skeleton'
import { Progress } from '@/components/ui/progress'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import { AlertTriangle, DollarSign, TrendingUp, Bell, Lightbulb, Download, Target, Eye } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { SetBudgetAlertModal } from '@/components/cost/actions/SetBudgetAlertModal'
import { OptimizationRecommendationsModal } from '@/components/cost/actions/OptimizationRecommendationsModal'
import { ExportCostReportModal } from '@/components/cost/actions/ExportCostReportModal'
import { CompareProvidersModal } from '@/components/cost/actions/CompareProvidersModal'
import { CostAnomalyDetailsModal } from '@/components/cost/actions/CostAnomalyDetailsModal'

interface CostOverview {
  total_spend_usd: number
  budget_limit_usd: number | null
  budget_remaining_usd: number | null
  budget_used_percentage: number | null
  avg_cost_per_call_usd: number
  projected_monthly_spend_usd: number
  change_from_previous: number
}

interface CostTrendItem {
  timestamp: string
  model: string
  total_cost_usd: number
  call_count: number
  avg_cost_per_call_usd: number
}

interface CostByModelItem {
  model: string
  model_provider: string
  total_cost_usd: number
  call_count: number
  avg_cost_per_call_usd: number
  percentage_of_total: number
}

export default function CostPage() {
  const { user } = useAuth()
  const queryClient = useQueryClient()
  const { filters } = useFilters()
  const [budgetLimit, setBudgetLimit] = useState('')
  const [alertThreshold, setAlertThreshold] = useState('')

  // Action modal states
  const [showBudgetModal, setShowBudgetModal] = useState(false)
  const [showOptimizationsModal, setShowOptimizationsModal] = useState(false)
  const [showExportModal, setShowExportModal] = useState(false)
  const [showCompareProvidersModal, setShowCompareProvidersModal] = useState(false)
  const [showAnomalyModal, setShowAnomalyModal] = useState(false)

  // Fetch cost overview
  const { data: overview, isLoading: overviewLoading, error: overviewError } = useQuery({
    queryKey: ['cost-overview', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/cost/overview?range=${filters.range}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data as CostOverview
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 60000, // Refetch every 60s
  })

  // Fetch cost trend
  const { data: costTrend, isLoading: trendLoading } = useQuery({
    queryKey: ['cost-trend', filters.range],
    queryFn: async () => {
      const granularity = filters.range === '1h' || filters.range === '24h' ? 'hourly' : 'daily'
      const response = await apiClient.get(
        `/api/v1/cost/trend?range=${filters.range}&granularity=${granularity}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.data as CostTrendItem[]
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 60000,
  })

  // Fetch cost by model
  const { data: costByModel, isLoading: modelLoading } = useQuery({
    queryKey: ['cost-by-model', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/by-model?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.data as CostByModelItem[]
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 60000,
  })

  // Fetch budget
  const { data: budget } = useQuery({
    queryKey: ['budget'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/cost/budget', {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data
    },
    enabled: !!user?.workspace_id,
  })

  // Update budget mutation
  const updateBudgetMutation = useMutation({
    mutationFn: async (data: { monthly_limit_usd?: number; alert_threshold_percentage?: number }) => {
      const response = await apiClient.put('/api/v1/cost/budget', data, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['budget'] })
      queryClient.invalidateQueries({ queryKey: ['cost-overview'] })
      setBudgetLimit('')
      setAlertThreshold('')
    },
  })

  const handleUpdateBudget = () => {
    const data: any = {}
    if (budgetLimit) data.monthly_limit_usd = parseFloat(budgetLimit)
    if (alertThreshold) data.alert_threshold_percentage = parseFloat(alertThreshold)

    if (Object.keys(data).length > 0) {
      updateBudgetMutation.mutate(data)
    }
  }

  // Transform cost trend data for stacked area chart
  const transformedTrend = costTrend?.reduce((acc, item) => {
    const existing = acc.find(a => a.timestamp === item.timestamp)
    if (existing) {
      existing[item.model] = item.total_cost_usd
    } else {
      acc.push({ timestamp: item.timestamp, [item.model]: item.total_cost_usd })
    }
    return acc
  }, [] as any[])
    ?.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime())

  // Get unique models for the area chart
  const uniqueModels = [...new Set(costTrend?.map(item => item.model) || [])]
  const modelColors = ['#8884d8', '#82ca9d', '#ffc658', '#ff8042', '#0088FE', '#00C49F']

  const budgetUsed = overview?.budget_used_percentage || 0
  const showBudgetWarning = overview?.budget_limit_usd && budgetUsed >= (budget?.alert_threshold_percentage || 80)

  if (overviewError) {
    return (
      <div className="p-8">
        <h1 className="text-3xl font-bold mb-6">Cost Management</h1>
        <Alert variant="destructive">
          <AlertDescription>
            Failed to load cost data. Please try again later.
          </AlertDescription>
        </Alert>
      </div>
    )
  }

  // Show loading state while data is being fetched
  if (overviewLoading) {
    return (
      <div className="p-8">
        <h1 className="text-3xl font-bold mb-6">Cost Management</h1>
        <div className="space-y-4">
          <Skeleton className="h-32 w-full" />
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Skeleton className="h-24 w-full" />
            <Skeleton className="h-24 w-full" />
            <Skeleton className="h-24 w-full" />
            <Skeleton className="h-24 w-full" />
          </div>
        </div>
      </div>
    )
  }

  return (
    <div>
      {/* Enterprise Multi-Dimensional FilterBar */}
      <FilterBar />

      <div className="p-8 space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold">Cost Management</h1>
            <p className="text-muted-foreground">
              Monitor spending, set budgets, and optimize costs across departments and providers
            </p>
          </div>
        </div>

        {/* Quick Actions Toolbar */}
        <div className="flex flex-wrap gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setShowBudgetModal(true)}
            className="flex items-center gap-2"
          >
            <Bell className="h-4 w-4" />
            Set Budget Alert
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setShowOptimizationsModal(true)}
            className="flex items-center gap-2"
          >
            <Lightbulb className="h-4 w-4" />
            View Optimizations
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setShowExportModal(true)}
            className="flex items-center gap-2"
          >
            <Download className="h-4 w-4" />
            Export Report
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setShowCompareProvidersModal(true)}
            className="flex items-center gap-2"
          >
            <Target className="h-4 w-4" />
            Compare Providers
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setShowAnomalyModal(true)}
            className="flex items-center gap-2"
          >
            <Eye className="h-4 w-4" />
            View Anomalies
          </Button>
        </div>

        {/* Budget Warning Alert */}
      {showBudgetWarning && (
        <Alert variant="destructive">
          <AlertTriangle className="h-4 w-4" />
          <AlertTitle>Budget Alert</AlertTitle>
          <AlertDescription>
            You've used {(budgetUsed || 0).toFixed(1)}% of your monthly budget ($
            {overview?.budget_limit_usd?.toLocaleString()}).
            {budgetUsed >= 90 && ' Consider increasing your budget or optimizing costs.'}
          </AlertDescription>
        </Alert>
      )}

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard
          title="Total Spend"
          value={overview ? `$${overview.total_spend_usd.toFixed(2)}` : '—'}
          change={overview?.change_from_previous || 0}
          changeLabel="vs last period"
          trend="inverse"
          loading={overviewLoading}
        />
        <KPICard
          title="Budget Remaining"
          value={
            overview?.budget_remaining_usd !== null && overview?.budget_remaining_usd !== undefined
              ? `$${overview.budget_remaining_usd.toFixed(2)}`
              : 'No budget set'
          }
          change={0}
          changeLabel=""
          trend="normal"
          loading={overviewLoading}
        />
        <KPICard
          title="Avg Cost/Call"
          value={overview ? `$${overview.avg_cost_per_call_usd.toFixed(4)}` : '—'}
          change={0}
          changeLabel=""
          trend="inverse"
          loading={overviewLoading}
        />
        <KPICard
          title="Projected Monthly"
          value={overview ? `$${overview.projected_monthly_spend_usd.toFixed(2)}` : '—'}
          change={0}
          changeLabel=""
          trend="normal"
          loading={overviewLoading}
        />
      </div>

      {/* Budget Progress */}
      {overview?.budget_limit_usd && (
        <Card>
          <CardHeader>
            <CardTitle>Monthly Budget Usage</CardTitle>
            <CardDescription>
              ${budget?.current_spend_usd?.toFixed(2) || '0.00'} of $
              {overview.budget_limit_usd.toLocaleString()} used this month
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            <Progress value={budgetUsed} className="h-3" />
            <div className="flex justify-between text-sm text-muted-foreground">
              <span>{(budgetUsed || 0).toFixed(1)}% used</span>
              <span>${overview?.budget_remaining_usd?.toFixed(2) ?? '0.00'} remaining</span>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Enterprise: Department Budget Dashboard (PRD 3.9) - Traffic Light Alerts */}
      <DepartmentBudget />

      {/* Enterprise: Cost Optimization Leaderboard (PRD 3.10) - P0 Actions */}
      <CostOptimizationLeaderboard />

      {/* Enterprise: Top Costly Agents (PRD 3.11) - Drill-down */}
      <TopCostlyAgentsTable />

      {/* Cost Trend Over Time */}
      <Card>
        <CardHeader>
          <CardTitle>Cost Trend by Model</CardTitle>
        </CardHeader>
        <CardContent>
          {trendLoading ? (
            <Skeleton className="h-[300px] w-full" />
          ) : transformedTrend && transformedTrend.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={transformedTrend}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis
                  dataKey="timestamp"
                  tickFormatter={(value) => new Date(value).toLocaleDateString([], {
                    month: 'short',
                    day: 'numeric'
                  })}
                />
                <YAxis tickFormatter={(value) => `$${value.toFixed(2)}`} />
                <Tooltip
                  labelFormatter={(value) => new Date(value).toLocaleString()}
                  formatter={(value: number) => [`$${value.toFixed(4)}`, 'Cost']}
                />
                <Legend />
                {uniqueModels.map((model, idx) => (
                  <Area
                    key={model}
                    type="monotone"
                    dataKey={model}
                    stackId="1"
                    stroke={modelColors[idx % modelColors.length]}
                    fill={modelColors[idx % modelColors.length]}
                  />
                ))}
              </AreaChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[300px] flex items-center justify-center text-muted-foreground">
              No cost data available for the selected time range
            </div>
          )}
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Cost by Model */}
        <Card>
          <CardHeader>
            <CardTitle>Cost by Model</CardTitle>
          </CardHeader>
          <CardContent>
            {modelLoading ? (
              <Skeleton className="h-[300px] w-full" />
            ) : costByModel && costByModel.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={costByModel} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis type="number" tickFormatter={(value) => `$${value.toFixed(2)}`} />
                  <YAxis dataKey="model" type="category" width={120} />
                  <Tooltip
                    formatter={(value: number) => [`$${value.toFixed(4)}`, 'Total Cost']}
                  />
                  <Bar dataKey="total_cost_usd" fill="#8884d8" />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-[300px] flex items-center justify-center text-muted-foreground">
                No model cost data available
              </div>
            )}
          </CardContent>
        </Card>

        {/* Budget Settings */}
        <Card>
          <CardHeader>
            <CardTitle>Budget Settings</CardTitle>
            <CardDescription>Set monthly budget limits and alert thresholds</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="budget">Monthly Budget Limit ($)</Label>
              <Input
                id="budget"
                type="number"
                placeholder={budget?.monthly_limit_usd?.toString() || '1000.00'}
                value={budgetLimit}
                onChange={(e) => setBudgetLimit(e.target.value)}
                step="0.01"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="threshold">Alert Threshold (%)</Label>
              <Input
                id="threshold"
                type="number"
                placeholder={budget?.alert_threshold_percentage?.toString() || '80'}
                value={alertThreshold}
                onChange={(e) => setAlertThreshold(e.target.value)}
                step="1"
                min="0"
                max="100"
              />
            </div>
            <Button
              onClick={handleUpdateBudget}
              disabled={updateBudgetMutation.isPending || (!budgetLimit && !alertThreshold)}
              className="w-full"
            >
              <DollarSign className="mr-2 h-4 w-4" />
              {updateBudgetMutation.isPending ? 'Updating...' : 'Update Budget'}
            </Button>
            {budget && (
              <div className="pt-4 border-t text-sm text-muted-foreground">
                <p>Current monthly limit: ${budget.monthly_limit_usd?.toLocaleString() || 'Not set'}</p>
                <p>Alert threshold: {budget.alert_threshold_percentage}%</p>
                <p>Current spend: ${budget.current_spend_usd?.toFixed(2)}</p>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Enterprise: Provider Cost & Performance Comparison (PRD 3.6/3.14) */}
      <ProviderComparison />

      {/* Advanced Cost Analytics - Phase 2.1: 6 Enterprise Charts (P1) */}

      {/* PRD 3.1 - Cost Attribution Sunburst: Hierarchical breakdown */}
      <CostAttributionSunburst />

      {/* PRD 3.2 - Token Usage Waterfall: Token flow visualization */}
      <TokenUsageWaterfall />

      {/* PRD 3.3 - Cost Forecast Chart: 30-day predictive modeling */}
      <CostForecastChart />

      {/* PRD 3.4 - Provider Cost/Performance Matrix: Scatter plot analysis */}
      <ProviderCostPerformanceMatrix />

      {/* PRD 3.5 - Caching ROI Calculator: Cache performance metrics */}
      <CachingROICalculator />

      {/* PRD 3.6 - Cost Anomaly Timeline: Unusual spending detection */}
      <CostAnomalyTimeline />
      </div>

      {/* Action Modals */}
      <SetBudgetAlertModal
        open={showBudgetModal}
        onOpenChange={setShowBudgetModal}
        currentBudget={overview?.budget_limit_usd || 0}
        currentThreshold={budget?.alert_threshold_percentage || 80}
      />
      <OptimizationRecommendationsModal
        open={showOptimizationsModal}
        onOpenChange={setShowOptimizationsModal}
        timeRange={filters.range}
      />
      <ExportCostReportModal
        open={showExportModal}
        onOpenChange={setShowExportModal}
      />
      <CompareProvidersModal
        open={showCompareProvidersModal}
        onOpenChange={setShowCompareProvidersModal}
        timeRange={filters.range}
      />
      <CostAnomalyDetailsModal
        open={showAnomalyModal}
        onOpenChange={setShowAnomalyModal}
        timeRange={filters.range}
      />
    </div>
  )
}

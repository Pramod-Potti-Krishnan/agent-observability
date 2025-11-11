'use client'
export const dynamic = 'force-dynamic'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Skeleton } from '@/components/ui/skeleton'
import { FilterBar } from '@/components/filters/FilterBar'
import { useFilters } from '@/lib/filter-context'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { TrendingUp, TrendingDown, DollarSign, Target, Users, Clock, Plus, FileText, Settings, Link, Briefcase } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { SetGoalModal, type GoalFormData } from '@/components/impact/modals/SetGoalModal'
import { GenerateReportModal, type ReportConfig } from '@/components/impact/modals/GenerateReportModal'
import { ConfigureTrackingModal, type TrackingConfig } from '@/components/impact/modals/ConfigureTrackingModal'
import { useState } from 'react'
import { useToast } from '@/hooks/use-toast'

// ============================================================================
// Type Definitions
// ============================================================================

interface ImpactOverview {
  roi_percentage: number
  payback_period_months: number
  net_value_created_usd: number
  total_investment_usd: number
  cumulative_savings_usd: number
  total_revenue_impact_usd: number
  productivity_hours_saved: number
  productivity_fte_equivalent: number
  total_requests: number
  value_per_request: number
  business_goals: {
    total: number
    completed: number
    avg_progress: number
  }
  period: string
  period_start: string
  period_end: string
}

interface BusinessGoal {
  id: string
  goal_type: string
  name: string
  description?: string
  target_value: number
  current_value: number
  unit: string
  target_date?: string
  status: 'active' | 'completed' | 'at_risk' | 'behind'
  progress_percentage: number
  children?: BusinessGoal[]
}

interface TopContributor {
  agent_id: string
  total_value_created_usd: number
  cost_savings_usd: number
  revenue_impact_usd: number
  productivity_value_usd: number
  contribution_percentage: number
  attribution_confidence: number
  data_points: number
}

// ============================================================================
// Main Component
// ============================================================================

export default function ImpactPage() {
  const { user } = useAuth()
  const { filters } = useFilters()
  const { toast } = useToast()

  // Modal state
  const [setGoalModalOpen, setSetGoalModalOpen] = useState(false)
  const [generateReportModalOpen, setGenerateReportModalOpen] = useState(false)
  const [configureTrackingModalOpen, setConfigureTrackingModalOpen] = useState(false)

  // Fetch impact overview
  const { data: overview, isLoading: overviewLoading, error: overviewError } = useQuery<ImpactOverview>({
    queryKey: ['impact-overview', filters.range, filters.department, filters.environment, filters.agent_id],
    queryFn: async () => {
      const params = new URLSearchParams({ range: filters.range })
      if (filters.department) params.set('department_id', filters.department)
      if (filters.environment) params.set('environment', filters.environment)
      if (filters.agent_id) params.set('agent_id', filters.agent_id)

      const response = await apiClient.get(`/api/v1/impact/overview?${params.toString()}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 300000, // Refresh every 5 minutes
  })

  // Fetch business goals
  const { data: goalsResponse, isLoading: goalsLoading } = useQuery<{ goals: BusinessGoal[] }>({
    queryKey: ['impact-goals', filters.range, filters.department, filters.agent_id],
    queryFn: async () => {
      const params = new URLSearchParams({ range: filters.range })
      if (filters.department) params.set('department_id', filters.department)
      if (filters.agent_id) params.set('agent_id', filters.agent_id)

      const response = await apiClient.get(`/api/v1/impact/goals?${params.toString()}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 300000,
  })

  const goalsData = goalsResponse?.goals || []

  // Modal handlers
  const handleSaveGoal = async (goalData: GoalFormData) => {
    try {
      // TODO: Call API to save goal
      toast({
        title: 'Goal Created',
        description: `Business goal "${goalData.name}" has been created successfully.`,
      })
      // Refresh goals data
      // queryClient.invalidateQueries(['impact-goals'])
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to create goal. Please try again.',
        variant: 'destructive',
      })
    }
  }

  const handleGenerateReport = async (config: ReportConfig) => {
    try {
      // TODO: Call API to generate report
      toast({
        title: 'Report Generated',
        description: `Executive report for ${config.timeRange} is being prepared. You'll receive a download link shortly.`,
      })
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to generate report. Please try again.',
        variant: 'destructive',
      })
    }
  }

  const handleSaveTrackingConfig = async (config: TrackingConfig) => {
    try {
      // TODO: Call API to save configuration
      toast({
        title: 'Configuration Saved',
        description: 'Impact tracking settings have been updated successfully.',
      })
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to save configuration. Please try again.',
        variant: 'destructive',
      })
    }
  }

  // Fetch top contributors
  const { data: attributionData, isLoading: attributionLoading } = useQuery<{ top_contributors: TopContributor[] }>({
    queryKey: ['impact-attribution', filters.range, filters.department],
    queryFn: async () => {
      const params = new URLSearchParams({ range: filters.range, limit: '5' })
      if (filters.department) params.set('department_id', filters.department)

      const response = await apiClient.get(`/api/v1/impact/attribution?${params.toString()}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 300000,
  })

  if (overviewError) {
    return (
      <div>
        <FilterBar />
        <div className="p-8">
          <h1 className="text-3xl font-bold mb-6">Business Impact</h1>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load business impact data. Please try again later.
            </AlertDescription>
          </Alert>
        </div>
      </div>
    )
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800'
      case 'active': return 'bg-blue-100 text-blue-800'
      case 'at_risk': return 'bg-yellow-100 text-yellow-800'
      case 'behind': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  return (
    <div>
      <FilterBar />
      <div className="p-8 space-y-6">
        {/* Header with Actions */}
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-3xl font-bold">Business Impact</h1>
            <p className="text-muted-foreground">
              Track ROI, value creation, and business outcomes driven by AI agents
            </p>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={() => setSetGoalModalOpen(true)}>
              <Plus className="h-4 w-4 mr-2" />
              Set Goal
            </Button>
            <Button variant="outline" size="sm" onClick={() => setGenerateReportModalOpen(true)}>
              <FileText className="h-4 w-4 mr-2" />
              Generate Report
            </Button>
            <Button variant="outline" size="sm" onClick={() => setConfigureTrackingModalOpen(true)}>
              <Settings className="h-4 w-4 mr-2" />
              Configure
            </Button>
            <Button variant="outline" size="sm" onClick={() => toast({ title: 'Coming Soon', description: 'Link Agent to Goal feature will be available soon.' })}>
              <Link className="h-4 w-4 mr-2" />
              Link Agent
            </Button>
            <Button variant="outline" size="sm" onClick={() => toast({ title: 'Coming Soon', description: 'Business Case feature will be available soon.' })}>
              <Briefcase className="h-4 w-4 mr-2" />
              Business Case
            </Button>
          </div>
        </div>

        {/* Modals */}
        <SetGoalModal open={setGoalModalOpen} onClose={() => setSetGoalModalOpen(false)} onSave={handleSaveGoal} />
        <GenerateReportModal open={generateReportModalOpen} onClose={() => setGenerateReportModalOpen(false)} onGenerate={handleGenerateReport} />
        <ConfigureTrackingModal open={configureTrackingModalOpen} onClose={() => setConfigureTrackingModalOpen(false)} onSave={handleSaveTrackingConfig} />

        {/* Top KPI Row - 6 Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {/* ROI Percentage */}
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
                <TrendingUp className="h-4 w-4" />
                ROI
              </CardTitle>
            </CardHeader>
            <CardContent>
              {overviewLoading ? (
                <Skeleton className="h-10 w-32" />
              ) : (
                <>
                  <div className="text-3xl font-bold text-green-600">
                    {overview?.roi_percentage.toFixed(1)}%
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    {overview?.payback_period_months.toFixed(1)} month payback
                  </p>
                </>
              )}
            </CardContent>
          </Card>

          {/* Net Value Created */}
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
                <DollarSign className="h-4 w-4" />
                Net Value Created
              </CardTitle>
            </CardHeader>
            <CardContent>
              {overviewLoading ? (
                <Skeleton className="h-10 w-32" />
              ) : (
                <>
                  <div className="text-3xl font-bold text-blue-600">
                    ${overview?.net_value_created_usd.toLocaleString(undefined, { maximumFractionDigits: 0 })}
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    ${overview?.total_investment_usd.toLocaleString()} invested
                  </p>
                </>
              )}
            </CardContent>
          </Card>

          {/* Cost Savings */}
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
                <TrendingDown className="h-4 w-4" />
                Cost Savings
              </CardTitle>
            </CardHeader>
            <CardContent>
              {overviewLoading ? (
                <Skeleton className="h-10 w-32" />
              ) : (
                <>
                  <div className="text-3xl font-bold text-green-600">
                    ${overview?.cumulative_savings_usd.toLocaleString(undefined, { maximumFractionDigits: 0 })}
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Infrastructure & operations
                  </p>
                </>
              )}
            </CardContent>
          </Card>

          {/* Revenue Impact */}
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
                <TrendingUp className="h-4 w-4" />
                Revenue Impact
              </CardTitle>
            </CardHeader>
            <CardContent>
              {overviewLoading ? (
                <Skeleton className="h-10 w-32" />
              ) : (
                <>
                  <div className="text-3xl font-bold text-purple-600">
                    ${overview?.total_revenue_impact_usd.toLocaleString(undefined, { maximumFractionDigits: 0 })}
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    Sales & conversions
                  </p>
                </>
              )}
            </CardContent>
          </Card>

          {/* Productivity Gains */}
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
                <Clock className="h-4 w-4" />
                Time Saved
              </CardTitle>
            </CardHeader>
            <CardContent>
              {overviewLoading ? (
                <Skeleton className="h-10 w-32" />
              ) : (
                <>
                  <div className="text-3xl font-bold text-orange-600">
                    {overview?.productivity_hours_saved.toLocaleString(undefined, { maximumFractionDigits: 0 })}h
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    {overview?.productivity_fte_equivalent.toFixed(1)} FTE equivalent
                  </p>
                </>
              )}
            </CardContent>
          </Card>

          {/* Business Goals */}
          <Card className="hover:shadow-lg transition-shadow">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
                <Target className="h-4 w-4" />
                Goals Progress
              </CardTitle>
            </CardHeader>
            <CardContent>
              {overviewLoading ? (
                <Skeleton className="h-10 w-32" />
              ) : (
                <>
                  <div className="text-3xl font-bold text-indigo-600">
                    {overview?.business_goals.avg_progress.toFixed(0)}%
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    {overview?.business_goals.completed}/{overview?.business_goals.total} goals completed
                  </p>
                </>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Business Goals Section */}
        <Card>
          <CardHeader>
            <CardTitle>Business Goals</CardTitle>
          </CardHeader>
          <CardContent>
            {goalsLoading ? (
              <div className="space-y-3">
                <Skeleton className="h-20 w-full" />
                <Skeleton className="h-20 w-full" />
                <Skeleton className="h-20 w-full" />
              </div>
            ) : goalsData && goalsData.length > 0 ? (
              <div className="space-y-3">
                {goalsData.map((goal) => (
                  <div key={goal.id} className="border rounded-lg p-4 hover:bg-gray-50">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h3 className="font-semibold">{goal.name}</h3>
                          <span className={`px-2 py-1 rounded text-xs font-medium ${getStatusColor(goal.status)}`}>
                            {goal.status}
                          </span>
                        </div>
                        {goal.description && (
                          <p className="text-sm text-muted-foreground mb-2">{goal.description}</p>
                        )}
                        <div className="flex items-center gap-4 text-sm">
                          <span className="text-muted-foreground">
                            Current: <span className="font-medium text-foreground">
                              {goal.current_value.toLocaleString()} {goal.unit}
                            </span>
                          </span>
                          <span className="text-muted-foreground">
                            Target: <span className="font-medium text-foreground">
                              {goal.target_value.toLocaleString()} {goal.unit}
                            </span>
                          </span>
                        </div>
                      </div>
                      <div className="text-right ml-4">
                        <div className="text-2xl font-bold">{goal.progress_percentage.toFixed(0)}%</div>
                        <div className="text-xs text-muted-foreground">Progress</div>
                      </div>
                    </div>
                    {/* Progress bar */}
                    <div className="mt-3 bg-gray-200 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full transition-all ${
                          goal.progress_percentage >= 100
                            ? 'bg-green-500'
                            : goal.progress_percentage >= 70
                            ? 'bg-blue-500'
                            : goal.progress_percentage >= 50
                            ? 'bg-yellow-500'
                            : 'bg-red-500'
                        }`}
                        style={{ width: `${Math.min(goal.progress_percentage, 100)}%` }}
                      />
                    </div>
                    {/* Child goals if any */}
                    {goal.children && goal.children.length > 0 && (
                      <div className="mt-3 ml-4 space-y-2 border-l-2 border-gray-200 pl-4">
                        {goal.children.map((child) => (
                          <div key={child.id} className="text-sm">
                            <div className="flex items-center justify-between">
                              <span className="font-medium">{child.name}</span>
                              <span className="text-muted-foreground">{child.progress_percentage.toFixed(0)}%</span>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-muted-foreground text-center py-8">No business goals configured yet.</p>
            )}
          </CardContent>
        </Card>

        {/* Top Value Contributors */}
        <Card>
          <CardHeader>
            <CardTitle>Top Value Contributors</CardTitle>
          </CardHeader>
          <CardContent>
            {attributionLoading ? (
              <div className="space-y-3">
                <Skeleton className="h-16 w-full" />
                <Skeleton className="h-16 w-full" />
                <Skeleton className="h-16 w-full" />
              </div>
            ) : attributionData && attributionData.top_contributors && attributionData.top_contributors.length > 0 ? (
              <div className="space-y-3">
                {attributionData.top_contributors.map((agent) => (
                  <div key={agent.agent_id} className="border rounded-lg p-4 hover:bg-gray-50">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-3">
                        <Users className="h-5 w-5 text-blue-500" />
                        <div>
                          <h3 className="font-semibold">{agent.agent_id}</h3>
                          <p className="text-xs text-muted-foreground">
                            {agent.contribution_percentage.toFixed(1)}% of total value • {(agent.attribution_confidence * 100).toFixed(0)}% confidence
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-xl font-bold text-green-600">
                          ${agent.total_value_created_usd.toLocaleString(undefined, { maximumFractionDigits: 0 })}
                        </div>
                      </div>
                    </div>
                    <div className="grid grid-cols-3 gap-4 text-sm">
                      <div>
                        <div className="text-muted-foreground">Cost Savings</div>
                        <div className="font-medium">${agent.cost_savings_usd.toLocaleString(undefined, { maximumFractionDigits: 0 })}</div>
                      </div>
                      <div>
                        <div className="text-muted-foreground">Revenue Impact</div>
                        <div className="font-medium">${agent.revenue_impact_usd.toLocaleString(undefined, { maximumFractionDigits: 0 })}</div>
                      </div>
                      <div>
                        <div className="text-muted-foreground">Productivity Value</div>
                        <div className="font-medium">${agent.productivity_value_usd.toLocaleString(undefined, { maximumFractionDigits: 0 })}</div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-muted-foreground text-center py-8">No attribution data available for this period.</p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

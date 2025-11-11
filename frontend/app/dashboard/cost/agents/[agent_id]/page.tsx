'use client'
export const dynamic = 'force-dynamic'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useParams, useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { KPICard } from '@/components/dashboard/KPICard'
import { TimeRangeSelector } from '@/components/dashboard/TimeRangeSelector'
import { ArrowLeft, Bot } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

// Import agent-specific cost components (to be created)
import { AgentCostTrendChart } from '@/components/cost/agent/AgentCostTrendChart'
import { AgentModelBreakdown } from '@/components/cost/agent/AgentModelBreakdown'
import { AgentCostComparison } from '@/components/cost/agent/AgentCostComparison'
import { AgentTokenEfficiency } from '@/components/cost/agent/AgentTokenEfficiency'
import { AgentCostByDepartment } from '@/components/cost/agent/AgentCostByDepartment'

interface AgentCostOverview {
  agent_id: string
  agent_name: string
  total_cost_usd: number
  avg_cost_per_call_usd: number
  total_calls: number
  cost_change_percentage: number
  most_used_model: string
  department: string
  primary_use_case: string
}

/**
 * Agent Cost Detail Page
 *
 * Drill-down view for individual agent cost analytics.
 * Displays comprehensive cost metrics for a specific agent:
 * - Overview KPIs
 * - Cost trends over time
 * - Model usage breakdown
 * - Comparison with similar agents
 * - Token efficiency metrics
 * - Department-level breakdown
 *
 * PRD Tab 3: Section 3.11 - Agent Drill-Down (P0)
 */
export default function AgentCostDetailPage() {
  const params = useParams()
  const router = useRouter()
  const { user } = useAuth()
  const [timeRange, setTimeRange] = useState('7d')

  const agentId = params.agent_id as string

  // Fetch agent cost overview
  const { data: overview, isLoading: overviewLoading, error: overviewError } = useQuery({
    queryKey: ['agent-cost-overview', agentId, timeRange],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/agents/${agentId}?range=${timeRange}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data as AgentCostOverview
    },
    enabled: !!user?.workspace_id && !!agentId,
    refetchInterval: 60000,
  })

  if (overviewError) {
    return (
      <div className="p-8">
        <Button
          variant="ghost"
          onClick={() => router.push('/dashboard/cost')}
          className="mb-4"
        >
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Cost Dashboard
        </Button>
        <Alert variant="destructive">
          <AlertDescription>
            Failed to load agent cost data. Please try again later.
          </AlertDescription>
        </Alert>
      </div>
    )
  }

  if (overviewLoading) {
    return (
      <div className="p-8">
        <Skeleton className="h-10 w-48 mb-6" />
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
    <div className="p-8 space-y-6">
      {/* Header with Back Button */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            onClick={() => router.push('/dashboard/cost')}
            className="h-10"
          >
            <ArrowLeft className="mr-2 h-4 w-4" />
            Back
          </Button>
          <div>
            <div className="flex items-center gap-2">
              <Bot className="h-6 w-6 text-primary" />
              <h1 className="text-3xl font-bold">{overview?.agent_name || agentId}</h1>
            </div>
            <p className="text-muted-foreground mt-1">
              Agent Cost Analytics • {overview?.department || 'Unknown Department'}
            </p>
          </div>
        </div>
        <TimeRangeSelector value={timeRange} onChange={setTimeRange} />
      </div>

      {/* Agent Metadata */}
      {overview && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Agent Information</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
              <div>
                <span className="text-muted-foreground">Agent ID:</span>
                <span className="ml-2 font-mono">{overview.agent_id}</span>
              </div>
              <div>
                <span className="text-muted-foreground">Department:</span>
                <span className="ml-2 font-medium">{overview.department}</span>
              </div>
              <div>
                <span className="text-muted-foreground">Primary Use Case:</span>
                <span className="ml-2 font-medium">{overview.primary_use_case}</span>
              </div>
              <div>
                <span className="text-muted-foreground">Most Used Model:</span>
                <span className="ml-2 font-medium">{overview.most_used_model}</span>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard
          title="Total Cost"
          value={overview ? `$${overview.total_cost_usd.toFixed(2)}` : '—'}
          change={overview?.cost_change_percentage || 0}
          changeLabel="vs last period"
          trend="inverse"
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
          title="Total Calls"
          value={overview ? overview.total_calls.toLocaleString() : '—'}
          change={0}
          changeLabel=""
          trend="normal"
          loading={overviewLoading}
        />
        <KPICard
          title="Cost Trend"
          value={overview ? `${overview.cost_change_percentage > 0 ? '+' : ''}${overview.cost_change_percentage.toFixed(1)}%` : '—'}
          change={overview?.cost_change_percentage || 0}
          changeLabel="vs previous period"
          trend="inverse"
          loading={overviewLoading}
        />
      </div>

      {/* Agent-Specific Cost Charts */}

      {/* Cost Trend Over Time */}
      <AgentCostTrendChart agentId={agentId} timeRange={timeRange} />

      {/* Model Usage Breakdown */}
      <AgentModelBreakdown agentId={agentId} timeRange={timeRange} />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Cost Comparison with Peers */}
        <AgentCostComparison agentId={agentId} timeRange={timeRange} />

        {/* Token Efficiency Metrics */}
        <AgentTokenEfficiency agentId={agentId} timeRange={timeRange} />
      </div>

      {/* Department-Level Cost Breakdown */}
      <AgentCostByDepartment agentId={agentId} timeRange={timeRange} />
    </div>
  )
}

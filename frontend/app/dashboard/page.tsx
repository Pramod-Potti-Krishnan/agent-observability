'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { KPICard } from '@/components/dashboard/KPICard'
import { AlertsFeed } from '@/components/dashboard/AlertsFeed'
import { ActivityStream } from '@/components/dashboard/ActivityStream'
import { TimeRangeSelector } from '@/components/dashboard/TimeRangeSelector'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

interface HomeKPIs {
  total_requests: {
    value: number
    change: number
    change_label: string
    trend: 'normal' | 'inverse'
  }
  avg_latency_ms: {
    value: number
    change: number
    change_label: string
    trend: 'normal' | 'inverse'
  }
  error_rate: {
    value: number
    change: number
    change_label: string
    trend: 'normal' | 'inverse'
  }
  total_cost_usd: {
    value: number
    change: number
    change_label: string
    trend: 'normal' | 'inverse'
  }
  avg_quality_score: {
    value: number
    change: number
    change_label: string
    trend: 'normal' | 'inverse'
  }
}

export default function DashboardPage() {
  const { user } = useAuth()
  const [timeRange, setTimeRange] = useState('7d')

  const { data: kpis, isLoading } = useQuery({
    queryKey: ['home-kpis', timeRange],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/metrics/home-kpis?range=${timeRange}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data as HomeKPIs
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 300000, // Refetch every 5 minutes
  })

  return (
    <div className="p-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold">Dashboard</h1>
          <p className="text-muted-foreground">
            Welcome back, {user?.full_name || 'User'}
          </p>
        </div>
        <TimeRangeSelector value={timeRange} onChange={setTimeRange} />
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-5 gap-4 mb-6">
        <KPICard
          title="Total Requests"
          value={kpis?.total_requests.value.toLocaleString() || '—'}
          change={kpis?.total_requests.change || 0}
          changeLabel={kpis?.total_requests.change_label || ''}
          trend="normal"
          loading={isLoading}
        />
        <KPICard
          title="Avg Latency"
          value={kpis ? `${Math.round(kpis.avg_latency_ms.value)}ms` : '—'}
          change={kpis?.avg_latency_ms.change || 0}
          changeLabel={kpis?.avg_latency_ms.change_label || ''}
          trend="inverse"
          loading={isLoading}
        />
        <KPICard
          title="Error Rate"
          value={kpis ? `${kpis.error_rate.value.toFixed(1)}%` : '—'}
          change={kpis?.error_rate.change || 0}
          changeLabel={kpis?.error_rate.change_label || ''}
          trend="inverse"
          loading={isLoading}
        />
        <KPICard
          title="Total Cost"
          value={kpis ? `$${kpis.total_cost_usd.value.toFixed(2)}` : '—'}
          change={kpis?.total_cost_usd.change || 0}
          changeLabel={kpis?.total_cost_usd.change_label || ''}
          trend="normal"
          loading={isLoading}
        />
        <KPICard
          title="Quality Score"
          value={kpis ? kpis.avg_quality_score.value.toFixed(1) : '—'}
          change={kpis?.avg_quality_score.change || 0}
          changeLabel={kpis?.avg_quality_score.change_label || ''}
          trend="normal"
          loading={isLoading}
        />
      </div>

      {/* Alerts and Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <AlertsFeed />
        <ActivityStream />
      </div>
    </div>
  )
}

'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { TimeRangeSelector } from '@/components/dashboard/TimeRangeSelector'
import { ViolationKPICard } from '@/components/safety/ViolationKPICard'
import { ViolationTrendChart } from '@/components/safety/ViolationTrendChart'
import { TypeBreakdown } from '@/components/safety/TypeBreakdown'
import { ViolationTable } from '@/components/safety/ViolationTable'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

interface Violation {
  id: string
  trace_id: string
  violation_type: string
  severity: string
  detected_content: string
  redacted_content: string
  detected_at: string
}

interface SeverityBreakdown {
  critical: number
  high: number
  medium: number
}

interface TypeBreakdown {
  pii: number
  toxicity: number
  injection: number
}

interface ViolationResponse {
  violations: Violation[]
  total_count: number
  severity_breakdown: SeverityBreakdown
  type_breakdown: TypeBreakdown
  trend_percentage: number
}

export default function SafetyPage() {
  const { user } = useAuth()
  const [timeRange, setTimeRange] = useState('7d')

  // Fetch violations data
  const { data, isLoading, error } = useQuery({
    queryKey: ['violations', timeRange],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/guardrails/violations?range=${timeRange}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data as ViolationResponse
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 60000, // Refresh every 60 seconds
  })

  // Process trend data for chart
  const getTrendData = () => {
    if (!data?.violations || data.violations.length === 0) return []

    // Group violations by date and severity
    const dateMap = new Map<string, { critical: number; high: number; medium: number }>()

    data.violations.forEach(violation => {
      // Skip violations without valid detected_at timestamps
      if (!violation.detected_at) return

      try {
        const date = new Date(violation.detected_at).toISOString().split('T')[0]

        if (!dateMap.has(date)) {
          dateMap.set(date, { critical: 0, high: 0, medium: 0 })
        }

        const entry = dateMap.get(date)!
        if (violation.severity === 'critical') entry.critical++
        else if (violation.severity === 'high') entry.high++
        else if (violation.severity === 'medium') entry.medium++
      } catch (e) {
        // Skip violations with invalid date strings
        console.warn('Invalid date in violation:', violation.detected_at)
      }
    })

    // Convert to array and sort by date
    return Array.from(dateMap.entries())
      .map(([date, counts]) => ({
        date,
        ...counts
      }))
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
  }

  const trendData = getTrendData()

  // Get last 15 violations for table
  const recentViolations = data?.violations
    ?.filter(v => v.detected_at) // Filter out violations without valid timestamps
    .sort((a, b) => {
      // Safe date comparison with fallback
      try {
        const dateA = new Date(a.detected_at).getTime()
        const dateB = new Date(b.detected_at).getTime()
        return dateB - dateA
      } catch (e) {
        return 0
      }
    })
    .slice(0, 15) || []

  if (error) {
    return (
      <div className="p-8">
        <h1 className="text-3xl font-bold mb-6">Safety & Guardrails</h1>
        <Alert variant="destructive">
          <AlertDescription>
            Failed to load safety metrics. Please try again later.
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
          <h1 className="text-3xl font-bold">Safety & Guardrails</h1>
          <p className="text-muted-foreground">
            Monitor PII detection, toxicity, and prompt injection violations
          </p>
        </div>
        <TimeRangeSelector value={timeRange} onChange={setTimeRange} />
      </div>

      {/* KPI Cards - Using 3-column grid with KPI card taking 1 column */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <ViolationKPICard
          totalViolations={data?.total_count || 0}
          criticalCount={data?.severity_breakdown?.critical || 0}
          highCount={data?.severity_breakdown?.high || 0}
          mediumCount={data?.severity_breakdown?.medium || 0}
          trend={data?.trend_percentage || 0}
          loading={isLoading}
        />

        {/* Type Breakdown */}
        <div className="md:col-span-2">
          <TypeBreakdown
            data={{
              pii: data?.type_breakdown?.pii || 0,
              toxicity: data?.type_breakdown?.toxicity || 0,
              injection: data?.type_breakdown?.injection || 0
            }}
            loading={isLoading}
          />
        </div>
      </div>

      {/* Violation Trend Chart */}
      <ViolationTrendChart data={trendData} loading={isLoading} />

      {/* Recent Violations Table */}
      <ViolationTable violations={recentViolations} loading={isLoading} />
    </div>
  )
}

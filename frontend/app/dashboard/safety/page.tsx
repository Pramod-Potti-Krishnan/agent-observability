'use client'
export const dynamic = 'force-dynamic'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Button } from '@/components/ui/button'
import { FilterBar } from '@/components/filters/FilterBar'
import { ViolationKPICard } from '@/components/safety/ViolationKPICard'
import { SafetyScoreCard } from '@/components/safety/SafetyScoreCard'
import { SLAComplianceCard } from '@/components/safety/SLAComplianceCard'
import { ComplianceStatusCard } from '@/components/safety/ComplianceStatusCard'
import { ViolationTrendChart } from '@/components/safety/ViolationTrendChart'
import { TypeBreakdown } from '@/components/safety/TypeBreakdown'
import { RiskHeatmap } from '@/components/safety/RiskHeatmap'
import { PIIBreakdownChart } from '@/components/safety/PIIBreakdownChart'
import { ViolationTable } from '@/components/safety/ViolationTable'
import { TopRiskyAgentsTable } from '@/components/safety/TopRiskyAgentsTable'
import { EnableRuleModal } from '@/components/safety/actions/EnableRuleModal'
import { CreateIncidentModal } from '@/components/safety/actions/CreateIncidentModal'
import { ConfigureRedactionModal } from '@/components/safety/actions/ConfigureRedactionModal'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { useFilters } from '@/lib/filter-context'
import { Shield, Bell, Settings } from 'lucide-react'

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

interface SafetyOverview {
  safety_score: number
  safety_trend: number
  sla_compliance: {
    compliance_rate: number
    total_incidents: number
    within_sla: number
    breached_sla: number
  }
  compliance_status: {
    status: 'compliant' | 'partial' | 'non_compliant'
    active_rules: number
    enabled_policies: string[]
    last_audit: string
  }
}

export default function SafetyPage() {
  const { user } = useAuth()
  const { filters } = useFilters()

  // Modal states
  const [enableRuleModalOpen, setEnableRuleModalOpen] = useState(false)
  const [createIncidentModalOpen, setCreateIncidentModalOpen] = useState(false)
  const [configureRedactionModalOpen, setConfigureRedactionModalOpen] = useState(false)

  // Fetch violations data
  const { data, isLoading, error } = useQuery({
    queryKey: ['violations', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/guardrails/violations?range=${filters.range}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data as ViolationResponse
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 60000, // Refresh every 60 seconds
  })

  // Fetch safety overview data for new KPI cards
  const { data: overviewData, isLoading: overviewLoading } = useQuery({
    queryKey: ['safety-overview', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/guardrails/safety-overview?range=${filters.range}`, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data as SafetyOverview
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 60000,
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
      <div>
        <FilterBar />
        <div className="p-8">
          <h1 className="text-3xl font-bold mb-6">Safety & Guardrails</h1>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load safety metrics. Please try again later.
            </AlertDescription>
          </Alert>
        </div>
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
          <h1 className="text-3xl font-bold">Safety & Guardrails</h1>
          <p className="text-muted-foreground">
            Monitor PII detection, toxicity, and prompt injection violations
          </p>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-3">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setEnableRuleModalOpen(true)}
          >
            <Shield className="h-4 w-4 mr-2" />
            Enable Rule
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setCreateIncidentModalOpen(true)}
          >
            <Bell className="h-4 w-4 mr-2" />
            Create Incident
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setConfigureRedactionModalOpen(true)}
          >
            <Settings className="h-4 w-4 mr-2" />
            Configure Redaction
          </Button>
        </div>

        {/* Action Modals */}
        <EnableRuleModal
          open={enableRuleModalOpen}
          onOpenChange={setEnableRuleModalOpen}
        />
        <CreateIncidentModal
          open={createIncidentModalOpen}
          onOpenChange={setCreateIncidentModalOpen}
        />
        <ConfigureRedactionModal
          open={configureRedactionModalOpen}
          onOpenChange={setConfigureRedactionModalOpen}
        />

      {/* Primary KPI Cards - 4 column grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <SafetyScoreCard
          score={overviewData?.safety_score || 0}
          trend={overviewData?.safety_trend || 0}
          loading={overviewLoading}
        />

        <SLAComplianceCard
          complianceRate={overviewData?.sla_compliance?.compliance_rate || 0}
          totalIncidents={overviewData?.sla_compliance?.total_incidents || 0}
          withinSLA={overviewData?.sla_compliance?.within_sla || 0}
          breachedSLA={overviewData?.sla_compliance?.breached_sla || 0}
          loading={overviewLoading}
        />

        <ComplianceStatusCard
          status={overviewData?.compliance_status?.status || 'non_compliant'}
          activeRules={overviewData?.compliance_status?.active_rules || 0}
          enabledPolicies={overviewData?.compliance_status?.enabled_policies || []}
          lastAudit={overviewData?.compliance_status?.last_audit}
          loading={overviewLoading}
        />

        <ViolationKPICard
          totalViolations={data?.total_count || 0}
          criticalCount={data?.severity_breakdown?.critical || 0}
          highCount={data?.severity_breakdown?.high || 0}
          mediumCount={data?.severity_breakdown?.medium || 0}
          trend={data?.trend_percentage || 0}
          loading={isLoading}
        />
      </div>

      {/* Type Breakdown - Full width */}
      <TypeBreakdown
        data={{
          pii: data?.type_breakdown?.pii || 0,
          toxicity: data?.type_breakdown?.toxicity || 0,
          injection: data?.type_breakdown?.injection || 0
        }}
        loading={isLoading}
      />

      {/* Risk Heatmap - P0 Feature */}
      <RiskHeatmap />

      {/* Top Risky Agents Table - P0 Feature */}
      <TopRiskyAgentsTable limit={20} />

      {/* Two-column layout for charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Violation Trend Chart */}
        <ViolationTrendChart data={trendData} loading={isLoading} />

        {/* PII Breakdown - P0 Feature */}
        <PIIBreakdownChart />
      </div>

      {/* Recent Violations Table */}
      <ViolationTable violations={recentViolations} loading={isLoading} />
      </div>
    </div>
  )
}

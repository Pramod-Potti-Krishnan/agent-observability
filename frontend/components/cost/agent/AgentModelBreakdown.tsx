'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { ResponsiveContainer, PieChart, Pie, Cell, Legend, Tooltip, BarChart, Bar, XAxis, YAxis, CartesianGrid } from 'recharts'
import { Cpu } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

interface ModelBreakdownItem {
  model_name: string
  model_provider: string
  total_cost_usd: number
  call_count: number
  avg_cost_per_call: number
  percentage_of_total: number
}

interface AgentModelBreakdownProps {
  agentId: string
  timeRange: string
}

const COLORS = ['#3b82f6', '#8b5cf6', '#10b981', '#f59e0b', '#ef4444', '#06b6d4']

/**
 * AgentModelBreakdown - Model usage and cost distribution
 *
 * Shows which models the agent uses and their costs:
 * - Pie chart of cost distribution
 * - Bar chart of call counts
 * - Cost per call analysis
 *
 * PRD Tab 3: Agent Detail Component 2
 */
export function AgentModelBreakdown({ agentId, timeRange }: AgentModelBreakdownProps) {
  const { user } = useAuth()

  const { data, isLoading, error } = useQuery({
    queryKey: ['agent-model-breakdown', agentId, timeRange],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/agents/${agentId}/models?range=${timeRange}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.data as ModelBreakdownItem[]
    },
    enabled: !!user?.workspace_id && !!agentId,
    refetchInterval: 60000,
  })

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      return (
        <div className="bg-background border border-border p-3 rounded-lg shadow-lg">
          <p className="font-semibold text-sm mb-2">{data.model_name}</p>
          <div className="space-y-1 text-xs">
            <p>
              <span className="text-muted-foreground">Provider:</span>
              <span className="font-medium ml-2">{data.model_provider}</span>
            </p>
            <p>
              <span className="text-muted-foreground">Cost:</span>
              <span className="font-medium ml-2">${data.total_cost_usd.toFixed(2)}</span>
            </p>
            <p>
              <span className="text-muted-foreground">Calls:</span>
              <span className="font-medium ml-2">{data.call_count.toLocaleString()}</span>
            </p>
            <p>
              <span className="text-muted-foreground">Avg/Call:</span>
              <span className="font-medium ml-2">${data.avg_cost_per_call.toFixed(4)}</span>
            </p>
            <p>
              <span className="text-muted-foreground">Share:</span>
              <span className="font-medium ml-2">{data.percentage_of_total.toFixed(1)}%</span>
            </p>
          </div>
        </div>
      )
    }
    return null
  }

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Cpu className="h-5 w-5" />
            Model Usage Breakdown
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load model breakdown data. Please try again later.
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Cpu className="h-5 w-5" />
          Model Usage Breakdown
        </CardTitle>
        <CardDescription>
          Cost distribution and call volume across models
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[400px] w-full" />
        ) : data && data.length > 0 ? (
          <div className="space-y-6">
            {/* Charts */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Cost Distribution Pie Chart */}
              <div>
                <h4 className="text-sm font-semibold mb-3">Cost Distribution</h4>
                <ResponsiveContainer width="100%" height={250}>
                  <PieChart>
                    <Pie
                      data={data}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percentage_of_total }) => `${name}: ${percentage_of_total.toFixed(0)}%`}
                      outerRadius={80}
                      fill="#8884d8"
                      dataKey="total_cost_usd"
                    >
                      {data.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip content={<CustomTooltip />} />
                  </PieChart>
                </ResponsiveContainer>
              </div>

              {/* Call Count Bar Chart */}
              <div>
                <h4 className="text-sm font-semibold mb-3">Call Volume</h4>
                <ResponsiveContainer width="100%" height={250}>
                  <BarChart data={data} layout="vertical">
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis type="number" tick={{ fontSize: 11 }} />
                    <YAxis dataKey="model_name" type="category" width={100} tick={{ fontSize: 11 }} />
                    <Tooltip content={<CustomTooltip />} />
                    <Bar dataKey="call_count" fill="#10b981" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* Model Details Table */}
            <div>
              <h4 className="text-sm font-semibold mb-3">Model Details</h4>
              <div className="border rounded-lg overflow-hidden">
                <table className="w-full text-sm">
                  <thead className="bg-muted">
                    <tr>
                      <th className="text-left p-3 font-semibold">Model</th>
                      <th className="text-left p-3 font-semibold">Provider</th>
                      <th className="text-right p-3 font-semibold">Cost</th>
                      <th className="text-right p-3 font-semibold">Calls</th>
                      <th className="text-right p-3 font-semibold">Avg/Call</th>
                      <th className="text-right p-3 font-semibold">Share</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.map((model, index) => (
                      <tr key={index} className="border-t hover:bg-muted/50">
                        <td className="p-3 font-medium">{model.model_name}</td>
                        <td className="p-3 text-muted-foreground">{model.model_provider}</td>
                        <td className="p-3 text-right font-medium">${model.total_cost_usd.toFixed(2)}</td>
                        <td className="p-3 text-right">{model.call_count.toLocaleString()}</td>
                        <td className="p-3 text-right text-xs">${model.avg_cost_per_call.toFixed(4)}</td>
                        <td className="p-3 text-right">
                          <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                            {model.percentage_of_total.toFixed(1)}%
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        ) : (
          <div className="h-[400px] flex items-center justify-center text-muted-foreground">
            No model usage data available for this agent
          </div>
        )}
      </CardContent>
    </Card>
  )
}

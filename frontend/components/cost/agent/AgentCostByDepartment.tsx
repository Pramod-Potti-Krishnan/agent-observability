'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, PieChart, Pie, Cell } from 'recharts'
import { Building2, DollarSign } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'

interface DepartmentCostItem {
  department_id: string
  department_name: string
  total_cost_usd: number
  call_count: number
  percentage_of_agent_total: number
}

interface AgentCostByDepartmentProps {
  agentId: string
  timeRange: string
}

const COLORS = ['#3b82f6', '#8b5cf6', '#10b981', '#f59e0b', '#ef4444', '#06b6d4', '#ec4899']

/**
 * AgentCostByDepartment - Department-level cost breakdown
 *
 * Shows which departments use this agent and their costs:
 * - Cost distribution by department
 * - Call volume breakdown
 * - Usage patterns across departments
 *
 * Useful for shared agents used across multiple departments.
 *
 * PRD Tab 3: Agent Detail Component 5
 */
export function AgentCostByDepartment({ agentId, timeRange }: AgentCostByDepartmentProps) {
  const { user } = useAuth()

  const { data, isLoading, error } = useQuery({
    queryKey: ['agent-cost-by-department', agentId, timeRange],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/agents/${agentId}/departments?range=${timeRange}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data.data as DepartmentCostItem[]
    },
    enabled: !!user?.workspace_id && !!agentId,
    refetchInterval: 60000,
  })

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      return (
        <div className="bg-background border border-border p-3 rounded-lg shadow-lg">
          <p className="font-semibold text-sm mb-2">{data.department_name}</p>
          <div className="space-y-1 text-xs">
            <p>
              <span className="text-muted-foreground">Cost:</span>
              <span className="font-medium ml-2">${data.total_cost_usd.toFixed(2)}</span>
            </p>
            <p>
              <span className="text-muted-foreground">Calls:</span>
              <span className="font-medium ml-2">{data.call_count.toLocaleString()}</span>
            </p>
            <p>
              <span className="text-muted-foreground">Share:</span>
              <span className="font-medium ml-2">{data.percentage_of_agent_total.toFixed(1)}%</span>
            </p>
          </div>
        </div>
      )
    }
    return null
  }

  const totalCost = data?.reduce((sum, item) => sum + item.total_cost_usd, 0) || 0
  const totalCalls = data?.reduce((sum, item) => sum + item.call_count, 0) || 0

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Building2 className="h-5 w-5" />
            Cost by Department
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load department breakdown. Please try again later.
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
          <Building2 className="h-5 w-5" />
          Cost by Department
        </CardTitle>
        <CardDescription>
          Agent usage and costs across departments
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[450px] w-full" />
        ) : data && data.length > 0 ? (
          <div className="space-y-6">
            {/* Summary Stats */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <Building2 className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Departments</span>
                </div>
                <p className="text-2xl font-bold">{data.length}</p>
              </div>

              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <DollarSign className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Total Cost</span>
                </div>
                <p className="text-2xl font-bold">${totalCost.toFixed(2)}</p>
              </div>

              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-sm text-muted-foreground">Total Calls</span>
                </div>
                <p className="text-2xl font-bold">{totalCalls.toLocaleString()}</p>
              </div>
            </div>

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
                      label={({ department_name, percentage_of_agent_total }) =>
                        `${department_name}: ${percentage_of_agent_total.toFixed(0)}%`
                      }
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

              {/* Call Volume Bar Chart */}
              <div>
                <h4 className="text-sm font-semibold mb-3">Call Volume by Department</h4>
                <ResponsiveContainer width="100%" height={250}>
                  <BarChart data={data} layout="vertical">
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis type="number" tick={{ fontSize: 11 }} />
                    <YAxis
                      dataKey="department_name"
                      type="category"
                      width={100}
                      tick={{ fontSize: 11 }}
                    />
                    <Tooltip content={<CustomTooltip />} />
                    <Bar dataKey="call_count" fill="#10b981" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* Department Details Table */}
            <div>
              <h4 className="text-sm font-semibold mb-3">Department Details</h4>
              <div className="border rounded-lg overflow-hidden">
                <table className="w-full text-sm">
                  <thead className="bg-muted">
                    <tr>
                      <th className="text-left p-3 font-semibold">Department</th>
                      <th className="text-right p-3 font-semibold">Cost</th>
                      <th className="text-right p-3 font-semibold">Calls</th>
                      <th className="text-right p-3 font-semibold">Avg/Call</th>
                      <th className="text-right p-3 font-semibold">Share</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data
                      .sort((a, b) => b.total_cost_usd - a.total_cost_usd)
                      .map((dept, index) => (
                        <tr key={index} className="border-t hover:bg-muted/50">
                          <td className="p-3">
                            <div className="flex items-center gap-2">
                              <div
                                className="w-3 h-3 rounded"
                                style={{ backgroundColor: COLORS[index % COLORS.length] }}
                              />
                              <span className="font-medium">{dept.department_name}</span>
                            </div>
                          </td>
                          <td className="p-3 text-right font-medium">
                            ${dept.total_cost_usd.toFixed(2)}
                          </td>
                          <td className="p-3 text-right">
                            {dept.call_count.toLocaleString()}
                          </td>
                          <td className="p-3 text-right text-xs">
                            ${(dept.total_cost_usd / Math.max(dept.call_count, 1)).toFixed(4)}
                          </td>
                          <td className="p-3 text-right">
                            <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                              {dept.percentage_of_agent_total.toFixed(1)}%
                            </span>
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Insights */}
            {data.length === 1 ? (
              <div className="bg-amber-50 dark:bg-amber-950 rounded-lg p-3 border border-amber-200 dark:border-amber-800">
                <p className="text-sm text-amber-800 dark:text-amber-200">
                  <strong>Single Department:</strong> This agent is only used by one department.
                  Consider sharing it with other departments to maximize ROI.
                </p>
              </div>
            ) : (
              <div className="bg-blue-50 dark:bg-blue-950 rounded-lg p-3 border border-blue-200 dark:border-blue-800">
                <p className="text-sm text-blue-800 dark:text-blue-200">
                  <strong>Shared Agent:</strong> This agent serves {data.length} departments.
                  Monitor usage patterns to ensure fair cost allocation.
                </p>
              </div>
            )}
          </div>
        ) : (
          <div className="h-[450px] flex items-center justify-center text-muted-foreground">
            No department data available for this agent
          </div>
        )}
      </CardContent>
    </Card>
  )
}

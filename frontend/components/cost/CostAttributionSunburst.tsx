'use client'

import { useQuery } from '@tanstack/react-query'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { ResponsiveContainer, Treemap, Tooltip } from 'recharts'
import { DollarSign, TrendingUp, Layers } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { useFilters } from '@/lib/filter-context'

interface CostNode {
  name: string
  value: number
  percentage: number
  children?: CostNode[]
  level: 'workspace' | 'department' | 'agent' | 'model'
}

interface CostAttributionData {
  root: CostNode
  total_cost: number
  top_contributor: {
    name: string
    cost: number
    percentage: number
  }
}

/**
 * CostAttributionSunburst - Hierarchical cost breakdown visualization
 *
 * Shows cost attribution across multiple levels:
 * - Level 1: Workspace (root)
 * - Level 2: Departments
 * - Level 3: Agents within departments
 * - Level 4: Models per agent
 *
 * Uses Treemap for better space utilization than traditional sunburst.
 * Allows drill-down to explore cost hierarchy.
 *
 * PRD Tab 3: Chart 3.1 - Cost Attribution Sunburst (P0)
 */
export function CostAttributionSunburst() {
  const { user } = useAuth()
  const { filters } = useFilters()

  const { data, isLoading, error } = useQuery({
    queryKey: ['cost-attribution', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/cost/attribution?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      )
      return response.data as CostAttributionData
    },
    enabled: !!user?.workspace_id,
    refetchInterval: 60000, // Refetch every minute
  })

  // Transform hierarchical data to flat format for Treemap
  const flattenData = (node: CostNode, path: string = ''): any[] => {
    const currentPath = path ? `${path} > ${node.name}` : node.name
    const items: any[] = []

    if (node.children && node.children.length > 0) {
      // Parent node
      node.children.forEach(child => {
        items.push(...flattenData(child, currentPath))
      })
    } else {
      // Leaf node
      items.push({
        name: currentPath,
        size: node.value,
        percentage: node.percentage,
        displayName: node.name,
      })
    }

    return items
  }

  const treeData = data?.root ? flattenData(data.root) : []

  // Custom color scale based on cost amount
  const getColor = (percentage: number) => {
    if (percentage > 30) return '#ef4444' // High cost - red
    if (percentage > 15) return '#f59e0b' // Medium cost - amber
    if (percentage > 5) return '#3b82f6'  // Low-medium cost - blue
    return '#10b981' // Low cost - green
  }

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      // Safety check for required values
      if (!data || data.size === undefined || data.percentage === undefined) {
        return null
      }
      return (
        <div className="bg-background border border-border p-3 rounded-lg shadow-lg">
          <p className="font-semibold text-sm mb-1">{data.displayName}</p>
          <p className="text-xs text-muted-foreground mb-1">
            Path: {data.name}
          </p>
          <p className="text-sm font-medium text-primary">
            ${data.size.toFixed(2)} ({data.percentage.toFixed(1)}%)
          </p>
        </div>
      )
    }
    return null
  }

  const CustomContent = (props: any) => {
    const { x, y, width, height, displayName, percentage, size } = props

    // Only show label if rectangle is large enough
    if (width < 80 || height < 40) return null

    // Safety check for required values
    if (size === undefined || percentage === undefined) return null

    return (
      <g>
        <rect
          x={x}
          y={y}
          width={width}
          height={height}
          style={{
            fill: getColor(percentage),
            stroke: '#fff',
            strokeWidth: 2,
            strokeOpacity: 1,
          }}
        />
        <text
          x={x + width / 2}
          y={y + height / 2 - 10}
          textAnchor="middle"
          fill="#fff"
          fontSize={12}
          fontWeight="bold"
        >
          {displayName}
        </text>
        <text
          x={x + width / 2}
          y={y + height / 2 + 8}
          textAnchor="middle"
          fill="#fff"
          fontSize={11}
        >
          ${size.toFixed(2)}
        </text>
        <text
          x={x + width / 2}
          y={y + height / 2 + 24}
          textAnchor="middle"
          fill="#fff"
          fontSize={10}
          opacity={0.9}
        >
          {percentage.toFixed(1)}%
        </text>
      </g>
    )
  }

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Layers className="h-5 w-5" />
            Cost Attribution
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertDescription>
              Failed to load cost attribution data. Please try again later.
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
          <Layers className="h-5 w-5" />
          Cost Attribution Breakdown
        </CardTitle>
        <CardDescription>
          Hierarchical view of costs across departments, agents, and models
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[400px] w-full" />
        ) : data && treeData.length > 0 ? (
          <div className="space-y-4">
            {/* Summary Stats */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <DollarSign className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Total Cost</span>
                </div>
                <p className="text-2xl font-bold">${data.total_cost.toFixed(2)}</p>
              </div>
              <div className="p-4 bg-muted rounded-lg">
                <div className="flex items-center gap-2 mb-1">
                  <TrendingUp className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Top Contributor</span>
                </div>
                <p className="text-lg font-semibold">{data.top_contributor.name}</p>
                <p className="text-sm text-muted-foreground">
                  ${data.top_contributor.cost.toFixed(2)} ({data.top_contributor.percentage.toFixed(1)}%)
                </p>
              </div>
            </div>

            {/* Treemap Visualization */}
            <ResponsiveContainer width="100%" height={400}>
              <Treemap
                data={treeData}
                dataKey="size"
                aspectRatio={4 / 3}
                stroke="#fff"
                fill="#8884d8"
                content={<CustomContent />}
              >
                <Tooltip content={<CustomTooltip />} />
              </Treemap>
            </ResponsiveContainer>

            {/* Legend */}
            <div className="flex items-center justify-center gap-4 text-xs flex-wrap">
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 rounded" style={{ backgroundColor: '#ef4444' }}></div>
                <span>High (&gt;30%)</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 rounded" style={{ backgroundColor: '#f59e0b' }}></div>
                <span>Medium (15-30%)</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 rounded" style={{ backgroundColor: '#3b82f6' }}></div>
                <span>Low-Med (5-15%)</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 rounded" style={{ backgroundColor: '#10b981' }}></div>
                <span>Low (&lt;5%)</span>
              </div>
            </div>

            <p className="text-xs text-muted-foreground text-center mt-2">
              Hover over rectangles to see full path and details. Larger rectangles indicate higher costs.
            </p>
          </div>
        ) : (
          <div className="h-[400px] flex items-center justify-center text-muted-foreground">
            No cost attribution data available for the selected time range
          </div>
        )}
      </CardContent>
    </Card>
  )
}

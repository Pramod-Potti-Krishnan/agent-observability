"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import apiClient from '@/lib/api-client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { AlertTriangle } from 'lucide-react';

interface AdoptionPoint {
  date: string;
  cumulative_users: number;
  cumulative_requests: number;
  adoption_rate: number;
}

interface AgentAdoption {
  agent_id: string;
  agent_version: string;
  launch_date: string;
  data_points: AdoptionPoint[];
  current_adoption_pct: number;
  lifecycle_stage: 'active' | 'beta' | 'deprecated';
}

interface AgentAdoptionResponse {
  agents: AgentAdoption[];
  meta: {
    range: string;
    total_agents: number;
  };
}

/**
 * AgentAdoptionCurves - S-curve adoption tracking for agents
 *
 * Shows adoption trajectory for new agents/versions to track rollout success.
 * - One line per agent/version
 * - X-axis = Days since launch
 * - Y-axis = Cumulative user adoption
 * - Compare against benchmarks
 *
 * PRD Tab 2: Chart 2.10 - Agent Adoption Curve (P1)
 */
export function AgentAdoptionCurves() {
  const { user, loading: authLoading } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<AgentAdoptionResponse>({
    queryKey: ['agent-adoption', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/usage/agent-adoption?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 10 * 60 * 1000,
  });

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Agent Adoption Curves</CardTitle>
          <CardDescription>Loading adoption data...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[350px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.agents.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Agent Adoption Curves</CardTitle>
          <CardDescription>Rollout tracking for new agents and versions</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <AlertTriangle className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Adoption Data Available</p>
            <p className="text-xs text-muted-foreground mt-1">
              No new agent launches detected in the selected time range
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  // Transform data for recharts - merge all agent data points
  const allDataPoints: Record<string, any> = {};

  data.agents.forEach((agent) => {
    agent.data_points.forEach((point) => {
      const key = point.date;
      if (!allDataPoints[key]) {
        allDataPoints[key] = { date: key };
      }
      allDataPoints[key][agent.agent_id] = point.cumulative_users;
    });
  });

  const chartData = Object.values(allDataPoints).sort(
    (a: any, b: any) => new Date(a.date).getTime() - new Date(b.date).getTime()
  );

  const colors = ['#8884d8', '#82ca9d', '#ffc658', '#ff8042', '#0088FE', '#00C49F'];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Agent Adoption Curves</CardTitle>
        <CardDescription>
          Cumulative user adoption for new agents • {data.agents.length} agents tracked • {filters.range}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={350}>
          <LineChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis
              dataKey="date"
              tickFormatter={(value) => new Date(value).toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric'
              })}
            />
            <YAxis label={{ value: 'Cumulative Users', angle: -90, position: 'insideLeft' }} />
            <Tooltip
              labelFormatter={(value) => new Date(value).toLocaleDateString()}
              formatter={(value: number) => [value.toLocaleString(), 'Users']}
            />
            <Legend />
            {data.agents.map((agent, idx) => (
              <Line
                key={agent.agent_id}
                type="monotone"
                dataKey={agent.agent_id}
                stroke={colors[idx % colors.length]}
                strokeWidth={2}
                dot={false}
                name={`${agent.agent_id} (${agent.current_adoption_pct.toFixed(0)}%)`}
              />
            ))}
          </LineChart>
        </ResponsiveContainer>

        {/* Agent Details */}
        <div className="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {data.agents.map((agent, idx) => (
            <div
              key={agent.agent_id}
              className="p-3 border rounded-lg hover:shadow-md transition-shadow"
            >
              <div className="flex items-center justify-between mb-2">
                <div
                  className="w-3 h-3 rounded-full"
                  style={{ backgroundColor: colors[idx % colors.length] }}
                ></div>
                <span className="text-xs px-2 py-1 bg-gray-100 rounded">
                  {agent.lifecycle_stage}
                </span>
              </div>
              <p className="font-medium text-sm truncate" title={agent.agent_id}>
                {agent.agent_id}
              </p>
              <p className="text-xs text-muted-foreground">
                v{agent.agent_version} • Launched{' '}
                {new Date(agent.launch_date).toLocaleDateString('en-US', {
                  month: 'short',
                  day: 'numeric'
                })}
              </p>
              <p className="text-lg font-bold text-blue-600 mt-1">
                {agent.current_adoption_pct.toFixed(1)}%
              </p>
              <p className="text-xs text-muted-foreground">adoption rate</p>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}

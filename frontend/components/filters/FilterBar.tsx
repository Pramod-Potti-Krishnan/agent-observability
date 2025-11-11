"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useFilters } from '@/lib/filter-context';
import { useAuth } from '@/lib/auth-context';
import apiClient from '@/lib/api-client';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { X, Filter } from 'lucide-react';

interface FilterOption {
  code: string;
  name: string;
  count?: number;
}

interface FilterOptionsResponse {
  data: FilterOption[];
  meta: {
    generated_at: string;
    total: number;
  };
}

/**
 * FilterBar component - Multi-dimensional filtering UI
 *
 * Features:
 * - Department, Environment, Version, Agent dropdowns
 * - Time range selector
 * - Cascading filters (versions filtered by dept/env, agents by all)
 * - Shows applied filters with clear buttons
 * - Connects to backend /api/v1/filters/* endpoints
 */
export function FilterBar() {
  const { filters, setFilters, resetFilters, isFiltered } = useFilters();
  const { user, loading: authLoading } = useAuth();

  // Fetch departments
  const { data: departments } = useQuery<FilterOptionsResponse>({
    queryKey: ['filters', 'departments'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/filters/departments');
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  // Fetch environments
  const { data: environments } = useQuery<FilterOptionsResponse>({
    queryKey: ['filters', 'environments'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/filters/environments');
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Fetch versions (cascading - filtered by dept/env)
  const versionsQueryKey = ['filters', 'versions', filters.department, filters.environment];
  const { data: versions } = useQuery<FilterOptionsResponse>({
    queryKey: versionsQueryKey,
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filters.department) params.set('department', filters.department);
      if (filters.environment) params.set('environment', filters.environment);

      const response = await apiClient.get(`/api/v1/filters/versions?${params.toString()}`);
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Fetch agents (cascading - filtered by dept/env/version)
  const agentsQueryKey = ['filters', 'agents', filters.department, filters.environment, filters.version];
  const { data: agents } = useQuery<FilterOptionsResponse>({
    queryKey: agentsQueryKey,
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filters.department) params.set('department', filters.department);
      if (filters.environment) params.set('environment', filters.environment);
      if (filters.version) params.set('version', filters.version);

      const response = await apiClient.get(`/api/v1/filters/agents?${params.toString()}`);
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id && !!(filters.department || filters.environment || filters.version), // Only fetch if parent filters active
    staleTime: 5 * 60 * 1000,
  });

  // Format option display with count
  const formatOption = (option: FilterOption) => {
    if (option.count) {
      return `${option.name} (${option.count.toLocaleString()})`;
    }
    return option.name;
  };

  return (
    <div className="bg-white border-b border-gray-200 py-4 px-6">
      <div className="flex items-center gap-4 flex-wrap">
        <div className="flex items-center gap-2 text-sm font-medium text-gray-700">
          <Filter className="h-4 w-4" />
          <span>Filters</span>
        </div>

        {/* Time Range */}
        <Select value={filters.range} onValueChange={(value) => setFilters({ range: value })}>
          <SelectTrigger className="w-[120px]">
            <SelectValue placeholder="Time range" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="1h">Last Hour</SelectItem>
            <SelectItem value="24h">Last 24 Hours</SelectItem>
            <SelectItem value="7d">Last 7 Days</SelectItem>
            <SelectItem value="30d">Last 30 Days</SelectItem>
          </SelectContent>
        </Select>

        {/* Department */}
        <Select
          value={filters.department || 'all'}
          onValueChange={(value) => setFilters({ department: value === 'all' ? null : value })}
        >
          <SelectTrigger className="w-[200px]">
            <SelectValue placeholder="All Departments" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Departments</SelectItem>
            {departments?.data.map((dept) => (
              <SelectItem key={dept.code} value={dept.code}>
                {formatOption(dept)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        {/* Environment */}
        <Select
          value={filters.environment || 'all'}
          onValueChange={(value) => setFilters({ environment: value === 'all' ? null : value })}
        >
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="All Environments" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Environments</SelectItem>
            {environments?.data.map((env) => (
              <SelectItem key={env.code} value={env.code}>
                {formatOption(env)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        {/* Version */}
        <Select
          value={filters.version || 'all'}
          onValueChange={(value) => setFilters({ version: value === 'all' ? null : value })}
        >
          <SelectTrigger className="w-[150px]">
            <SelectValue placeholder="All Versions" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Versions</SelectItem>
            {versions?.data.map((ver) => (
              <SelectItem key={ver.code} value={ver.code}>
                {formatOption(ver)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        {/* Agent (only show if parent filters active) */}
        {(filters.department || filters.environment || filters.version) && (
          <Select
            value={filters.agent_id || 'all'}
            onValueChange={(value) => setFilters({ agent_id: value === 'all' ? null : value })}
          >
            <SelectTrigger className="w-[200px]">
              <SelectValue placeholder="All Agents" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Agents</SelectItem>
              {agents?.data.map((agent) => (
                <SelectItem key={agent.code} value={agent.code}>
                  {formatOption(agent)}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        )}

        {/* Clear Filters Button */}
        {isFiltered && (
          <Button
            variant="ghost"
            size="sm"
            onClick={resetFilters}
            className="text-gray-600 hover:text-gray-900"
          >
            <X className="h-4 w-4 mr-1" />
            Clear Filters
          </Button>
        )}
      </div>

      {/* Applied Filters Display */}
      {isFiltered && (
        <div className="flex items-center gap-2 mt-3">
          <span className="text-xs text-gray-500">Applied:</span>
          {filters.department && (
            <Badge variant="secondary" className="text-xs">
              Dept: {departments?.data.find(d => d.code === filters.department)?.name || filters.department}
              <button
                onClick={() => setFilters({ department: null })}
                className="ml-1 hover:text-gray-900"
              >
                <X className="h-3 w-3" />
              </button>
            </Badge>
          )}
          {filters.environment && (
            <Badge variant="secondary" className="text-xs">
              Env: {environments?.data.find(e => e.code === filters.environment)?.name || filters.environment}
              <button
                onClick={() => setFilters({ environment: null })}
                className="ml-1 hover:text-gray-900"
              >
                <X className="h-3 w-3" />
              </button>
            </Badge>
          )}
          {filters.version && (
            <Badge variant="secondary" className="text-xs">
              Version: {filters.version}
              <button
                onClick={() => setFilters({ version: null })}
                className="ml-1 hover:text-gray-900"
              >
                <X className="h-3 w-3" />
              </button>
            </Badge>
          )}
          {filters.agent_id && (
            <Badge variant="secondary" className="text-xs">
              Agent: {filters.agent_id}
              <button
                onClick={() => setFilters({ agent_id: null })}
                className="ml-1 hover:text-gray-900"
              >
                <X className="h-3 w-3" />
              </button>
            </Badge>
          )}
        </div>
      )}
    </div>
  );
}

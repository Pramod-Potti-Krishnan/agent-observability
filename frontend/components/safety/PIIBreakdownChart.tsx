"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import apiClient from '@/lib/api-client';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, Cell } from 'recharts';
import { Mail, Phone, CreditCard, MapPin, User, Hash } from 'lucide-react';

interface PIITypeData {
  type: string;
  count: number;
  percentage: number;
}

interface PIIBreakdownData {
  breakdown: PIITypeData[];
  total_pii_violations: number;
}

/**
 * PIIBreakdownChart - Distribution of PII types detected
 *
 * PII Types:
 * - email: Email addresses
 * - phone: Phone numbers
 * - ssn: Social Security Numbers
 * - ip_address: IP addresses
 * - credit_card: Credit card numbers
 * - name: Personal names
 */
export function PIIBreakdownChart() {
  const { user } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<PIIBreakdownData>({
    queryKey: ['pii-breakdown', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/guardrails/pii-breakdown?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    enabled: !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Icon mapping for PII types
  const getIcon = (type: string) => {
    switch (type) {
      case 'email':
        return <Mail className="h-4 w-4" />;
      case 'phone':
        return <Phone className="h-4 w-4" />;
      case 'ssn':
        return <Hash className="h-4 w-4" />;
      case 'ip_address':
        return <MapPin className="h-4 w-4" />;
      case 'credit_card':
        return <CreditCard className="h-4 w-4" />;
      case 'name':
        return <User className="h-4 w-4" />;
      default:
        return <Hash className="h-4 w-4" />;
    }
  };

  // Color mapping for PII types
  const getColor = (type: string): string => {
    const colors: Record<string, string> = {
      email: '#3b82f6',      // blue
      phone: '#10b981',      // green
      ssn: '#ef4444',        // red
      ip_address: '#f59e0b', // amber
      credit_card: '#8b5cf6',// purple
      name: '#ec4899'        // pink
    };
    return colors[type] || '#6b7280';
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>PII Type Breakdown</CardTitle>
          <CardDescription>Loading PII analysis...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[300px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.breakdown.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>PII Type Breakdown</CardTitle>
          <CardDescription>Distribution of detected PII types</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[300px] flex items-center justify-center text-muted-foreground">
            <div className="text-center space-y-2">
              <Mail className="h-12 w-12 mx-auto text-gray-400" />
              <p className="font-medium">No PII Violations</p>
              <p className="text-sm">No PII detected in the selected time range</p>
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>PII Type Breakdown</CardTitle>
        <CardDescription>
          {data.total_pii_violations} total PII violations detected • {filters.range}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-6">
          {/* Bar Chart */}
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={data.breakdown}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis
                dataKey="type"
                tickFormatter={(value) => value.charAt(0).toUpperCase() + value.slice(1).replace('_', ' ')}
              />
              <YAxis />
              <Tooltip
                formatter={(value: number, name: string, props: any) => [
                  `${value} violations (${props.payload.percentage.toFixed(1)}%)`,
                  ''
                ]}
                labelFormatter={(label) => label.charAt(0).toUpperCase() + label.slice(1).replace('_', ' ')}
              />
              <Bar dataKey="count" radius={[8, 8, 0, 0]}>
                {data.breakdown.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={getColor(entry.type)} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>

          {/* Detailed Breakdown */}
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {data.breakdown.map((item) => (
              <div
                key={item.type}
                className="flex items-center gap-3 p-3 rounded-lg border bg-card hover:shadow-md transition-shadow"
              >
                <div
                  className="p-2 rounded-lg"
                  style={{ backgroundColor: `${getColor(item.type)}20` }}
                >
                  <div style={{ color: getColor(item.type) }}>
                    {getIcon(item.type)}
                  </div>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-muted-foreground truncate">
                    {item.type.charAt(0).toUpperCase() + item.type.slice(1).replace('_', ' ')}
                  </p>
                  <div className="flex items-baseline gap-2">
                    <span className="text-lg font-bold">{item.count}</span>
                    <span className="text-xs text-muted-foreground">
                      ({item.percentage.toFixed(1)}%)
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

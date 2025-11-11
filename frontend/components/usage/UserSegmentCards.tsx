"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { useFilters } from '@/lib/filter-context';
import apiClient from '@/lib/api-client';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { Users, TrendingUp, UserPlus, UserX, Zap } from 'lucide-react';

interface UserSegment {
  segment: 'power_user' | 'regular' | 'new' | 'dormant';
  count: number;
  percentage: number;
  avg_requests_per_user: number;
  trend_percentage: number;
}

interface UserSegmentResponse {
  data: UserSegment[];
  meta: {
    total_users: number;
    range: string;
  };
}

/**
 * UserSegmentCards - User segmentation analytics
 *
 * Displays 4 cards showing user distribution across segments:
 * - Power Users (top 10% by activity)
 * - Regular Users (moderate activity)
 * - New Users (joined in last 30 days)
 * - Dormant Users (no activity in 30+ days)
 *
 * Based on PRD Tab 2 requirement for user segmentation analysis
 */
export function UserSegmentCards() {
  const { user, loading: authLoading } = useAuth();
  const { filters } = useFilters();

  const { data, isLoading } = useQuery<UserSegmentResponse>({
    queryKey: ['user-segments', filters.range],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/usage/user-segments?range=${filters.range}`,
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  const getSegmentConfig = (segment: string) => {
    switch (segment) {
      case 'power_user':
        return {
          icon: Zap,
          label: 'Power Users',
          color: 'text-purple-600',
          bgColor: 'bg-purple-50',
          description: 'Top 10% by activity',
        };
      case 'regular':
        return {
          icon: Users,
          label: 'Regular Users',
          color: 'text-blue-600',
          bgColor: 'bg-blue-50',
          description: 'Moderate activity',
        };
      case 'new':
        return {
          icon: UserPlus,
          label: 'New Users',
          color: 'text-green-600',
          bgColor: 'bg-green-50',
          description: 'Joined last 30 days',
        };
      case 'dormant':
        return {
          icon: UserX,
          label: 'Dormant Users',
          color: 'text-gray-600',
          bgColor: 'bg-gray-50',
          description: 'No activity 30+ days',
        };
      default:
        return {
          icon: Users,
          label: segment,
          color: 'text-gray-600',
          bgColor: 'bg-gray-50',
          description: '',
        };
    }
  };

  if (isLoading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {[1, 2, 3, 4].map((i) => (
          <Card key={i}>
            <CardHeader className="pb-2">
              <Skeleton className="h-5 w-24" />
            </CardHeader>
            <CardContent>
              <Skeleton className="h-10 w-16 mb-2" />
              <Skeleton className="h-4 w-32" />
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  if (!data || data.data.length === 0) {
    return (
      <Card>
        <CardContent className="py-8 text-center text-muted-foreground">
          <Users className="h-12 w-12 mx-auto mb-2 opacity-50" />
          <p>No user segmentation data available</p>
        </CardContent>
      </Card>
    );
  }

  // Sort segments in desired order
  const orderedSegments = ['power_user', 'regular', 'new', 'dormant'];
  const sortedData = [...data.data].sort(
    (a, b) => orderedSegments.indexOf(a.segment) - orderedSegments.indexOf(b.segment)
  );

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      {sortedData.map((segment) => {
        const config = getSegmentConfig(segment.segment);
        const Icon = config.icon;
        const isPositiveTrend = segment.trend_percentage >= 0;

        return (
          <Card key={segment.segment} className="hover:shadow-lg transition-shadow">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {config.label}
              </CardTitle>
              <div className={`p-2 rounded-lg ${config.bgColor}`}>
                <Icon className={`h-4 w-4 ${config.color}`} />
              </div>
            </CardHeader>
            <CardContent>
              <div className="flex items-baseline gap-2 mb-1">
                <div className="text-3xl font-bold">{segment.count.toLocaleString()}</div>
                <Badge variant={isPositiveTrend ? 'default' : 'secondary'} className="text-xs">
                  {isPositiveTrend ? '+' : ''}
                  {segment.trend_percentage.toFixed(1)}%
                </Badge>
              </div>
              <p className="text-xs text-muted-foreground mb-2">{config.description}</p>
              <div className="flex items-center justify-between text-xs">
                <span className="text-muted-foreground">
                  {segment.percentage.toFixed(1)}% of total
                </span>
                <span className="font-medium">
                  {segment.avg_requests_per_user.toFixed(1)} req/user
                </span>
              </div>
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
}

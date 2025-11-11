"use client";

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import {
  RadarChart,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  Radar,
  ResponsiveContainer
} from 'recharts';

interface CriteriaBreakdown {
  accuracy: number;
  relevance: number;
  helpfulness: number;
  coherence: number;
}

interface AgentCriteriaBreakdownProps {
  criteria: CriteriaBreakdown;
  loading?: boolean;
}

/**
 * AgentCriteriaBreakdown - Radar chart showing rubric criteria scores for an agent
 *
 * Features:
 * - Radar chart visualization
 * - 4 evaluation criteria
 * - Color coding by score level
 */
export function AgentCriteriaBreakdown({ criteria, loading = false }: AgentCriteriaBreakdownProps) {
  // Ensure values are numbers with null safety
  const safeData = {
    accuracy: criteria?.accuracy || 0,
    relevance: criteria?.relevance || 0,
    helpfulness: criteria?.helpfulness || 0,
    coherence: criteria?.coherence || 0
  };

  const chartData = [
    { criterion: 'Accuracy', score: safeData.accuracy },
    { criterion: 'Relevance', score: safeData.relevance },
    { criterion: 'Helpfulness', score: safeData.helpfulness },
    { criterion: 'Coherence', score: safeData.coherence }
  ];

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Criteria Breakdown</CardTitle>
          <CardDescription>Loading criteria scores...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[350px] w-full" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Criteria Breakdown</CardTitle>
        <CardDescription>
          Performance across evaluation criteria
        </CardDescription>
      </CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={350}>
          <RadarChart data={chartData}>
            <PolarGrid stroke="#e0e0e0" />
            <PolarAngleAxis
              dataKey="criterion"
              style={{ fontSize: '12px' }}
            />
            <PolarRadiusAxis
              angle={90}
              domain={[0, 10]}
              style={{ fontSize: '10px' }}
            />
            <Radar
              name="Score"
              dataKey="score"
              stroke="#3b82f6"
              fill="#3b82f6"
              fillOpacity={0.3}
              strokeWidth={2}
            />
          </RadarChart>
        </ResponsiveContainer>

        {/* Score Summary */}
        <div className="mt-6 grid grid-cols-2 gap-4">
          {chartData.map((item) => (
            <div key={item.criterion} className="text-center p-3 bg-gray-50 rounded-lg">
              <p className="text-xs text-muted-foreground mb-1">{item.criterion}</p>
              <p className="text-xl font-bold">
                {item.score.toFixed(1)}
              </p>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}

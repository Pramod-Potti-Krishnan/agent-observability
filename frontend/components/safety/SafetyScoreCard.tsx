"use client";

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Shield, TrendingUp, TrendingDown } from 'lucide-react';

interface SafetyScoreCardProps {
  score: number; // 0-100
  trend: number; // percentage change
  loading?: boolean;
}

/**
 * SafetyScoreCard - Overall safety score (0-100) based on violation rate
 *
 * Score calculation:
 * - 100 = No violations
 * - 90-99 = Low violation rate (< 1%)
 * - 70-89 = Medium violation rate (1-5%)
 * - 50-69 = High violation rate (5-10%)
 * - < 50 = Critical violation rate (> 10%)
 */
export function SafetyScoreCard({ score, trend, loading }: SafetyScoreCardProps) {
  // Determine color based on score
  const getScoreColor = (score: number): string => {
    if (score >= 90) return 'text-green-600';
    if (score >= 70) return 'text-yellow-600';
    if (score >= 50) return 'text-orange-600';
    return 'text-red-600';
  };

  // Determine status label
  const getStatusLabel = (score: number): string => {
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'At Risk';
  };

  const scoreColor = getScoreColor(score);
  const statusLabel = getStatusLabel(score);

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          Safety Score
        </CardTitle>
        <Shield className={`h-5 w-5 ${scoreColor}`} />
      </CardHeader>
      <CardContent>
        {loading ? (
          <>
            <Skeleton className="h-12 w-24 mb-2" />
            <Skeleton className="h-4 w-32" />
          </>
        ) : (
          <>
            <div className={`text-4xl font-bold ${scoreColor}`}>
              {score.toFixed(0)}
              <span className="text-xl text-muted-foreground">/100</span>
            </div>
            <div className="flex items-center gap-2 mt-2">
              <span className={`text-sm font-medium ${scoreColor}`}>
                {statusLabel}
              </span>
              {trend !== 0 && (
                <div className={`flex items-center text-xs ${trend > 0 ? 'text-green-600' : 'text-red-600'}`}>
                  {trend > 0 ? (
                    <TrendingUp className="h-3 w-3 mr-1" />
                  ) : (
                    <TrendingDown className="h-3 w-3 mr-1" />
                  )}
                  <span>{Math.abs(trend).toFixed(1)}%</span>
                </div>
              )}
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              {score >= 90 && 'Low violation rate'}
              {score >= 70 && score < 90 && 'Moderate violation rate'}
              {score >= 50 && score < 70 && 'Elevated violation rate'}
              {score < 50 && 'High violation rate'}
            </p>
          </>
        )}
      </CardContent>
    </Card>
  );
}

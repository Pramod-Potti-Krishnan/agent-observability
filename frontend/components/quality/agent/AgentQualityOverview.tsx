"use client";

import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { TrendingUp, TrendingDown, Minus, AlertTriangle, Target, CheckCircle, Sparkles } from 'lucide-react';
import { CreateEvaluationDialog } from './CreateEvaluationDialog';

interface AgentQualityOverviewProps {
  agentId: string;
  avgScore: number;
  totalEvaluations: number;
  failingRate: number;
  recentTrend: 'improving' | 'stable' | 'degrading';
  driftIndicator: number;
  loading?: boolean;
  onRefresh?: () => void;
}

/**
 * AgentQualityOverview - 4 KPI cards showing agent-specific quality metrics
 *
 * Features:
 * - Average Quality Score with color coding
 * - Total Evaluations count
 * - Failing Rate percentage
 * - Recent Trend with icon indicator
 * - Create Evaluation action button
 */
export function AgentQualityOverview({
  agentId,
  avgScore,
  totalEvaluations,
  failingRate,
  recentTrend,
  driftIndicator,
  loading = false,
  onRefresh
}: AgentQualityOverviewProps) {
  const [dialogOpen, setDialogOpen] = useState(false);
  // Ensure values are numbers with null safety
  const safeScore = avgScore || 0;
  const safeTotal = totalEvaluations || 0;
  const safeFailingRate = failingRate || 0;
  const safeDrift = driftIndicator || 0;

  // Get score color
  const getScoreColor = (score: number): string => {
    if (score >= 9.0) return 'text-green-600';
    if (score >= 7.0) return 'text-blue-600';
    if (score >= 5.0) return 'text-amber-600';
    if (score >= 3.0) return 'text-orange-600';
    return 'text-red-600';
  };

  const getScoreBgColor = (score: number): string => {
    if (score >= 9.0) return 'bg-green-50 border-green-200';
    if (score >= 7.0) return 'bg-blue-50 border-blue-200';
    if (score >= 5.0) return 'bg-amber-50 border-amber-200';
    if (score >= 3.0) return 'bg-orange-50 border-orange-200';
    return 'bg-red-50 border-red-200';
  };

  // Get trend display
  const getTrendDisplay = () => {
    if (recentTrend === 'improving') {
      return {
        icon: <TrendingUp className="h-5 w-5" />,
        color: 'text-green-600',
        bg: 'bg-green-100',
        label: 'Improving'
      };
    } else if (recentTrend === 'degrading') {
      return {
        icon: <TrendingDown className="h-5 w-5" />,
        color: 'text-red-600',
        bg: 'bg-red-100',
        label: 'Degrading'
      };
    } else {
      return {
        icon: <Minus className="h-5 w-5" />,
        color: 'text-gray-600',
        bg: 'bg-gray-100',
        label: 'Stable'
      };
    }
  };

  const trend = getTrendDisplay();

  const handleEvaluationSuccess = () => {
    setDialogOpen(false);
    if (onRefresh) {
      onRefresh();
    }
  };

  return (
    <div className="space-y-4">
      {/* Header with Create Evaluation Button */}
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-lg font-semibold">Quality Overview</h3>
          <p className="text-sm text-muted-foreground">
            LLM-as-Judge evaluation metrics for this agent
          </p>
        </div>
        <Button
          onClick={() => setDialogOpen(true)}
          className="gap-2"
          disabled={loading}
        >
          <Sparkles className="h-4 w-4" />
          Create Evaluation
        </Button>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      {/* Average Quality Score */}
      <Card className={`hover:shadow-lg transition-shadow border-2 ${getScoreBgColor(safeScore)}`}>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">
            Average Quality Score
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <Skeleton className="h-12 w-24" />
          ) : (
            <>
              <div className={`text-5xl font-bold ${getScoreColor(safeScore)}`}>
                {safeScore.toFixed(1)}
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                out of 10.0
              </p>
              <div className="mt-2">
                <Badge variant={safeDrift > 0 ? "default" : safeDrift < 0 ? "destructive" : "secondary"} className="text-xs">
                  {safeDrift > 0 ? '+' : ''}{safeDrift.toFixed(1)}% drift
                </Badge>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* Total Evaluations */}
      <Card className="hover:shadow-lg transition-shadow">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">
            Total Evaluations
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <Skeleton className="h-12 w-24" />
          ) : (
            <>
              <div className="text-3xl font-bold">{safeTotal.toLocaleString()}</div>
              <p className="text-xs text-muted-foreground mt-1">
                quality assessments
              </p>
            </>
          )}
        </CardContent>
      </Card>

      {/* Failing Rate */}
      <Card className="hover:shadow-lg transition-shadow">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">
            Failing Rate
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <Skeleton className="h-12 w-24" />
          ) : (
            <>
              <div className="flex items-center gap-2">
                <div className={`text-3xl font-bold ${safeFailingRate > 0 ? 'text-red-600' : 'text-green-600'}`}>
                  {safeFailingRate.toFixed(1)}%
                </div>
                {safeFailingRate > 0 ? (
                  <AlertTriangle className="h-5 w-5 text-red-600" />
                ) : (
                  <CheckCircle className="h-5 w-5 text-green-600" />
                )}
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                {safeFailingRate > 0 ? 'below quality threshold (< 5.0)' : 'all passing quality threshold'}
              </p>
            </>
          )}
        </CardContent>
      </Card>

      {/* Recent Trend */}
      <Card className="hover:shadow-lg transition-shadow">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">
            Recent Trend
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <Skeleton className="h-12 w-24" />
          ) : (
            <>
              <div className={`flex items-center gap-2 ${trend.color}`}>
                {trend.icon}
                <Badge className={`${trend.bg} ${trend.color}`}>{trend.label}</Badge>
              </div>
              <p className="text-xs text-muted-foreground mt-1">
                Quality trend direction
              </p>
            </>
          )}
        </CardContent>
      </Card>
      </div>

      {/* Create Evaluation Dialog */}
      <CreateEvaluationDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        agentId={agentId}
        onSuccess={handleEvaluationSuccess}
      />
    </div>
  );
}

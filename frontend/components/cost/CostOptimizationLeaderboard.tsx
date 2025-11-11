"use client";

import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import apiClient from '@/lib/api-client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  TrendingDown,
  Sparkles,
  Clock,
  Shield,
  Target,
  ChevronRight,
  Zap,
  X,
  CheckCircle2
} from 'lucide-react';

interface OptimizationOpportunity {
  opportunity_id: string;
  optimization_type: string;
  affected_agents: string[];
  current_cost_monthly_usd: number;
  optimized_cost_monthly_usd: number;
  savings_potential_monthly_usd: number;
  savings_potential_annual_usd: number;
  implementation_effort: 'low' | 'medium' | 'high';
  technical_risk: 'low' | 'medium' | 'high';
  quality_impact: 'none' | 'minimal' | 'moderate' | 'significant';
  recommendation_details: {
    current_config?: Record<string, any>;
    recommended_config?: Record<string, any>;
    implementation_steps?: string[];
    rollback_plan?: string;
    testing_checklist?: string[];
  };
  status: string;
  priority_score: number;
  identified_by: string;
  created_at: string;
}

interface OptimizationResponse {
  data: OptimizationOpportunity[];
  meta: {
    total_opportunities: number;
    total_savings_potential_monthly: number;
    total_savings_potential_annual: number;
    opportunities_by_type: Record<string, number>;
  };
}

// Type labels and icons
const typeConfig: Record<string, { label: string; icon: any; color: string }> = {
  model_downgrade: { label: 'Model Downgrade', icon: TrendingDown, color: 'text-blue-600' },
  caching: { label: 'Caching', icon: Zap, color: 'text-purple-600' },
  prompt_optimization: { label: 'Prompt Optimization', icon: Sparkles, color: 'text-pink-600' },
  provider_switch: { label: 'Provider Switch', icon: Target, color: 'text-green-600' },
  batching: { label: 'Request Batching', icon: Clock, color: 'text-orange-600' },
  token_reduction: { label: 'Token Reduction', icon: TrendingDown, color: 'text-red-600' },
  agent_deprecation: { label: 'Agent Deprecation', icon: Shield, color: 'text-gray-600' },
};

/**
 * CostOptimizationLeaderboard - Prioritized list of cost optimization opportunities
 *
 * Features:
 * - Ranked by savings potential
 * - Implementation effort and risk indicators
 * - Quick action buttons for each opportunity
 * - Annual savings projections
 */
export function CostOptimizationLeaderboard() {
  const { user, loading: authLoading } = useAuth();
  const [selectedOpportunity, setSelectedOpportunity] = useState<OptimizationOpportunity | null>(null);

  const { data, isLoading } = useQuery<OptimizationResponse>({
    queryKey: ['optimization-opportunities'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/cost/optimization-opportunities?sort_by=savings&limit=10');
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Get effort badge variant
  const getEffortBadge = (effort: string): { variant: 'default' | 'secondary' | 'destructive', label: string } => {
    if (effort === 'low') return { variant: 'secondary', label: 'Low Effort' };
    if (effort === 'high') return { variant: 'destructive', label: 'High Effort' };
    return { variant: 'default', label: 'Medium Effort' };
  };

  // Get risk badge
  const getRiskBadge = (risk: string): { variant: 'default' | 'secondary' | 'destructive', label: string } => {
    if (risk === 'low') return { variant: 'secondary', label: 'Low Risk' };
    if (risk === 'high') return { variant: 'destructive', label: 'High Risk' };
    return { variant: 'default', label: 'Medium Risk' };
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Cost Optimization Opportunities</CardTitle>
          <CardDescription>Loading opportunities...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[400px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Cost Optimization Opportunities</CardTitle>
          <CardDescription>No optimization opportunities found</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <Sparkles className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">All Optimized!</p>
            <p className="text-xs text-muted-foreground mt-1">
              No cost optimization opportunities detected
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>Cost Optimization Leaderboard</CardTitle>
            <CardDescription>
              {data?.meta?.total_opportunities ?? 0} opportunities •
              ${data?.meta?.total_savings_potential_monthly?.toFixed(2) ?? '0.00'}/month potential •
              ${data?.meta?.total_savings_potential_annual?.toFixed(2) ?? '0.00'}/year
            </CardDescription>
          </div>
          <Badge variant="secondary" className="text-green-700 bg-green-100">
            <TrendingDown className="h-3 w-3 mr-1" />
            Top 10 Ranked
          </Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {data.data.map((opp, index) => {
            const typeInfo = typeConfig[opp.optimization_type] || typeConfig.model_downgrade;
            const TypeIcon = typeInfo.icon;
            const effortBadge = getEffortBadge(opp.implementation_effort);
            const riskBadge = getRiskBadge(opp.technical_risk);
            const savingsPercent = ((opp.savings_potential_monthly_usd / opp.current_cost_monthly_usd) * 100).toFixed(0);

            return (
              <div
                key={opp.opportunity_id}
                className="flex items-center gap-4 p-4 rounded-lg border hover:border-primary hover:shadow-sm transition-all cursor-pointer group"
                onClick={() => setSelectedOpportunity(opp)}
              >
                {/* Rank */}
                <div className="flex-shrink-0 w-8 h-8 rounded-full bg-gradient-to-br from-yellow-400 to-orange-500 flex items-center justify-center text-white font-bold text-sm">
                  #{index + 1}
                </div>

                {/* Type Icon */}
                <div className={`flex-shrink-0 p-2 rounded-lg bg-gray-100 ${typeInfo.color}`}>
                  <TypeIcon className="h-5 w-5" />
                </div>

                {/* Details */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <h4 className="font-semibold text-sm truncate">{typeInfo.label}</h4>
                    <Badge variant="outline" className="text-xs">
                      {opp.affected_agents.length} agent{opp.affected_agents.length > 1 ? 's' : ''}
                    </Badge>
                  </div>
                  <p className="text-xs text-muted-foreground line-clamp-1">
                    {opp.recommendation_details.implementation_steps?.[0] || 'Optimization opportunity identified'}
                  </p>
                  <div className="flex items-center gap-2 mt-2">
                    <Badge variant={effortBadge.variant} className="text-xs">
                      {effortBadge.label}
                    </Badge>
                    <Badge variant={riskBadge.variant} className="text-xs">
                      {riskBadge.label}
                    </Badge>
                    {opp.quality_impact !== 'none' && (
                      <Badge variant="outline" className="text-xs">
                        {opp.quality_impact} quality impact
                      </Badge>
                    )}
                  </div>
                </div>

                {/* Savings */}
                <div className="flex-shrink-0 text-right">
                  <div className="flex items-center gap-1 justify-end mb-1">
                    <TrendingDown className="h-4 w-4 text-green-600" />
                    <span className="text-lg font-bold text-green-600">
                      ${opp.savings_potential_monthly_usd.toFixed(0)}/mo
                    </span>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    ${opp.savings_potential_annual_usd.toFixed(0)}/year
                  </p>
                  <Badge variant="secondary" className="text-xs mt-1 bg-green-50 text-green-700">
                    -{savingsPercent}%
                  </Badge>
                </div>

                {/* Priority Score */}
                <div className="flex-shrink-0 text-center">
                  <div className="text-xs text-muted-foreground mb-1">Priority</div>
                  <div className={`text-xl font-bold ${
                    opp.priority_score >= 80 ? 'text-red-600' :
                    opp.priority_score >= 60 ? 'text-orange-600' :
                    'text-gray-600'
                  }`}>
                    {opp.priority_score}
                  </div>
                </div>

                {/* Action Button */}
                <Button
                  variant="ghost"
                  size="sm"
                  className="flex-shrink-0 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  View Details
                  <ChevronRight className="h-4 w-4 ml-1" />
                </Button>
              </div>
            );
          })}
        </div>

        {/* Summary Footer */}
        <div className="mt-6 pt-4 border-t">
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <p className="text-xs text-muted-foreground mb-1">Total Monthly Savings</p>
              <p className="text-2xl font-bold text-green-600">
                ${data?.meta?.total_savings_potential_monthly?.toFixed(0) ?? '0'}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">Annual Impact</p>
              <p className="text-2xl font-bold text-green-600">
                ${data?.meta?.total_savings_potential_annual?.toFixed(0) ?? '0'}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">Opportunities</p>
              <p className="text-2xl font-bold">
                {data?.meta?.total_opportunities ?? 0}
              </p>
            </div>
          </div>
        </div>
      </CardContent>

      {/* Details Modal */}
      <Dialog open={!!selectedOpportunity} onOpenChange={(open) => !open && setSelectedOpportunity(null)}>
        <DialogContent className="max-w-3xl max-h-[80vh] overflow-y-auto">
          {selectedOpportunity && (
            <>
              <DialogHeader>
                <DialogTitle className="flex items-center gap-2">
                  {(() => {
                    const typeInfo = typeConfig[selectedOpportunity.optimization_type] || typeConfig.model_downgrade;
                    const TypeIcon = typeInfo.icon;
                    return (
                      <>
                        <div className={`p-2 rounded-lg bg-gray-100 ${typeInfo.color}`}>
                          <TypeIcon className="h-5 w-5" />
                        </div>
                        {typeInfo.label}
                      </>
                    );
                  })()}
                </DialogTitle>
                <DialogDescription>
                  Optimization opportunity for {selectedOpportunity.affected_agents.length} agent(s)
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-6">
                {/* Savings Overview */}
                <div className="grid grid-cols-2 gap-4 p-4 rounded-lg bg-green-50 border border-green-200">
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">Monthly Savings</p>
                    <p className="text-2xl font-bold text-green-600">
                      ${selectedOpportunity.savings_potential_monthly_usd.toFixed(2)}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">Annual Savings</p>
                    <p className="text-2xl font-bold text-green-600">
                      ${selectedOpportunity.savings_potential_annual_usd.toFixed(2)}
                    </p>
                  </div>
                </div>

                {/* Cost Comparison */}
                <div>
                  <h4 className="font-semibold mb-2">Cost Analysis</h4>
                  <div className="space-y-2">
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-muted-foreground">Current Monthly Cost:</span>
                      <span className="font-medium">${selectedOpportunity.current_cost_monthly_usd.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-muted-foreground">Optimized Monthly Cost:</span>
                      <span className="font-medium text-green-600">${selectedOpportunity.optimized_cost_monthly_usd.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between items-center pt-2 border-t">
                      <span className="text-sm font-semibold">Savings:</span>
                      <span className="font-bold text-green-600">
                        ${selectedOpportunity.savings_potential_monthly_usd.toFixed(2)}
                        ({((selectedOpportunity.savings_potential_monthly_usd / selectedOpportunity.current_cost_monthly_usd) * 100).toFixed(0)}%)
                      </span>
                    </div>
                  </div>
                </div>

                {/* Risk & Effort Assessment */}
                <div>
                  <h4 className="font-semibold mb-2">Implementation Assessment</h4>
                  <div className="flex gap-4">
                    <Badge variant={getEffortBadge(selectedOpportunity.implementation_effort).variant}>
                      {getEffortBadge(selectedOpportunity.implementation_effort).label}
                    </Badge>
                    <Badge variant={getRiskBadge(selectedOpportunity.technical_risk).variant}>
                      {getRiskBadge(selectedOpportunity.technical_risk).label}
                    </Badge>
                    {selectedOpportunity.quality_impact !== 'none' && (
                      <Badge variant="outline">
                        {selectedOpportunity.quality_impact} quality impact
                      </Badge>
                    )}
                    <Badge variant="secondary">
                      Priority: {selectedOpportunity.priority_score}
                    </Badge>
                  </div>
                </div>

                {/* Affected Agents */}
                <div>
                  <h4 className="font-semibold mb-2">Affected Agents ({selectedOpportunity.affected_agents.length})</h4>
                  <div className="flex flex-wrap gap-2">
                    {selectedOpportunity.affected_agents.map((agentId) => (
                      <Badge key={agentId} variant="outline" className="font-mono text-xs">
                        {agentId}
                      </Badge>
                    ))}
                  </div>
                </div>

                {/* Implementation Steps */}
                {selectedOpportunity.recommendation_details.implementation_steps &&
                 selectedOpportunity.recommendation_details.implementation_steps.length > 0 && (
                  <div>
                    <h4 className="font-semibold mb-2">Implementation Steps</h4>
                    <ol className="space-y-2">
                      {selectedOpportunity.recommendation_details.implementation_steps.map((step, idx) => (
                        <li key={idx} className="flex gap-2">
                          <span className="flex-shrink-0 flex items-center justify-center w-6 h-6 rounded-full bg-primary text-primary-foreground text-xs font-bold">
                            {idx + 1}
                          </span>
                          <span className="text-sm pt-0.5">{step}</span>
                        </li>
                      ))}
                    </ol>
                  </div>
                )}

                {/* Configuration Changes */}
                {(selectedOpportunity.recommendation_details.current_config ||
                  selectedOpportunity.recommendation_details.recommended_config) && (
                  <div className="grid grid-cols-2 gap-4">
                    {selectedOpportunity.recommendation_details.current_config && (
                      <div>
                        <h4 className="font-semibold mb-2 text-sm">Current Configuration</h4>
                        <pre className="text-xs bg-gray-100 p-3 rounded overflow-x-auto">
                          {JSON.stringify(selectedOpportunity.recommendation_details.current_config, null, 2)}
                        </pre>
                      </div>
                    )}
                    {selectedOpportunity.recommendation_details.recommended_config && (
                      <div>
                        <h4 className="font-semibold mb-2 text-sm">Recommended Configuration</h4>
                        <pre className="text-xs bg-green-50 p-3 rounded overflow-x-auto border border-green-200">
                          {JSON.stringify(selectedOpportunity.recommendation_details.recommended_config, null, 2)}
                        </pre>
                      </div>
                    )}
                  </div>
                )}

                {/* Testing Checklist */}
                {selectedOpportunity.recommendation_details.testing_checklist &&
                 selectedOpportunity.recommendation_details.testing_checklist.length > 0 && (
                  <div>
                    <h4 className="font-semibold mb-2">Testing Checklist</h4>
                    <div className="space-y-2">
                      {selectedOpportunity.recommendation_details.testing_checklist.map((item, idx) => (
                        <div key={idx} className="flex gap-2 items-start">
                          <CheckCircle2 className="h-4 w-4 text-muted-foreground flex-shrink-0 mt-0.5" />
                          <span className="text-sm">{item}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Rollback Plan */}
                {selectedOpportunity.recommendation_details.rollback_plan && (
                  <div className="p-4 rounded-lg bg-yellow-50 border border-yellow-200">
                    <h4 className="font-semibold mb-2 flex items-center gap-2">
                      <Shield className="h-4 w-4 text-yellow-600" />
                      Rollback Plan
                    </h4>
                    <p className="text-sm">{selectedOpportunity.recommendation_details.rollback_plan}</p>
                  </div>
                )}

                {/* Action Buttons */}
                <div className="flex gap-2 pt-4 border-t">
                  <Button className="flex-1" variant="default">
                    Implement Optimization
                  </Button>
                  <Button variant="outline" onClick={() => setSelectedOpportunity(null)}>
                    Close
                  </Button>
                </div>
              </div>
            </>
          )}
        </DialogContent>
      </Dialog>
    </Card>
  );
}

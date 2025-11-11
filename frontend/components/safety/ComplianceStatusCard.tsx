"use client";

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { FileCheck, AlertCircle, CheckCircle } from 'lucide-react';

interface ComplianceStatusCardProps {
  status: 'compliant' | 'partial' | 'non_compliant';
  activeRules: number;
  enabledPolicies: string[];
  lastAudit?: string;
  loading?: boolean;
}

/**
 * ComplianceStatusCard - Overall compliance status for regulatory requirements
 *
 * Status levels:
 * - Compliant: All required policies enabled, no critical violations
 * - Partial: Some policies enabled, minor violations
 * - Non-Compliant: Missing required policies or critical violations
 */
export function ComplianceStatusCard({
  status,
  activeRules,
  enabledPolicies,
  lastAudit,
  loading
}: ComplianceStatusCardProps) {
  // Determine display properties based on status
  const getStatusDisplay = (status: string) => {
    switch (status) {
      case 'compliant':
        return {
          icon: <CheckCircle className="h-5 w-5 text-green-600" />,
          label: 'Compliant',
          variant: 'default' as const,
          color: 'text-green-600',
          bgColor: 'bg-green-50',
          description: 'All compliance requirements met'
        };
      case 'partial':
        return {
          icon: <AlertCircle className="h-5 w-5 text-yellow-600" />,
          label: 'Partial Compliance',
          variant: 'secondary' as const,
          color: 'text-yellow-600',
          bgColor: 'bg-yellow-50',
          description: 'Some requirements need attention'
        };
      case 'non_compliant':
      default:
        return {
          icon: <AlertCircle className="h-5 w-5 text-red-600" />,
          label: 'Non-Compliant',
          variant: 'destructive' as const,
          color: 'text-red-600',
          bgColor: 'bg-red-50',
          description: 'Critical compliance gaps detected'
        };
    }
  };

  const display = getStatusDisplay(status);

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          Compliance Status
        </CardTitle>
        <FileCheck className={`h-5 w-5 ${display.color}`} />
      </CardHeader>
      <CardContent>
        {loading ? (
          <>
            <Skeleton className="h-12 w-32 mb-2" />
            <Skeleton className="h-4 w-40" />
          </>
        ) : (
          <>
            <div className="flex items-center gap-2 mb-3">
              {display.icon}
              <Badge variant={display.variant} className="text-xs">
                {display.label}
              </Badge>
            </div>

            <p className="text-sm text-muted-foreground mb-4">
              {display.description}
            </p>

            {/* Active Rules */}
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">Active Rules</span>
                <span className="font-medium">{activeRules}</span>
              </div>

              {/* Enabled Policies */}
              <div className="flex flex-col gap-1">
                <span className="text-xs text-muted-foreground">Enabled Policies:</span>
                <div className="flex flex-wrap gap-1">
                  {enabledPolicies.length > 0 ? (
                    enabledPolicies.slice(0, 3).map((policy, idx) => (
                      <Badge key={idx} variant="outline" className="text-xs">
                        {policy}
                      </Badge>
                    ))
                  ) : (
                    <span className="text-xs text-muted-foreground">None</span>
                  )}
                  {enabledPolicies.length > 3 && (
                    <Badge variant="outline" className="text-xs">
                      +{enabledPolicies.length - 3} more
                    </Badge>
                  )}
                </div>
              </div>

              {/* Last Audit */}
              {lastAudit && (
                <div className="pt-2 border-t">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-muted-foreground">Last Audit</span>
                    <span className="font-medium">
                      {new Date(lastAudit).toLocaleDateString()}
                    </span>
                  </div>
                </div>
              )}
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}

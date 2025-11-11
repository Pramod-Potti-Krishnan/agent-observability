"use client";

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { Clock, CheckCircle2, XCircle } from 'lucide-react';

interface SLAComplianceCardProps {
  complianceRate: number; // percentage 0-100
  totalIncidents: number;
  withinSLA: number;
  breachedSLA: number;
  loading?: boolean;
}

/**
 * SLAComplianceCard - Tracks SLA compliance for violation response
 *
 * SLA Definition:
 * - Critical violations: Must be addressed within 1 hour
 * - High violations: Must be addressed within 4 hours
 * - Medium violations: Must be addressed within 24 hours
 */
export function SLAComplianceCard({
  complianceRate,
  totalIncidents,
  withinSLA,
  breachedSLA,
  loading
}: SLAComplianceCardProps) {
  // Determine compliance status
  const getComplianceStatus = (rate: number) => {
    if (rate >= 95) return { label: 'Excellent', variant: 'default' as const, color: 'text-green-600' };
    if (rate >= 85) return { label: 'Good', variant: 'secondary' as const, color: 'text-blue-600' };
    if (rate >= 70) return { label: 'Fair', variant: 'secondary' as const, color: 'text-yellow-600' };
    return { label: 'At Risk', variant: 'destructive' as const, color: 'text-red-600' };
  };

  const status = getComplianceStatus(complianceRate);

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          SLA Compliance
        </CardTitle>
        <Clock className={`h-5 w-5 ${status.color}`} />
      </CardHeader>
      <CardContent>
        {loading ? (
          <>
            <Skeleton className="h-12 w-24 mb-2" />
            <Skeleton className="h-4 w-32" />
          </>
        ) : (
          <>
            <div className={`text-4xl font-bold ${status.color}`}>
              {complianceRate.toFixed(1)}%
            </div>
            <div className="flex items-center gap-2 mt-2">
              <Badge variant={status.variant} className="text-xs">
                {status.label}
              </Badge>
            </div>

            {/* Detailed breakdown */}
            <div className="mt-4 space-y-2">
              <div className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-1 text-muted-foreground">
                  <CheckCircle2 className="h-3 w-3 text-green-600" />
                  <span>Within SLA</span>
                </div>
                <span className="font-medium text-green-600">{withinSLA}</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-1 text-muted-foreground">
                  <XCircle className="h-3 w-3 text-red-600" />
                  <span>Breached SLA</span>
                </div>
                <span className="font-medium text-red-600">{breachedSLA}</span>
              </div>
              <div className="pt-2 border-t">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Total Incidents</span>
                  <span className="font-medium">{totalIncidents}</span>
                </div>
              </div>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}

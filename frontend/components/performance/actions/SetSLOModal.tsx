"use client";

import React, { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useToast } from '@/hooks/use-toast';
import { Target } from 'lucide-react';
import apiClient from '@/lib/api-client';

interface SetSLOModalProps {
  isOpen: boolean;
  onClose: () => void;
  agentId: string;
  currentSLO?: {
    p50_ms: number;
    p90_ms: number;
    p95_ms: number;
    p99_ms: number;
    error_rate_pct: number;
  };
}

/**
 * SetSLOModal - Modal for creating/updating SLO configuration
 *
 * P0 Action: Set Latency SLO (A4.1)
 * - Allows setting P50/P90/P95/P99 latency targets
 * - Sets error rate threshold
 * - Validates percentile ordering
 */
export function SetSLOModal({ isOpen, onClose, agentId, currentSLO }: SetSLOModalProps) {
  const { user } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const [formData, setFormData] = useState({
    p50_ms: currentSLO?.p50_ms || 500,
    p90_ms: currentSLO?.p90_ms || 1000,
    p95_ms: currentSLO?.p95_ms || 1500,
    p99_ms: currentSLO?.p99_ms || 2000,
    error_rate_pct: currentSLO?.error_rate_pct || 5.0,
  });

  const createSLOMutation = useMutation({
    mutationFn: async (data: typeof formData) => {
      const response = await apiClient.post(
        '/api/v1/performance/slo',
        {
          agent_id: agentId,
          ...data,
        },
        {
          headers: {
            'X-Workspace-ID': user?.workspace_id || '',
          },
        }
      );
      return response.data;
    },
    onSuccess: () => {
      toast({
        title: 'SLO Configuration Saved',
        description: `SLO targets updated successfully for agent ${agentId.substring(0, 12)}...`,
      });
      queryClient.invalidateQueries({ queryKey: ['slo-compliance'] });
      queryClient.invalidateQueries({ queryKey: ['agent-detail', agentId] });
      onClose();
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to Save SLO',
        description: error.response?.data?.detail || 'An error occurred while saving SLO configuration',
        variant: 'destructive',
      });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Validate percentile ordering
    if (formData.p50_ms >= formData.p90_ms) {
      toast({
        title: 'Invalid SLO Configuration',
        description: 'P50 must be less than P90',
        variant: 'destructive',
      });
      return;
    }
    if (formData.p90_ms >= formData.p95_ms) {
      toast({
        title: 'Invalid SLO Configuration',
        description: 'P90 must be less than P95',
        variant: 'destructive',
      });
      return;
    }
    if (formData.p95_ms >= formData.p99_ms) {
      toast({
        title: 'Invalid SLO Configuration',
        description: 'P95 must be less than P99',
        variant: 'destructive',
      });
      return;
    }
    if (formData.error_rate_pct < 0 || formData.error_rate_pct > 100) {
      toast({
        title: 'Invalid SLO Configuration',
        description: 'Error rate must be between 0 and 100',
        variant: 'destructive',
      });
      return;
    }

    createSLOMutation.mutate(formData);
  };

  const handleChange = (field: keyof typeof formData, value: string) => {
    setFormData((prev) => ({
      ...prev,
      [field]: parseFloat(value) || 0,
    }));
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <Target className="h-5 w-5 text-blue-600" />
            <DialogTitle>Set SLO Configuration</DialogTitle>
          </div>
          <DialogDescription>
            Define latency and error rate targets for agent <span className="font-mono">{agentId.substring(0, 16)}...</span>
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit}>
          <div className="grid gap-4 py-4">
            {/* Latency Targets */}
            <div className="space-y-3">
              <Label className="text-sm font-semibold">Latency Targets (milliseconds)</Label>

              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1">
                  <Label htmlFor="p50_ms" className="text-xs">P50 (Median)</Label>
                  <Input
                    id="p50_ms"
                    type="number"
                    value={formData.p50_ms}
                    onChange={(e) => handleChange('p50_ms', e.target.value)}
                    min="0"
                    step="50"
                    required
                  />
                </div>

                <div className="space-y-1">
                  <Label htmlFor="p90_ms" className="text-xs">P90</Label>
                  <Input
                    id="p90_ms"
                    type="number"
                    value={formData.p90_ms}
                    onChange={(e) => handleChange('p90_ms', e.target.value)}
                    min="0"
                    step="50"
                    required
                  />
                </div>

                <div className="space-y-1">
                  <Label htmlFor="p95_ms" className="text-xs">P95</Label>
                  <Input
                    id="p95_ms"
                    type="number"
                    value={formData.p95_ms}
                    onChange={(e) => handleChange('p95_ms', e.target.value)}
                    min="0"
                    step="50"
                    required
                  />
                </div>

                <div className="space-y-1">
                  <Label htmlFor="p99_ms" className="text-xs">P99</Label>
                  <Input
                    id="p99_ms"
                    type="number"
                    value={formData.p99_ms}
                    onChange={(e) => handleChange('p99_ms', e.target.value)}
                    min="0"
                    step="50"
                    required
                  />
                </div>
              </div>
            </div>

            {/* Error Rate Target */}
            <div className="space-y-2">
              <Label htmlFor="error_rate_pct" className="text-sm font-semibold">
                Error Rate Target (percentage)
              </Label>
              <Input
                id="error_rate_pct"
                type="number"
                value={formData.error_rate_pct}
                onChange={(e) => handleChange('error_rate_pct', e.target.value)}
                min="0"
                max="100"
                step="0.1"
                required
              />
              <p className="text-xs text-muted-foreground">
                Maximum acceptable error rate (0-100%)
              </p>
            </div>

            {/* Validation Hint */}
            <div className="rounded-md bg-blue-50 border border-blue-200 p-3">
              <p className="text-xs text-blue-700">
                <strong>Note:</strong> P50 &lt; P90 &lt; P95 &lt; P99 ordering is required
              </p>
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={createSLOMutation.isPending}>
              Cancel
            </Button>
            <Button type="submit" disabled={createSLOMutation.isPending}>
              {createSLOMutation.isPending ? 'Saving...' : currentSLO ? 'Update SLO' : 'Create SLO'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

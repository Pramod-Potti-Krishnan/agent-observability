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
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';
import { AlertTriangle } from 'lucide-react';
import apiClient from '@/lib/api-client';

interface FlagRegressionModalProps {
  isOpen: boolean;
  onClose: () => void;
  agentId: string;
  version?: string;
}

/**
 * FlagRegressionModal - Modal for flagging performance regressions
 *
 * P0 Action: Flag Performance Regression (A4.4)
 * - Mark specific version as having performance issues
 * - Record impact percentage
 * - Add notes about root cause or symptoms
 */
export function FlagRegressionModal({ isOpen, onClose, agentId, version }: FlagRegressionModalProps) {
  const { user } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const [formData, setFormData] = useState({
    version: version || '',
    impact_pct: 15.0,
    notes: '',
  });

  const regressionMutation = useMutation({
    mutationFn: async (data: typeof formData) => {
      const response = await apiClient.post(
        '/api/v1/performance/regression',
        {
          version: data.version,
          agent_ids: [agentId],
          impact_pct: data.impact_pct,
          notes: data.notes,
        },
        {
          headers: {
            'X-Workspace-ID': user?.workspace_id || '',
          },
        }
      );
      return response.data;
    },
    onSuccess: (data) => {
      toast({
        title: 'Regression Flagged',
        description: `Version ${data.version} flagged as regression (${data.impact_pct}% impact) for ${data.affected_agent_count} agent(s)`,
      });
      queryClient.invalidateQueries({ queryKey: ['agent-detail', agentId] });
      queryClient.invalidateQueries({ queryKey: ['version-performance'] });
      onClose();
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to Flag Regression',
        description: error.response?.data?.detail || 'An error occurred while flagging regression',
        variant: 'destructive',
      });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Validation
    if (!formData.version || formData.version.trim() === '') {
      toast({
        title: 'Invalid Version',
        description: 'Version is required',
        variant: 'destructive',
      });
      return;
    }

    if (formData.impact_pct < 0 || formData.impact_pct > 100) {
      toast({
        title: 'Invalid Impact',
        description: 'Impact percentage must be between 0 and 100',
        variant: 'destructive',
      });
      return;
    }

    regressionMutation.mutate(formData);
  };

  const handleChange = (field: keyof typeof formData, value: string | number) => {
    setFormData((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  const impactLevels = [
    { value: 5, label: 'Minor', color: 'bg-yellow-100 border-yellow-300 text-yellow-800' },
    { value: 15, label: 'Moderate', color: 'bg-orange-100 border-orange-300 text-orange-800' },
    { value: 30, label: 'Significant', color: 'bg-red-100 border-red-300 text-red-800' },
    { value: 50, label: 'Critical', color: 'bg-red-200 border-red-400 text-red-900' },
  ];

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[550px]">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-red-600" />
            <DialogTitle>Flag Performance Regression</DialogTitle>
          </div>
          <DialogDescription>
            Mark a version deployment as having performance issues for agent <span className="font-mono">{agentId.substring(0, 16)}...</span>
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit}>
          <div className="grid gap-4 py-4">
            {/* Version Input */}
            <div className="space-y-2">
              <Label htmlFor="version" className="text-sm font-semibold">
                Version / Deployment ID
              </Label>
              <Input
                id="version"
                type="text"
                value={formData.version}
                onChange={(e) => handleChange('version', e.target.value)}
                placeholder="e.g., v2.3.1 or deploy-20250127-a3f2"
                required
              />
              <p className="text-xs text-muted-foreground">
                Version or deployment identifier that introduced the regression
              </p>
            </div>

            {/* Impact Percentage */}
            <div className="space-y-3">
              <Label className="text-sm font-semibold">
                Performance Impact
              </Label>

              <div className="grid grid-cols-2 gap-2">
                {impactLevels.map((level) => (
                  <button
                    key={level.value}
                    type="button"
                    onClick={() => handleChange('impact_pct', level.value)}
                    className={`p-3 rounded-lg border-2 text-left transition-all ${
                      formData.impact_pct === level.value
                        ? level.color
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="text-sm font-semibold">{level.label}</div>
                    <div className="text-xs mt-0.5">+{level.value}% latency</div>
                  </button>
                ))}
              </div>

              <div className="flex items-center gap-2">
                <Label htmlFor="impact_custom" className="text-xs">Custom:</Label>
                <Input
                  id="impact_custom"
                  type="number"
                  value={formData.impact_pct}
                  onChange={(e) => handleChange('impact_pct', parseFloat(e.target.value) || 0)}
                  min="0"
                  max="100"
                  step="0.1"
                  className="w-24"
                />
                <span className="text-xs text-muted-foreground">%</span>
              </div>
            </div>

            {/* Notes */}
            <div className="space-y-2">
              <Label htmlFor="notes" className="text-sm font-semibold">
                Notes (Optional)
              </Label>
              <Textarea
                id="notes"
                value={formData.notes}
                onChange={(e) => handleChange('notes', e.target.value)}
                placeholder="Describe symptoms, root cause, or affected functionality..."
                rows={4}
                className="resize-none"
              />
              <p className="text-xs text-muted-foreground">
                Document symptoms, suspected root cause, or related incidents
              </p>
            </div>

            {/* Warning */}
            <div className="rounded-md bg-red-50 border border-red-200 p-4">
              <div className="flex items-start gap-3">
                <AlertTriangle className="h-5 w-5 text-red-600 mt-0.5 flex-shrink-0" />
                <div className="space-y-1">
                  <p className="text-sm font-semibold text-red-900">Regression Alert</p>
                  <p className="text-xs text-red-700">
                    This will flag version <strong>{formData.version || '(not set)'}</strong> as having a{' '}
                    <strong>{formData.impact_pct}%</strong> performance regression. Team members will be
                    notified, and this version may be recommended for rollback.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={regressionMutation.isPending}>
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={regressionMutation.isPending}
              variant="destructive"
            >
              {regressionMutation.isPending ? 'Flagging...' : 'Flag Regression'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

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
import { Bell, AlertTriangle } from 'lucide-react';

interface SetQualityAlertModalProps {
  isOpen: boolean;
  onClose: () => void;
  agentId?: string;
}

type QualityMetric =
  | 'overall_score'
  | 'accuracy'
  | 'relevance'
  | 'helpfulness'
  | 'coherence'
  | 'failing_rate';

type ChannelType = 'email' | 'slack';
type TriggerCondition = 'below' | 'above';

/**
 * SetQualityAlertModal - Modal for creating quality threshold alerts
 *
 * Quality Action: Set Quality Alert (A5.2)
 * - Create alerts for quality metrics (overall score, criteria scores, failing rate)
 * - Set threshold values and trigger conditions
 * - Choose notification channel (email/slack)
 * - Alert triggers when metrics cross threshold
 */
export function SetQualityAlertModal({ isOpen, onClose, agentId }: SetQualityAlertModalProps) {
  const { user } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const [metric, setMetric] = useState<QualityMetric>('overall_score');
  const [threshold, setThreshold] = useState<number>(5.0);
  const [condition, setCondition] = useState<TriggerCondition>('below');
  const [channel, setChannel] = useState<ChannelType>('email');

  const alertMutation = useMutation({
    mutationFn: async (data: {
      metric: QualityMetric;
      threshold: number;
      condition: TriggerCondition;
      channel: ChannelType;
    }) => {
      // Simulate API call (in real implementation, POST to backend)
      await new Promise((resolve) => setTimeout(resolve, 800));
      return {
        alert_id: `alert_${Date.now()}`,
        ...data,
      };
    },
    onSuccess: (data) => {
      const metricLabel = getMetricLabel(data.metric);
      const unit = getMetricUnit(data.metric);
      toast({
        title: 'Quality Alert Created',
        description: `Alert will notify via ${data.channel} when ${metricLabel} goes ${data.condition} ${data.threshold}${unit}${agentId ? ` for agent ${agentId.substring(0, 16)}...` : ''}`,
      });
      if (agentId) {
        queryClient.invalidateQueries({ queryKey: ['agent-detail', agentId] });
      }
      queryClient.invalidateQueries({ queryKey: ['quality-overview'] });
      onClose();
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to Create Alert',
        description: error.message || 'An error occurred while creating alert',
        variant: 'destructive',
      });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Validation
    if (metric === 'failing_rate') {
      if (threshold < 0 || threshold > 100) {
        toast({
          title: 'Invalid Threshold',
          description: 'Failing rate threshold must be between 0 and 100',
          variant: 'destructive',
        });
        return;
      }
    } else {
      if (threshold < 0 || threshold > 10) {
        toast({
          title: 'Invalid Threshold',
          description: 'Score threshold must be between 0 and 10',
          variant: 'destructive',
        });
        return;
      }
    }

    alertMutation.mutate({ metric, threshold, condition, channel });
  };

  const getMetricLabel = (metric: QualityMetric): string => {
    const labels: Record<QualityMetric, string> = {
      overall_score: 'Overall Quality Score',
      accuracy: 'Accuracy Score',
      relevance: 'Relevance Score',
      helpfulness: 'Helpfulness Score',
      coherence: 'Coherence Score',
      failing_rate: 'Failing Rate',
    };
    return labels[metric];
  };

  const getMetricUnit = (metric: QualityMetric): string => {
    return metric === 'failing_rate' ? '%' : '';
  };

  const getDefaultThreshold = (metric: QualityMetric): number => {
    return metric === 'failing_rate' ? 20 : 5.0;
  };

  const getDefaultCondition = (metric: QualityMetric): TriggerCondition => {
    return metric === 'failing_rate' ? 'above' : 'below';
  };

  const handleMetricChange = (newMetric: QualityMetric) => {
    setMetric(newMetric);
    setThreshold(getDefaultThreshold(newMetric));
    setCondition(getDefaultCondition(newMetric));
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[550px]">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <Bell className="h-5 w-5 text-orange-600" />
            <DialogTitle>Create Quality Alert</DialogTitle>
          </div>
          <DialogDescription>
            Get notified when quality metrics cross critical thresholds{agentId ? ` for agent ${agentId.substring(0, 16)}...` : ''}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit}>
          <div className="grid gap-4 py-4">
            {/* Metric Selection */}
            <div className="space-y-3">
              <Label className="text-sm font-semibold">Quality Metric</Label>

              <div className="grid grid-cols-2 gap-2">
                {(['overall_score', 'accuracy', 'relevance', 'helpfulness', 'coherence', 'failing_rate'] as QualityMetric[]).map((m) => (
                  <button
                    key={m}
                    type="button"
                    onClick={() => handleMetricChange(m)}
                    className={`p-3 rounded-lg border-2 text-left transition-all ${
                      metric === m
                        ? 'border-orange-600 bg-orange-50'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="text-sm font-medium">{getMetricLabel(m)}</div>
                    <div className="text-xs text-muted-foreground mt-0.5">
                      {m === 'failing_rate' ? 'Percentage below threshold' : '0-10 quality score'}
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Trigger Condition */}
            <div className="space-y-3">
              <Label className="text-sm font-semibold">Alert Condition</Label>

              <div className="grid grid-cols-2 gap-3">
                <button
                  type="button"
                  onClick={() => setCondition('below')}
                  className={`p-3 rounded-lg border-2 text-center transition-all ${
                    condition === 'below'
                      ? 'border-orange-600 bg-orange-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="text-sm font-semibold">⬇️ Below</div>
                  <div className="text-xs text-muted-foreground mt-1">
                    Alert when metric falls below threshold
                  </div>
                </button>

                <button
                  type="button"
                  onClick={() => setCondition('above')}
                  className={`p-3 rounded-lg border-2 text-center transition-all ${
                    condition === 'above'
                      ? 'border-orange-600 bg-orange-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="text-sm font-semibold">⬆️ Above</div>
                  <div className="text-xs text-muted-foreground mt-1">
                    Alert when metric rises above threshold
                  </div>
                </button>
              </div>
            </div>

            {/* Threshold Input */}
            <div className="space-y-2">
              <Label htmlFor="threshold" className="text-sm font-semibold">
                Alert Threshold
              </Label>
              <div className="flex items-center gap-2">
                <Input
                  id="threshold"
                  type="number"
                  value={threshold}
                  onChange={(e) => setThreshold(parseFloat(e.target.value) || 0)}
                  min="0"
                  max={metric === 'failing_rate' ? 100 : 10}
                  step={metric === 'failing_rate' ? 1 : 0.1}
                  required
                  className="flex-1"
                />
                <span className="text-sm text-muted-foreground w-12">
                  {getMetricUnit(metric) || '/10'}
                </span>
              </div>
              <p className="text-xs text-muted-foreground">
                Alert triggers when {getMetricLabel(metric)} goes {condition} this value
              </p>
            </div>

            {/* Notification Channel */}
            <div className="space-y-3">
              <Label className="text-sm font-semibold">Notification Channel</Label>

              <div className="grid grid-cols-2 gap-3">
                <button
                  type="button"
                  onClick={() => setChannel('email')}
                  className={`p-4 rounded-lg border-2 text-center transition-all ${
                    channel === 'email'
                      ? 'border-orange-600 bg-orange-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="text-lg font-semibold">📧 Email</div>
                  <div className="text-xs text-muted-foreground mt-1">
                    Send to {user?.email}
                  </div>
                </button>

                <button
                  type="button"
                  onClick={() => setChannel('slack')}
                  className={`p-4 rounded-lg border-2 text-center transition-all ${
                    channel === 'slack'
                      ? 'border-orange-600 bg-orange-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="text-lg font-semibold">💬 Slack</div>
                  <div className="text-xs text-muted-foreground mt-1">
                    Post to #quality-alerts
                  </div>
                </button>
              </div>
            </div>

            {/* Alert Summary */}
            <div className="rounded-md bg-orange-50 border border-orange-200 p-3">
              <div className="flex items-start gap-2">
                <AlertTriangle className="h-4 w-4 text-orange-600 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="text-xs font-semibold text-orange-900 mb-1">Alert Summary:</p>
                  <p className="text-xs text-orange-700">
                    Notify via {channel} when {getMetricLabel(metric)} goes {condition} {threshold}{getMetricUnit(metric)}{agentId ? ` for agent ${agentId.substring(0, 16)}...` : ''}
                  </p>
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={alertMutation.isPending}>
              Cancel
            </Button>
            <Button type="submit" disabled={alertMutation.isPending}>
              {alertMutation.isPending ? 'Creating...' : 'Create Alert'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

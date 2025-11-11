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
import { Bell } from 'lucide-react';
import apiClient from '@/lib/api-client';

interface CreateAlertModalProps {
  isOpen: boolean;
  onClose: () => void;
  agentId: string;
}

type MetricType = 'p50_latency' | 'p90_latency' | 'p95_latency' | 'p99_latency' | 'error_rate';
type ChannelType = 'email' | 'slack';

/**
 * CreateAlertModal - Modal for creating performance alerts
 *
 * P0 Action: Create Performance Alert (A4.3)
 * - Create alerts for P50/P90/P95/P99 latency or error rate
 * - Set threshold values
 * - Choose notification channel (email/slack)
 */
export function CreateAlertModal({ isOpen, onClose, agentId }: CreateAlertModalProps) {
  const { user } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const [metricType, setMetricType] = useState<MetricType>('p95_latency');
  const [threshold, setThreshold] = useState<number>(2000);
  const [channel, setChannel] = useState<ChannelType>('email');

  const alertMutation = useMutation({
    mutationFn: async (data: { metric_type: MetricType; threshold: number; channel: ChannelType }) => {
      const response = await apiClient.post(
        '/api/v1/performance/alerts',
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
    onSuccess: (data) => {
      const metricLabel = getMetricLabel(data.metric_type);
      toast({
        title: 'Alert Created Successfully',
        description: `Alert ${data.alert_id.substring(0, 8)}... will notify via ${data.channel} when ${metricLabel} exceeds ${data.threshold}${data.metric_type.includes('latency') ? 'ms' : '%'}`,
      });
      queryClient.invalidateQueries({ queryKey: ['agent-detail', agentId] });
      onClose();
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to Create Alert',
        description: error.response?.data?.detail || 'An error occurred while creating alert',
        variant: 'destructive',
      });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Validation
    if (threshold <= 0) {
      toast({
        title: 'Invalid Threshold',
        description: 'Threshold must be greater than 0',
        variant: 'destructive',
      });
      return;
    }

    if (metricType === 'error_rate' && threshold > 100) {
      toast({
        title: 'Invalid Threshold',
        description: 'Error rate threshold must be between 0 and 100',
        variant: 'destructive',
      });
      return;
    }

    alertMutation.mutate({ metric_type: metricType, threshold, channel });
  };

  const getMetricLabel = (metric: MetricType): string => {
    const labels: Record<MetricType, string> = {
      p50_latency: 'P50 Latency',
      p90_latency: 'P90 Latency',
      p95_latency: 'P95 Latency',
      p99_latency: 'P99 Latency',
      error_rate: 'Error Rate',
    };
    return labels[metric];
  };

  const getDefaultThreshold = (metric: MetricType): number => {
    if (metric === 'error_rate') return 5;
    if (metric === 'p50_latency') return 1000;
    if (metric === 'p90_latency') return 1500;
    if (metric === 'p95_latency') return 2000;
    return 3000; // p99
  };

  const handleMetricChange = (newMetric: MetricType) => {
    setMetricType(newMetric);
    setThreshold(getDefaultThreshold(newMetric));
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <Bell className="h-5 w-5 text-purple-600" />
            <DialogTitle>Create Performance Alert</DialogTitle>
          </div>
          <DialogDescription>
            Get notified when performance metrics exceed thresholds for agent <span className="font-mono">{agentId.substring(0, 16)}...</span>
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit}>
          <div className="grid gap-4 py-4">
            {/* Metric Selection */}
            <div className="space-y-3">
              <Label className="text-sm font-semibold">Metric to Monitor</Label>

              <div className="grid grid-cols-2 gap-2">
                {(['p50_latency', 'p90_latency', 'p95_latency', 'p99_latency', 'error_rate'] as MetricType[]).map((metric) => (
                  <button
                    key={metric}
                    type="button"
                    onClick={() => handleMetricChange(metric)}
                    className={`p-3 rounded-lg border-2 text-left transition-all ${
                      metricType === metric
                        ? 'border-purple-600 bg-purple-50'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="text-sm font-medium">{getMetricLabel(metric)}</div>
                    <div className="text-xs text-muted-foreground mt-0.5">
                      {metric.includes('latency') ? 'Response time' : 'Failure rate'}
                    </div>
                  </button>
                ))}
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
                  max={metricType === 'error_rate' ? 100 : undefined}
                  step={metricType === 'error_rate' ? 0.1 : 50}
                  required
                  className="flex-1"
                />
                <span className="text-sm text-muted-foreground w-12">
                  {metricType.includes('latency') ? 'ms' : '%'}
                </span>
              </div>
              <p className="text-xs text-muted-foreground">
                Alert triggers when {getMetricLabel(metricType)} exceeds this value
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
                      ? 'border-purple-600 bg-purple-50'
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
                      ? 'border-purple-600 bg-purple-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="text-lg font-semibold">💬 Slack</div>
                  <div className="text-xs text-muted-foreground mt-1">
                    Post to #alerts
                  </div>
                </button>
              </div>
            </div>

            {/* Alert Summary */}
            <div className="rounded-md bg-blue-50 border border-blue-200 p-3">
              <p className="text-xs text-blue-700">
                <strong>Alert Summary:</strong> Notify via {channel} when {getMetricLabel(metricType)}
                {' '}exceeds {threshold}{metricType.includes('latency') ? 'ms' : '%'}
              </p>
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

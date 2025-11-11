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
import { Label } from '@/components/ui/label';
import { useToast } from '@/hooks/use-toast';
import { Activity, AlertTriangle } from 'lucide-react';
import apiClient from '@/lib/api-client';

interface ProfileAgentModalProps {
  isOpen: boolean;
  onClose: () => void;
  agentId: string;
}

/**
 * ProfileAgentModal - Modal for enabling performance profiling
 *
 * P0 Action: Trigger Performance Profiling (A4.2)
 * - Enables detailed instrumentation for 1/2/4/8 hours
 * - Shows overhead warning (5-10%)
 * - Provides profiling session ID for monitoring
 */
export function ProfileAgentModal({ isOpen, onClose, agentId }: ProfileAgentModalProps) {
  const { user } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const [duration, setDuration] = useState<1 | 2 | 4 | 8>(1);

  const profileMutation = useMutation({
    mutationFn: async (durationHours: number) => {
      const response = await apiClient.post(
        '/api/v1/performance/profile',
        {
          agent_id: agentId,
          duration_hours: durationHours,
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
      const endTime = new Date(data.profiling_end_utc).toLocaleString();
      toast({
        title: 'Performance Profiling Enabled',
        description: `Profiling session ${data.profiling_id.substring(0, 8)}... will run until ${endTime}`,
      });
      queryClient.invalidateQueries({ queryKey: ['agent-detail', agentId] });
      onClose();
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to Enable Profiling',
        description: error.response?.data?.detail || 'An error occurred while enabling profiling',
        variant: 'destructive',
      });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    profileMutation.mutate(duration);
  };

  const getDurationDescription = (hours: number) => {
    const descriptions = {
      1: 'Quick diagnostic session',
      2: 'Standard profiling window',
      4: 'Extended analysis period',
      8: 'Deep performance investigation',
    };
    return descriptions[hours as keyof typeof descriptions];
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <Activity className="h-5 w-5 text-orange-600" />
            <DialogTitle>Enable Performance Profiling</DialogTitle>
          </div>
          <DialogDescription>
            Enable detailed instrumentation for agent <span className="font-mono">{agentId.substring(0, 16)}...</span>
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit}>
          <div className="grid gap-4 py-4">
            {/* Duration Selection */}
            <div className="space-y-3">
              <Label className="text-sm font-semibold">Profiling Duration</Label>

              <div className="grid grid-cols-2 gap-3">
                {[1, 2, 4, 8].map((hours) => (
                  <button
                    key={hours}
                    type="button"
                    onClick={() => setDuration(hours as 1 | 2 | 4 | 8)}
                    className={`p-4 rounded-lg border-2 text-left transition-all ${
                      duration === hours
                        ? 'border-blue-600 bg-blue-50'
                        : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <div className="text-2xl font-bold">{hours}h</div>
                    <div className="text-xs text-muted-foreground mt-1">
                      {getDurationDescription(hours)}
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Performance Impact Warning */}
            <div className="rounded-md bg-yellow-50 border border-yellow-200 p-4">
              <div className="flex items-start gap-3">
                <AlertTriangle className="h-5 w-5 text-yellow-600 mt-0.5 flex-shrink-0" />
                <div className="space-y-2">
                  <p className="text-sm font-semibold text-yellow-900">Performance Impact</p>
                  <p className="text-xs text-yellow-700">
                    Enabling profiling will add <strong>5-10% overhead</strong> to request latency.
                    The agent will collect detailed timing, memory, and execution data during this period.
                  </p>
                </div>
              </div>
            </div>

            {/* What Gets Profiled */}
            <div className="space-y-2">
              <Label className="text-sm font-semibold">Collected Metrics</Label>
              <ul className="text-xs text-muted-foreground space-y-1 list-disc list-inside">
                <li>Request-level timing breakdown (auth, preprocessing, LLM, postprocessing, tools)</li>
                <li>Memory usage and allocation patterns</li>
                <li>External dependency call traces</li>
                <li>CPU utilization per request phase</li>
              </ul>
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={profileMutation.isPending}>
              Cancel
            </Button>
            <Button type="submit" disabled={profileMutation.isPending}>
              {profileMutation.isPending ? 'Enabling...' : `Enable Profiling (${duration}h)`}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

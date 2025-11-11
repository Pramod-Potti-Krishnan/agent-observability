"use client";

import React, { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import apiClient from '@/lib/api-client';
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
import { Input } from '@/components/ui/input';
import { Slider } from '@/components/ui/slider';
import { useToast } from '@/hooks/use-toast';
import { Bell, TrendingUp } from 'lucide-react';

interface SetCapacityAlertModalProps {
  isOpen: boolean;
  onClose: () => void;
  agentId?: string;
}

/**
 * SetCapacityAlertModal - Configure capacity alerts for agents
 *
 * Allows admins to:
 * - Set maximum requests per hour/day threshold
 * - Configure alert percentage (e.g., 80% of capacity)
 * - Set notification channels
 *
 * PRD Tab 2: Usage Actions - Set Capacity Alert (P1)
 */
export function SetCapacityAlertModal({ isOpen, onClose, agentId }: SetCapacityAlertModalProps) {
  const { user } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const [selectedAgentId, setSelectedAgentId] = useState(agentId || '');
  const [maxRequestsPerHour, setMaxRequestsPerHour] = useState(1000);
  const [alertThreshold, setAlertThreshold] = useState(80); // Percentage
  const [notificationEmail, setNotificationEmail] = useState('');

  const setAlertMutation = useMutation({
    mutationFn: async () => {
      const response = await apiClient.post(
        '/api/v1/usage/actions/set-capacity-alert',
        {
          agent_id: selectedAgentId,
          max_requests_per_hour: maxRequestsPerHour,
          alert_threshold_percentage: alertThreshold,
          notification_email: notificationEmail || null,
        },
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['usage-overview'] });
      toast({
        title: 'Capacity Alert Configured',
        description: `Alert set for ${selectedAgentId} at ${alertThreshold}% of ${maxRequestsPerHour} req/hr`,
      });
      handleClose();
    },
    onError: (error: any) => {
      toast({
        title: 'Configuration Failed',
        description: error.response?.data?.detail || 'Failed to set capacity alert',
        variant: 'destructive',
      });
    },
  });

  const handleClose = () => {
    setSelectedAgentId(agentId || '');
    setMaxRequestsPerHour(1000);
    setAlertThreshold(80);
    setNotificationEmail('');
    onClose();
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!selectedAgentId.trim()) {
      toast({
        title: 'Validation Error',
        description: 'Please enter an agent ID',
        variant: 'destructive',
      });
      return;
    }

    if (maxRequestsPerHour < 1) {
      toast({
        title: 'Validation Error',
        description: 'Maximum requests per hour must be at least 1',
        variant: 'destructive',
      });
      return;
    }

    if (notificationEmail && !notificationEmail.includes('@')) {
      toast({
        title: 'Validation Error',
        description: 'Please enter a valid email address',
        variant: 'destructive',
      });
      return;
    }

    setAlertMutation.mutate();
  };

  const triggerThreshold = Math.round((maxRequestsPerHour * alertThreshold) / 100);

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Bell className="h-5 w-5 text-blue-500" />
            Set Capacity Alert
          </DialogTitle>
          <DialogDescription>
            Configure capacity alerts to prevent agent overload and maintain SLAs.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="agent-id">Agent ID *</Label>
            <Input
              id="agent-id"
              placeholder="e.g., data-analysis-agent"
              value={selectedAgentId}
              onChange={(e) => setSelectedAgentId(e.target.value)}
              disabled={!!agentId}
              required
            />
            <p className="text-xs text-muted-foreground">
              The agent to monitor for capacity
            </p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="max-requests">Maximum Requests per Hour *</Label>
            <Input
              id="max-requests"
              type="number"
              min="1"
              step="1"
              placeholder="1000"
              value={maxRequestsPerHour}
              onChange={(e) => setMaxRequestsPerHour(parseInt(e.target.value) || 1000)}
              required
            />
            <p className="text-xs text-muted-foreground">
              Capacity limit for this agent
            </p>
          </div>

          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <Label>Alert Threshold</Label>
              <span className="text-sm font-medium">{alertThreshold}%</span>
            </div>
            <Slider
              value={[alertThreshold]}
              onValueChange={(values) => setAlertThreshold(values[0])}
              min={50}
              max={95}
              step={5}
              className="w-full"
            />
            <p className="text-xs text-muted-foreground">
              Alert will trigger at {triggerThreshold} requests/hr ({alertThreshold}% of capacity)
            </p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="notification-email">Notification Email (Optional)</Label>
            <Input
              id="notification-email"
              type="email"
              placeholder="team@example.com"
              value={notificationEmail}
              onChange={(e) => setNotificationEmail(e.target.value)}
            />
            <p className="text-xs text-muted-foreground">
              Email address to receive capacity alerts
            </p>
          </div>

          <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
            <p className="text-sm text-blue-900 mb-2">
              <TrendingUp className="h-4 w-4 inline mr-1" />
              <strong>Capacity Planning:</strong>
            </p>
            <ul className="text-sm text-blue-800 ml-4 list-disc space-y-1">
              <li>Alerts help prevent agent overload</li>
              <li>Trigger actions: auto-scaling, rate limiting, notifications</li>
              <li>Recommended: Set threshold at 70-85% for headroom</li>
            </ul>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={handleClose}>
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={setAlertMutation.isPending}
            >
              {setAlertMutation.isPending ? 'Configuring...' : 'Set Alert'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

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
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';
import { AlertTriangle, Calendar } from 'lucide-react';

interface DeprecateAgentModalProps {
  isOpen: boolean;
  onClose: () => void;
  agentId?: string;
}

/**
 * DeprecateAgentModal - Mark an agent as deprecated with sunset date
 *
 * Allows admins to:
 * - Mark agent as deprecated
 * - Set sunset date
 * - Provide migration guidance
 * - Optionally suggest replacement agent
 *
 * PRD Tab 2: Usage Actions - Deprecate Agent (P1)
 */
export function DeprecateAgentModal({ isOpen, onClose, agentId }: DeprecateAgentModalProps) {
  const { user } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const [selectedAgentId, setSelectedAgentId] = useState(agentId || '');
  const [sunsetDate, setSunsetDate] = useState('');
  const [replacementAgentId, setReplacementAgentId] = useState('');
  const [migrationMessage, setMigrationMessage] = useState('');

  const deprecateMutation = useMutation({
    mutationFn: async () => {
      const response = await apiClient.post(
        '/api/v1/usage/actions/deprecate-agent',
        {
          agent_id: selectedAgentId,
          sunset_date: sunsetDate,
          replacement_agent_id: replacementAgentId || null,
          migration_message: migrationMessage,
        },
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['agent-distribution'] });
      queryClient.invalidateQueries({ queryKey: ['usage-overview'] });
      toast({
        title: 'Agent Deprecated',
        description: `${selectedAgentId} has been marked as deprecated. Users will be notified.`,
      });
      handleClose();
    },
    onError: (error: any) => {
      toast({
        title: 'Deprecation Failed',
        description: error.response?.data?.detail || 'Failed to deprecate agent',
        variant: 'destructive',
      });
    },
  });

  const handleClose = () => {
    setSelectedAgentId(agentId || '');
    setSunsetDate('');
    setReplacementAgentId('');
    setMigrationMessage('');
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

    if (!sunsetDate) {
      toast({
        title: 'Validation Error',
        description: 'Please set a sunset date',
        variant: 'destructive',
      });
      return;
    }

    const selectedDate = new Date(sunsetDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (selectedDate < today) {
      toast({
        title: 'Validation Error',
        description: 'Sunset date must be in the future',
        variant: 'destructive',
      });
      return;
    }

    deprecateMutation.mutate();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-orange-500" />
            Deprecate Agent
          </DialogTitle>
          <DialogDescription>
            Mark an agent as deprecated and notify users with migration guidance.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="agent-id">Agent ID *</Label>
            <Input
              id="agent-id"
              placeholder="e.g., customer-support-v1"
              value={selectedAgentId}
              onChange={(e) => setSelectedAgentId(e.target.value)}
              disabled={!!agentId}
              required
            />
            <p className="text-xs text-muted-foreground">
              The agent to mark as deprecated
            </p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="sunset-date">Sunset Date *</Label>
            <div className="relative">
              <Calendar className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                id="sunset-date"
                type="date"
                className="pl-10"
                value={sunsetDate}
                onChange={(e) => setSunsetDate(e.target.value)}
                min={new Date().toISOString().split('T')[0]}
                required
              />
            </div>
            <p className="text-xs text-muted-foreground">
              Date when agent will be sunset and removed
            </p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="replacement-agent">Replacement Agent (Optional)</Label>
            <Input
              id="replacement-agent"
              placeholder="e.g., customer-support-v2"
              value={replacementAgentId}
              onChange={(e) => setReplacementAgentId(e.target.value)}
            />
            <p className="text-xs text-muted-foreground">
              Recommended replacement agent for users to migrate to
            </p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="migration-message">Migration Message (Optional)</Label>
            <Textarea
              id="migration-message"
              placeholder="Provide guidance for users on how to migrate..."
              value={migrationMessage}
              onChange={(e) => setMigrationMessage(e.target.value)}
              rows={4}
            />
            <p className="text-xs text-muted-foreground">
              Instructions shown to users about migration
            </p>
          </div>

          <div className="p-3 bg-orange-50 border border-orange-200 rounded-lg">
            <p className="text-sm text-orange-900">
              <strong>Warning:</strong> Deprecating an agent will:
            </p>
            <ul className="text-sm text-orange-800 mt-2 ml-4 list-disc space-y-1">
              <li>Display deprecation notices to all users</li>
              <li>Send migration notifications</li>
              <li>Block new usage after sunset date</li>
            </ul>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={handleClose}>
              Cancel
            </Button>
            <Button
              type="submit"
              variant="destructive"
              disabled={deprecateMutation.isPending}
            >
              {deprecateMutation.isPending ? 'Deprecating...' : 'Deprecate Agent'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

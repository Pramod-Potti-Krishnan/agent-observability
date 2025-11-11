"use client";

import React, { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useAuth } from '@/lib/auth-context';
import apiClient from '@/lib/api-client';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { CheckCircle2, AlertCircle } from 'lucide-react';

interface EnableRuleModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function EnableRuleModal({ open, onOpenChange }: EnableRuleModalProps) {
  const { user } = useAuth();
  const queryClient = useQueryClient();

  const [formData, setFormData] = useState({
    rule_type: 'pii_detection',
    name: '',
    description: '',
    severity: 'warning',
    action: 'log',
    agent_id: '',
  });

  const createRuleMutation = useMutation({
    mutationFn: async (data: typeof formData) => {
      const response = await apiClient.post(
        '/api/v1/guardrails/rules',
        {
          ...data,
          agent_id: data.agent_id || null,
          config: {},
        },
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['violations'] });
      queryClient.invalidateQueries({ queryKey: ['safety-overview'] });
      onOpenChange(false);
      // Reset form
      setFormData({
        rule_type: 'pii_detection',
        name: '',
        description: '',
        severity: 'warning',
        action: 'log',
        agent_id: '',
      });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    createRuleMutation.mutate(formData);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Enable Guardrail Rule</DialogTitle>
          <DialogDescription>
            Create and enable a new guardrail rule to monitor safety violations
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {createRuleMutation.isError && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>
                Failed to create rule. Please try again.
              </AlertDescription>
            </Alert>
          )}

          {createRuleMutation.isSuccess && (
            <Alert>
              <CheckCircle2 className="h-4 w-4" />
              <AlertDescription>
                Rule created successfully!
              </AlertDescription>
            </Alert>
          )}

          <div className="space-y-2">
            <Label htmlFor="rule_type">Rule Type *</Label>
            <Select
              value={formData.rule_type}
              onValueChange={(value) => setFormData({ ...formData, rule_type: value })}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select rule type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="pii_detection">PII Detection</SelectItem>
                <SelectItem value="toxicity">Toxicity Check</SelectItem>
                <SelectItem value="prompt_injection">Prompt Injection</SelectItem>
                <SelectItem value="custom">Custom Rule</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="name">Rule Name *</Label>
            <Input
              id="name"
              placeholder="e.g., Block SSN Detection"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              placeholder="Describe what this rule monitors..."
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              rows={3}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="severity">Severity *</Label>
              <Select
                value={formData.severity}
                onValueChange={(value) => setFormData({ ...formData, severity: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="info">Info</SelectItem>
                  <SelectItem value="warning">Warning</SelectItem>
                  <SelectItem value="error">Error</SelectItem>
                  <SelectItem value="critical">Critical</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="action">Action *</Label>
              <Select
                value={formData.action}
                onValueChange={(value) => setFormData({ ...formData, action: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="log">Log Only</SelectItem>
                  <SelectItem value="block">Block Request</SelectItem>
                  <SelectItem value="redact">Redact Content</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="agent_id">Agent ID (Optional)</Label>
            <Input
              id="agent_id"
              placeholder="Leave empty for all agents"
              value={formData.agent_id}
              onChange={(e) => setFormData({ ...formData, agent_id: e.target.value })}
            />
            <p className="text-xs text-muted-foreground">
              Apply this rule to a specific agent, or leave empty for global rule
            </p>
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={createRuleMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={createRuleMutation.isPending || !formData.name}
            >
              {createRuleMutation.isPending ? 'Creating...' : 'Create Rule'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

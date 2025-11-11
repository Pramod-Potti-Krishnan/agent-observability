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

interface CreateIncidentModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function CreateIncidentModal({ open, onOpenChange }: CreateIncidentModalProps) {
  const { user } = useAuth();
  const queryClient = useQueryClient();

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    severity: 'high',
    incident_type: 'security_breach',
    affected_agent: '',
    trace_id: '',
  });

  const createIncidentMutation = useMutation({
    mutationFn: async (data: typeof formData) => {
      const response = await apiClient.post(
        '/api/v1/alerts/incidents',
        {
          ...data,
          workspace_id: user?.workspace_id,
          status: 'open',
          created_by: user?.email || 'system',
          created_at: new Date().toISOString(),
        },
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['incidents'] });
      queryClient.invalidateQueries({ queryKey: ['safety-overview'] });
      onOpenChange(false);
      // Reset form
      setFormData({
        title: '',
        description: '',
        severity: 'high',
        incident_type: 'security_breach',
        affected_agent: '',
        trace_id: '',
      });
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    createIncidentMutation.mutate(formData);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[550px]">
        <DialogHeader>
          <DialogTitle>Create Safety Incident</DialogTitle>
          <DialogDescription>
            Document a safety incident for tracking and remediation
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {createIncidentMutation.isError && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>
                Failed to create incident. Please try again.
              </AlertDescription>
            </Alert>
          )}

          {createIncidentMutation.isSuccess && (
            <Alert>
              <CheckCircle2 className="h-4 w-4" />
              <AlertDescription>
                Incident created successfully!
              </AlertDescription>
            </Alert>
          )}

          <div className="space-y-2">
            <Label htmlFor="title">Incident Title *</Label>
            <Input
              id="title"
              placeholder="e.g., Critical PII Leak Detected"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">Description *</Label>
            <Textarea
              id="description"
              placeholder="Describe the incident in detail..."
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              rows={4}
              required
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
                  <SelectItem value="low">Low</SelectItem>
                  <SelectItem value="medium">Medium</SelectItem>
                  <SelectItem value="high">High</SelectItem>
                  <SelectItem value="critical">Critical</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="incident_type">Incident Type *</Label>
              <Select
                value={formData.incident_type}
                onValueChange={(value) => setFormData({ ...formData, incident_type: value })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="security_breach">Security Breach</SelectItem>
                  <SelectItem value="data_leak">Data Leak</SelectItem>
                  <SelectItem value="policy_violation">Policy Violation</SelectItem>
                  <SelectItem value="compliance_issue">Compliance Issue</SelectItem>
                  <SelectItem value="other">Other</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="affected_agent">Affected Agent ID</Label>
            <Input
              id="affected_agent"
              placeholder="e.g., agent-claude"
              value={formData.affected_agent}
              onChange={(e) => setFormData({ ...formData, affected_agent: e.target.value })}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="trace_id">Related Trace ID</Label>
            <Input
              id="trace_id"
              placeholder="e.g., trace-123"
              value={formData.trace_id}
              onChange={(e) => setFormData({ ...formData, trace_id: e.target.value })}
            />
            <p className="text-xs text-muted-foreground">
              Link this incident to a specific trace for investigation
            </p>
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={createIncidentMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={createIncidentMutation.isPending || !formData.title || !formData.description}
            >
              {createIncidentMutation.isPending ? 'Creating...' : 'Create Incident'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

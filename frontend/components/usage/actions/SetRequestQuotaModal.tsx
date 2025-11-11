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
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { useToast } from '@/hooks/use-toast';
import { Shield, Clock } from 'lucide-react';

interface SetRequestQuotaModalProps {
  isOpen: boolean;
  onClose: () => void;
  userId?: string;
  departmentId?: string;
}

type QuotaScope = 'user' | 'department';
type QuotaPeriod = 'hourly' | 'daily' | 'monthly';

/**
 * SetRequestQuotaModal - Configure usage quotas for users or departments
 *
 * Allows admins to:
 * - Set request quotas per user or department
 * - Choose quota period (hourly, daily, monthly)
 * - Enforce rate limits to control costs
 *
 * PRD Tab 2: Usage Actions - Set Request Quota (P1)
 */
export function SetRequestQuotaModal({
  isOpen,
  onClose,
  userId,
  departmentId,
}: SetRequestQuotaModalProps) {
  const { user } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const [scope, setScope] = useState<QuotaScope>(userId ? 'user' : 'department');
  const [targetUserId, setTargetUserId] = useState(userId || '');
  const [targetDepartmentId, setTargetDepartmentId] = useState(departmentId || '');
  const [quotaLimit, setQuotaLimit] = useState(10000);
  const [period, setPeriod] = useState<QuotaPeriod>('daily');

  const setQuotaMutation = useMutation({
    mutationFn: async () => {
      const response = await apiClient.post(
        '/api/v1/usage/actions/set-request-quota',
        {
          scope,
          user_id: scope === 'user' ? targetUserId : null,
          department_id: scope === 'department' ? targetDepartmentId : null,
          quota_limit: quotaLimit,
          period,
        },
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['top-users'] });
      queryClient.invalidateQueries({ queryKey: ['usage-overview'] });
      toast({
        title: 'Quota Configured',
        description: `${scope === 'user' ? 'User' : 'Department'} quota set to ${quotaLimit} requests/${period}`,
      });
      handleClose();
    },
    onError: (error: any) => {
      toast({
        title: 'Configuration Failed',
        description: error.response?.data?.detail || 'Failed to set request quota',
        variant: 'destructive',
      });
    },
  });

  const handleClose = () => {
    setScope(userId ? 'user' : 'department');
    setTargetUserId(userId || '');
    setTargetDepartmentId(departmentId || '');
    setQuotaLimit(10000);
    setPeriod('daily');
    onClose();
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (scope === 'user' && !targetUserId.trim()) {
      toast({
        title: 'Validation Error',
        description: 'Please enter a user ID',
        variant: 'destructive',
      });
      return;
    }

    if (scope === 'department' && !targetDepartmentId.trim()) {
      toast({
        title: 'Validation Error',
        description: 'Please enter a department ID',
        variant: 'destructive',
      });
      return;
    }

    if (quotaLimit < 1) {
      toast({
        title: 'Validation Error',
        description: 'Quota limit must be at least 1',
        variant: 'destructive',
      });
      return;
    }

    setQuotaMutation.mutate();
  };

  const getRecommendedQuota = (period: QuotaPeriod): string => {
    const recommendations = {
      hourly: '100-1,000',
      daily: '1,000-10,000',
      monthly: '50,000-500,000',
    };
    return recommendations[period];
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Shield className="h-5 w-5 text-green-500" />
            Set Request Quota
          </DialogTitle>
          <DialogDescription>
            Configure usage quotas to control costs and enforce fair usage policies.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-3">
            <Label>Quota Scope *</Label>
            <RadioGroup
              value={scope}
              onValueChange={(value) => setScope(value as QuotaScope)}
              disabled={!!(userId || departmentId)}
            >
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="user" id="scope-user" />
                <Label htmlFor="scope-user" className="font-normal cursor-pointer">
                  Individual User
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="department" id="scope-department" />
                <Label htmlFor="scope-department" className="font-normal cursor-pointer">
                  Entire Department
                </Label>
              </div>
            </RadioGroup>
          </div>

          {scope === 'user' && (
            <div className="space-y-2">
              <Label htmlFor="user-id">User ID *</Label>
              <Input
                id="user-id"
                placeholder="e.g., user@example.com"
                value={targetUserId}
                onChange={(e) => setTargetUserId(e.target.value)}
                disabled={!!userId}
                required
              />
            </div>
          )}

          {scope === 'department' && (
            <div className="space-y-2">
              <Label htmlFor="department-id">Department ID *</Label>
              <Input
                id="department-id"
                placeholder="e.g., engineering, sales"
                value={targetDepartmentId}
                onChange={(e) => setTargetDepartmentId(e.target.value)}
                disabled={!!departmentId}
                required
              />
            </div>
          )}

          <div className="space-y-3">
            <Label>Quota Period *</Label>
            <RadioGroup
              value={period}
              onValueChange={(value) => setPeriod(value as QuotaPeriod)}
            >
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="hourly" id="period-hourly" />
                <Label htmlFor="period-hourly" className="font-normal cursor-pointer">
                  <Clock className="h-3 w-3 inline mr-1" />
                  Hourly (Recommended: {getRecommendedQuota('hourly')})
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="daily" id="period-daily" />
                <Label htmlFor="period-daily" className="font-normal cursor-pointer">
                  <Clock className="h-3 w-3 inline mr-1" />
                  Daily (Recommended: {getRecommendedQuota('daily')})
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="monthly" id="period-monthly" />
                <Label htmlFor="period-monthly" className="font-normal cursor-pointer">
                  <Clock className="h-3 w-3 inline mr-1" />
                  Monthly (Recommended: {getRecommendedQuota('monthly')})
                </Label>
              </div>
            </RadioGroup>
          </div>

          <div className="space-y-2">
            <Label htmlFor="quota-limit">Quota Limit (Requests) *</Label>
            <Input
              id="quota-limit"
              type="number"
              min="1"
              step="1"
              placeholder="10000"
              value={quotaLimit}
              onChange={(e) => setQuotaLimit(parseInt(e.target.value) || 10000)}
              required
            />
            <p className="text-xs text-muted-foreground">
              Maximum requests allowed per {period} period
            </p>
          </div>

          <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
            <p className="text-sm text-green-900 mb-2">
              <strong>Quota Benefits:</strong>
            </p>
            <ul className="text-sm text-green-800 ml-4 list-disc space-y-1">
              <li>Prevent runaway costs from excessive usage</li>
              <li>Enforce fair usage across teams</li>
              <li>Automatically rate-limit requests beyond quota</li>
            </ul>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={handleClose}>
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={setQuotaMutation.isPending}
            >
              {setQuotaMutation.isPending ? 'Setting Quota...' : 'Set Quota'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

"use client";

import React, { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { useAuth } from '@/lib/auth-context';
import apiClient from '@/lib/api-client';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { CheckCircle2, AlertCircle } from 'lucide-react';
import { Separator } from '@/components/ui/separator';

interface ConfigureRedactionModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function ConfigureRedactionModal({ open, onOpenChange }: ConfigureRedactionModalProps) {
  const { user } = useAuth();
  const queryClient = useQueryClient();

  const [settings, setSettings] = useState({
    enabled: true,
    pii_types: {
      email: true,
      phone: true,
      ssn: true,
      credit_card: true,
      ip_address: false,
      name: false,
    },
    redaction_method: 'mask', // mask, hash, remove
    auto_redact: true,
  });

  const saveSettingsMutation = useMutation({
    mutationFn: async (data: typeof settings) => {
      const response = await apiClient.post(
        '/api/v1/guardrails/redaction-config',
        {
          workspace_id: user?.workspace_id,
          ...data,
        },
        { headers: { 'X-Workspace-ID': user?.workspace_id } }
      );
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['redaction-config'] });
      onOpenChange(false);
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    saveSettingsMutation.mutate(settings);
  };

  const togglePIIType = (type: keyof typeof settings.pii_types) => {
    setSettings({
      ...settings,
      pii_types: {
        ...settings.pii_types,
        [type]: !settings.pii_types[type],
      },
    });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Configure PII Redaction</DialogTitle>
          <DialogDescription>
            Configure automatic PII detection and redaction settings
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-6">
          {saveSettingsMutation.isError && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>
                Failed to save settings. Please try again.
              </AlertDescription>
            </Alert>
          )}

          {saveSettingsMutation.isSuccess && (
            <Alert>
              <CheckCircle2 className="h-4 w-4" />
              <AlertDescription>
                Redaction settings saved successfully!
              </AlertDescription>
            </Alert>
          )}

          {/* Enable/Disable Redaction */}
          <div className="flex items-center space-x-2">
            <Checkbox
              id="enabled"
              checked={settings.enabled}
              onCheckedChange={(checked) => setSettings({ ...settings, enabled: !!checked })}
            />
            <Label htmlFor="enabled" className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
              Enable automatic PII redaction
            </Label>
          </div>

          <Separator />

          {/* PII Types to Redact */}
          <div className="space-y-3">
            <Label className="text-sm font-medium">PII Types to Redact</Label>
            <div className="space-y-2">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="email"
                  checked={settings.pii_types.email}
                  onCheckedChange={() => togglePIIType('email')}
                  disabled={!settings.enabled}
                />
                <Label htmlFor="email" className="text-sm font-normal">
                  Email Addresses
                </Label>
              </div>

              <div className="flex items-center space-x-2">
                <Checkbox
                  id="phone"
                  checked={settings.pii_types.phone}
                  onCheckedChange={() => togglePIIType('phone')}
                  disabled={!settings.enabled}
                />
                <Label htmlFor="phone" className="text-sm font-normal">
                  Phone Numbers
                </Label>
              </div>

              <div className="flex items-center space-x-2">
                <Checkbox
                  id="ssn"
                  checked={settings.pii_types.ssn}
                  onCheckedChange={() => togglePIIType('ssn')}
                  disabled={!settings.enabled}
                />
                <Label htmlFor="ssn" className="text-sm font-normal">
                  Social Security Numbers
                </Label>
              </div>

              <div className="flex items-center space-x-2">
                <Checkbox
                  id="credit_card"
                  checked={settings.pii_types.credit_card}
                  onCheckedChange={() => togglePIIType('credit_card')}
                  disabled={!settings.enabled}
                />
                <Label htmlFor="credit_card" className="text-sm font-normal">
                  Credit Card Numbers
                </Label>
              </div>

              <div className="flex items-center space-x-2">
                <Checkbox
                  id="ip_address"
                  checked={settings.pii_types.ip_address}
                  onCheckedChange={() => togglePIIType('ip_address')}
                  disabled={!settings.enabled}
                />
                <Label htmlFor="ip_address" className="text-sm font-normal">
                  IP Addresses
                </Label>
              </div>

              <div className="flex items-center space-x-2">
                <Checkbox
                  id="name"
                  checked={settings.pii_types.name}
                  onCheckedChange={() => togglePIIType('name')}
                  disabled={!settings.enabled}
                />
                <Label htmlFor="name" className="text-sm font-normal">
                  Personal Names
                </Label>
              </div>
            </div>
          </div>

          <Separator />

          {/* Auto-Redact Option */}
          <div className="flex items-center space-x-2">
            <Checkbox
              id="auto_redact"
              checked={settings.auto_redact}
              onCheckedChange={(checked) => setSettings({ ...settings, auto_redact: !!checked })}
              disabled={!settings.enabled}
            />
            <div className="space-y-1">
              <Label htmlFor="auto_redact" className="text-sm font-normal">
                Automatically redact detected PII in real-time
              </Label>
              <p className="text-xs text-muted-foreground">
                When enabled, PII will be automatically masked in responses
              </p>
            </div>
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={saveSettingsMutation.isPending}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={saveSettingsMutation.isPending}
            >
              {saveSettingsMutation.isPending ? 'Saving...' : 'Save Settings'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

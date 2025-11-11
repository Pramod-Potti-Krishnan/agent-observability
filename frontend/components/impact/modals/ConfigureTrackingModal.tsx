'use client'

import { useState } from 'react'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Switch } from '@/components/ui/switch'
import { Input } from '@/components/ui/input'
import { Settings } from 'lucide-react'

interface ConfigureTrackingModalProps {
  open: boolean
  onClose: () => void
  onSave: (config: TrackingConfig) => void
}

export interface TrackingConfig {
  enableValueTracking: boolean
  enableCustomerMetrics: boolean
  enableCostAttribution: boolean
  enableProductivityTracking: boolean
  updateFrequency: string
  baselineCostPerHour: number
  alertThresholds: {
    goalAtRisk: number
    negativeROI: boolean
    csatDrop: number
  }
}

export function ConfigureTrackingModal({ open, onClose, onSave }: ConfigureTrackingModalProps) {
  const [config, setConfig] = useState<TrackingConfig>({
    enableValueTracking: true,
    enableCustomerMetrics: true,
    enableCostAttribution: true,
    enableProductivityTracking: true,
    updateFrequency: 'hourly',
    baselineCostPerHour: 50,
    alertThresholds: {
      goalAtRisk: 50,
      negativeROI: true,
      csatDrop: 0.5,
    },
  })

  const handleSave = () => {
    onSave(config)
    onClose()
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[550px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            Configure Impact Tracking
          </DialogTitle>
          <DialogDescription>
            Customize how business impact metrics are collected and calculated.
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-6 py-4 max-h-[60vh] overflow-y-auto">
          {/* Tracking Features */}
          <div className="space-y-4">
            <h3 className="font-medium text-sm">Tracking Features</h3>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <Label htmlFor="value-tracking" className="flex flex-col gap-1">
                  <span>Value Attribution Tracking</span>
                  <span className="font-normal text-xs text-muted-foreground">
                    Track cost savings and revenue impact by agent
                  </span>
                </Label>
                <Switch
                  id="value-tracking"
                  checked={config.enableValueTracking}
                  onCheckedChange={(checked) => setConfig({ ...config, enableValueTracking: checked })}
                />
              </div>

              <div className="flex items-center justify-between">
                <Label htmlFor="customer-metrics" className="flex flex-col gap-1">
                  <span>Customer Impact Metrics</span>
                  <span className="font-normal text-xs text-muted-foreground">
                    Track CSAT, NPS, and ticket volume
                  </span>
                </Label>
                <Switch
                  id="customer-metrics"
                  checked={config.enableCustomerMetrics}
                  onCheckedChange={(checked) => setConfig({ ...config, enableCustomerMetrics: checked })}
                />
              </div>

              <div className="flex items-center justify-between">
                <Label htmlFor="cost-attribution" className="flex flex-col gap-1">
                  <span>Cost Attribution</span>
                  <span className="font-normal text-xs text-muted-foreground">
                    Correlate agent usage with infrastructure costs
                  </span>
                </Label>
                <Switch
                  id="cost-attribution"
                  checked={config.enableCostAttribution}
                  onCheckedChange={(checked) => setConfig({ ...config, enableCostAttribution: checked })}
                />
              </div>

              <div className="flex items-center justify-between">
                <Label htmlFor="productivity" className="flex flex-col gap-1">
                  <span>Productivity Tracking</span>
                  <span className="font-normal text-xs text-muted-foreground">
                    Calculate time savings and FTE equivalents
                  </span>
                </Label>
                <Switch
                  id="productivity"
                  checked={config.enableProductivityTracking}
                  onCheckedChange={(checked) => setConfig({ ...config, enableProductivityTracking: checked })}
                />
              </div>
            </div>
          </div>

          {/* Calculation Settings */}
          <div className="space-y-4">
            <h3 className="font-medium text-sm">Calculation Settings</h3>
            <div className="space-y-3">
              <div className="grid gap-2">
                <Label htmlFor="baseline-cost">Baseline Cost per Hour (USD)</Label>
                <Input
                  id="baseline-cost"
                  type="number"
                  value={config.baselineCostPerHour}
                  onChange={(e) => setConfig({ ...config, baselineCostPerHour: parseFloat(e.target.value) })}
                />
                <p className="text-xs text-muted-foreground">
                  Used to calculate productivity value from time savings
                </p>
              </div>
            </div>
          </div>

          {/* Alert Thresholds */}
          <div className="space-y-4">
            <h3 className="font-medium text-sm">Alert Thresholds</h3>
            <div className="space-y-3">
              <div className="grid gap-2">
                <Label htmlFor="goal-risk">Goal At-Risk Threshold (%)</Label>
                <Input
                  id="goal-risk"
                  type="number"
                  value={config.alertThresholds.goalAtRisk}
                  onChange={(e) =>
                    setConfig({
                      ...config,
                      alertThresholds: { ...config.alertThresholds, goalAtRisk: parseFloat(e.target.value) },
                    })
                  }
                />
                <p className="text-xs text-muted-foreground">
                  Alert when goal progress falls below this percentage
                </p>
              </div>

              <div className="flex items-center justify-between">
                <Label htmlFor="negative-roi" className="flex flex-col gap-1">
                  <span>Alert on Negative ROI</span>
                  <span className="font-normal text-xs text-muted-foreground">
                    Notify when ROI becomes negative
                  </span>
                </Label>
                <Switch
                  id="negative-roi"
                  checked={config.alertThresholds.negativeROI}
                  onCheckedChange={(checked) =>
                    setConfig({
                      ...config,
                      alertThresholds: { ...config.alertThresholds, negativeROI: checked },
                    })
                  }
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="csat-drop">CSAT Drop Alert Threshold</Label>
                <Input
                  id="csat-drop"
                  type="number"
                  step="0.1"
                  value={config.alertThresholds.csatDrop}
                  onChange={(e) =>
                    setConfig({
                      ...config,
                      alertThresholds: { ...config.alertThresholds, csatDrop: parseFloat(e.target.value) },
                    })
                  }
                />
                <p className="text-xs text-muted-foreground">
                  Alert when CSAT score drops by this amount
                </p>
              </div>
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleSave}>Save Configuration</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

'use client'

import { useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Slider } from '@/components/ui/slider'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Bell, DollarSign, Percent, AlertTriangle } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { useToast } from '@/hooks/use-toast'

interface SetBudgetAlertModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  currentBudget?: number
  currentThreshold?: number
}

/**
 * SetBudgetAlertModal - Configure budget limits and alert thresholds
 *
 * Features:
 * - Set monthly budget limit
 * - Configure alert threshold percentage
 * - Visual slider for threshold selection
 * - Real-time budget utilization preview
 *
 * PRD Tab 3: Action Modal 1 - Budget Configuration
 */
export function SetBudgetAlertModal({
  open,
  onOpenChange,
  currentBudget = 0,
  currentThreshold = 80
}: SetBudgetAlertModalProps) {
  const { user } = useAuth()
  const { toast } = useToast()
  const queryClient = useQueryClient()

  const [budgetLimit, setBudgetLimit] = useState(currentBudget.toString())
  const [alertThreshold, setAlertThreshold] = useState(currentThreshold)
  const [error, setError] = useState('')

  const updateBudgetMutation = useMutation({
    mutationFn: async (data: { monthly_limit_usd?: number; alert_threshold_percentage?: number }) => {
      const response = await apiClient.put('/api/v1/cost/budget', data, {
        headers: { 'X-Workspace-ID': user?.workspace_id }
      })
      return response.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['budget'] })
      queryClient.invalidateQueries({ queryKey: ['cost-overview'] })
      toast({
        title: 'Budget Updated',
        description: 'Your budget limits and alert thresholds have been updated successfully.',
      })
      onOpenChange(false)
    },
    onError: (error: any) => {
      setError(error.response?.data?.detail || 'Failed to update budget')
    },
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    const budgetValue = parseFloat(budgetLimit)
    if (isNaN(budgetValue) || budgetValue <= 0) {
      setError('Please enter a valid budget amount')
      return
    }

    if (alertThreshold < 0 || alertThreshold > 100) {
      setError('Alert threshold must be between 0 and 100')
      return
    }

    updateBudgetMutation.mutate({
      monthly_limit_usd: budgetValue,
      alert_threshold_percentage: alertThreshold,
    })
  }

  const previewAlertAmount = (parseFloat(budgetLimit) || 0) * (alertThreshold / 100)

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Bell className="h-5 w-5" />
            Set Budget Alert
          </DialogTitle>
          <DialogDescription>
            Configure monthly budget limits and alert thresholds to monitor spending
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit}>
          <div className="space-y-6 py-4">
            {/* Budget Limit */}
            <div className="space-y-2">
              <Label htmlFor="budget" className="flex items-center gap-2">
                <DollarSign className="h-4 w-4" />
                Monthly Budget Limit
              </Label>
              <Input
                id="budget"
                type="number"
                placeholder="1000.00"
                value={budgetLimit}
                onChange={(e) => setBudgetLimit(e.target.value)}
                step="0.01"
                min="0"
                required
              />
              <p className="text-xs text-muted-foreground">
                Maximum amount you want to spend per month
              </p>
            </div>

            {/* Alert Threshold */}
            <div className="space-y-3">
              <Label className="flex items-center gap-2">
                <Percent className="h-4 w-4" />
                Alert Threshold
              </Label>
              <div className="flex items-center gap-4">
                <Slider
                  value={[alertThreshold]}
                  onValueChange={([value]) => setAlertThreshold(value)}
                  min={0}
                  max={100}
                  step={5}
                  className="flex-1"
                />
                <div className="w-16 text-right">
                  <span className="text-lg font-bold">{alertThreshold}%</span>
                </div>
              </div>
              <p className="text-xs text-muted-foreground">
                Receive alerts when spending exceeds this percentage of your budget
              </p>
            </div>

            {/* Preview */}
            {budgetLimit && parseFloat(budgetLimit) > 0 && (
              <div className="p-4 bg-muted rounded-lg space-y-2">
                <h4 className="text-sm font-semibold">Alert Preview</h4>
                <div className="space-y-1 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Monthly Budget:</span>
                    <span className="font-medium">${parseFloat(budgetLimit).toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Alert Threshold:</span>
                    <span className="font-medium">{alertThreshold}%</span>
                  </div>
                  <div className="flex justify-between pt-2 border-t">
                    <span className="text-muted-foreground">Alert Triggered At:</span>
                    <span className="font-bold text-amber-600">
                      ${previewAlertAmount.toFixed(2)}
                    </span>
                  </div>
                </div>
              </div>
            )}

            {/* Warning for low thresholds */}
            {alertThreshold < 50 && (
              <Alert>
                <AlertTriangle className="h-4 w-4" />
                <AlertDescription className="text-xs">
                  Setting a low threshold may result in receiving alerts too late to take preventive action.
                  Consider setting it to at least 70%.
                </AlertDescription>
              </Alert>
            )}

            {/* Error Message */}
            {error && (
              <Alert variant="destructive">
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={updateBudgetMutation.isPending}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={updateBudgetMutation.isPending}>
              {updateBudgetMutation.isPending ? 'Saving...' : 'Save Budget'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

'use client'

import { useState } from 'react'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

interface SetGoalModalProps {
  open: boolean
  onClose: () => void
  onSave: (goal: GoalFormData) => void
}

export interface GoalFormData {
  goal_type: string
  name: string
  description: string
  target_value: number
  unit: string
  target_date: string
  agent_id?: string
  department_id?: string
}

export function SetGoalModal({ open, onClose, onSave }: SetGoalModalProps) {
  const [formData, setFormData] = useState<GoalFormData>({
    goal_type: 'cost_savings',
    name: '',
    description: '',
    target_value: 0,
    unit: 'usd',
    target_date: '',
    agent_id: '',
    department_id: '',
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSave(formData)
    onClose()
    // Reset form
    setFormData({
      goal_type: 'cost_savings',
      name: '',
      description: '',
      target_value: 0,
      unit: 'usd',
      target_date: '',
      agent_id: '',
      department_id: '',
    })
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[600px]">
        <form onSubmit={handleSubmit}>
          <DialogHeader>
            <DialogTitle>Set Business Goal</DialogTitle>
            <DialogDescription>
              Define a new business goal to track AI agent impact against organizational objectives.
            </DialogDescription>
          </DialogHeader>

          <div className="grid gap-4 py-4">
            {/* Goal Type */}
            <div className="grid gap-2">
              <Label htmlFor="goal_type">Goal Type</Label>
              <Select
                value={formData.goal_type}
                onValueChange={(value) => setFormData({ ...formData, goal_type: value })}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select goal type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="cost_savings">Cost Savings</SelectItem>
                  <SelectItem value="revenue">Revenue Impact</SelectItem>
                  <SelectItem value="productivity">Productivity Gains</SelectItem>
                  <SelectItem value="csat">Customer Satisfaction</SelectItem>
                  <SelectItem value="ticket_reduction">Ticket Reduction</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Goal Name */}
            <div className="grid gap-2">
              <Label htmlFor="name">Goal Name</Label>
              <Input
                id="name"
                placeholder="e.g., Reduce AI Infrastructure Costs"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </div>

            {/* Description */}
            <div className="grid gap-2">
              <Label htmlFor="description">Description</Label>
              <Textarea
                id="description"
                placeholder="Describe the goal and its business impact..."
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                rows={3}
              />
            </div>

            {/* Target Value and Unit */}
            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="target_value">Target Value</Label>
                <Input
                  id="target_value"
                  type="number"
                  placeholder="50000"
                  value={formData.target_value || ''}
                  onChange={(e) => setFormData({ ...formData, target_value: parseFloat(e.target.value) })}
                  required
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="unit">Unit</Label>
                <Select
                  value={formData.unit}
                  onValueChange={(value) => setFormData({ ...formData, unit: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="usd">USD ($)</SelectItem>
                    <SelectItem value="tickets">Tickets</SelectItem>
                    <SelectItem value="hours">Hours</SelectItem>
                    <SelectItem value="score">Score</SelectItem>
                    <SelectItem value="percentage">Percentage (%)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* Target Date */}
            <div className="grid gap-2">
              <Label htmlFor="target_date">Target Date</Label>
              <Input
                id="target_date"
                type="date"
                value={formData.target_date}
                onChange={(e) => setFormData({ ...formData, target_date: e.target.value })}
                required
              />
            </div>

            {/* Optional: Agent ID */}
            <div className="grid gap-2">
              <Label htmlFor="agent_id">Agent ID (Optional)</Label>
              <Input
                id="agent_id"
                placeholder="e.g., customer-support-ai-001"
                value={formData.agent_id}
                onChange={(e) => setFormData({ ...formData, agent_id: e.target.value })}
              />
              <p className="text-xs text-muted-foreground">
                Link this goal to a specific agent to track its contribution
              </p>
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit">Create Goal</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

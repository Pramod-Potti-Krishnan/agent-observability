'use client'

import { useState } from 'react'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Checkbox } from '@/components/ui/checkbox'
import { FileText, Download } from 'lucide-react'

interface GenerateReportModalProps {
  open: boolean
  onClose: () => void
  onGenerate: (config: ReportConfig) => void
}

export interface ReportConfig {
  timeRange: string
  format: string
  sections: string[]
  includeCharts: boolean
}

export function GenerateReportModal({ open, onClose, onGenerate }: GenerateReportModalProps) {
  const [config, setConfig] = useState<ReportConfig>({
    timeRange: '30d',
    format: 'pdf',
    sections: ['overview', 'goals', 'attribution', 'recommendations'],
    includeCharts: true,
  })

  const handleGenerate = () => {
    onGenerate(config)
    onClose()
  }

  const toggleSection = (section: string) => {
    setConfig({
      ...config,
      sections: config.sections.includes(section)
        ? config.sections.filter((s) => s !== section)
        : [...config.sections, section],
    })
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5" />
            Generate Executive Report
          </DialogTitle>
          <DialogDescription>
            Create a comprehensive report on AI agent business impact for stakeholders.
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-4 py-4">
          {/* Time Range */}
          <div className="grid gap-2">
            <Label>Report Period</Label>
            <Select value={config.timeRange} onValueChange={(value) => setConfig({ ...config, timeRange: value })}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="7d">Last 7 Days</SelectItem>
                <SelectItem value="30d">Last 30 Days</SelectItem>
                <SelectItem value="90d">Last 90 Days</SelectItem>
                <SelectItem value="1y">Last Year</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Format */}
          <div className="grid gap-2">
            <Label>Export Format</Label>
            <Select value={config.format} onValueChange={(value) => setConfig({ ...config, format: value })}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="pdf">PDF Document</SelectItem>
                <SelectItem value="excel">Excel Spreadsheet</SelectItem>
                <SelectItem value="pptx">PowerPoint Presentation</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Sections to Include */}
          <div className="grid gap-2">
            <Label>Report Sections</Label>
            <div className="space-y-2 border rounded-md p-3">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="overview"
                  checked={config.sections.includes('overview')}
                  onCheckedChange={() => toggleSection('overview')}
                />
                <label htmlFor="overview" className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
                  Executive Summary & ROI Overview
                </label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="goals"
                  checked={config.sections.includes('goals')}
                  onCheckedChange={() => toggleSection('goals')}
                />
                <label htmlFor="goals" className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
                  Business Goals Progress
                </label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="attribution"
                  checked={config.sections.includes('attribution')}
                  onCheckedChange={() => toggleSection('attribution')}
                />
                <label htmlFor="attribution" className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
                  Value Attribution by Agent
                </label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="customer"
                  checked={config.sections.includes('customer')}
                  onCheckedChange={() => toggleSection('customer')}
                />
                <label htmlFor="customer" className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
                  Customer Impact & Satisfaction
                </label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="recommendations"
                  checked={config.sections.includes('recommendations')}
                  onCheckedChange={() => toggleSection('recommendations')}
                />
                <label htmlFor="recommendations" className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
                  AI-Powered Recommendations
                </label>
              </div>
            </div>
          </div>

          {/* Include Charts */}
          <div className="flex items-center space-x-2">
            <Checkbox
              id="charts"
              checked={config.includeCharts}
              onCheckedChange={(checked) => setConfig({ ...config, includeCharts: checked as boolean })}
            />
            <label htmlFor="charts" className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
              Include charts and visualizations
            </label>
          </div>
        </div>

        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button onClick={handleGenerate}>
            <Download className="h-4 w-4 mr-2" />
            Generate Report
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

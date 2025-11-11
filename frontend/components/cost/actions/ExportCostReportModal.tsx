'use client'

import { useState } from 'react'
import { useMutation } from '@tanstack/react-query'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
import { Checkbox } from '@/components/ui/checkbox'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Download, FileText, FileSpreadsheet, FileJson, Calendar, CheckCircle2 } from 'lucide-react'
import apiClient from '@/lib/api-client'
import { useAuth } from '@/lib/auth-context'
import { useToast } from '@/hooks/use-toast'

interface ExportCostReportModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

type ExportFormat = 'csv' | 'pdf' | 'json'
type TimeRange = '7d' | '30d' | '90d' | 'all'

/**
 * ExportCostReportModal - Export cost data and reports
 *
 * Features:
 * - Multiple export formats (CSV, PDF, JSON)
 * - Flexible time range selection
 * - Customizable data sections
 * - Progress indicator
 * - Direct download
 *
 * PRD Tab 3: Action Modal 3 - Report Export
 */
export function ExportCostReportModal({
  open,
  onOpenChange
}: ExportCostReportModalProps) {
  const { user } = useAuth()
  const { toast } = useToast()

  const [format, setFormat] = useState<ExportFormat>('csv')
  const [timeRange, setTimeRange] = useState<TimeRange>('30d')
  const [includeSections, setIncludeSections] = useState({
    overview: true,
    byAgent: true,
    byModel: true,
    byDepartment: true,
    trends: true,
    recommendations: false,
  })

  const exportMutation = useMutation({
    mutationFn: async () => {
      const params = new URLSearchParams({
        format,
        range: timeRange,
        sections: Object.entries(includeSections)
          .filter(([_, include]) => include)
          .map(([section]) => section)
          .join(','),
      })

      const response = await apiClient.get(
        `/api/v1/cost/export?${params.toString()}`,
        {
          headers: { 'X-Workspace-ID': user?.workspace_id },
          responseType: 'blob',
        }
      )

      // Create download link
      const url = window.URL.createObjectURL(new Blob([response.data]))
      const link = document.createElement('a')
      link.href = url
      const extension = format === 'pdf' ? 'pdf' : format === 'json' ? 'json' : 'csv'
      link.setAttribute('download', `cost-report-${timeRange}.${extension}`)
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)

      return response.data
    },
    onSuccess: () => {
      toast({
        title: 'Report Exported',
        description: `Your cost report has been downloaded successfully.`,
      })
      onOpenChange(false)
    },
    onError: (error: any) => {
      toast({
        title: 'Export Failed',
        description: error.response?.data?.detail || 'Failed to export report',
        variant: 'destructive',
      })
    },
  })

  const handleExport = () => {
    exportMutation.mutate()
  }

  const getFormatIcon = (fmt: ExportFormat) => {
    switch (fmt) {
      case 'csv':
        return FileSpreadsheet
      case 'pdf':
        return FileText
      case 'json':
        return FileJson
    }
  }

  const selectedSectionsCount = Object.values(includeSections).filter(Boolean).length

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Download className="h-5 w-5" />
            Export Cost Report
          </DialogTitle>
          <DialogDescription>
            Download detailed cost analytics and trends
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6 py-4">
          {/* Export Format */}
          <div className="space-y-3">
            <Label>Export Format</Label>
            <RadioGroup value={format} onValueChange={(value) => setFormat(value as ExportFormat)}>
              <div className="flex items-center space-x-2 p-3 border rounded hover:bg-muted/50 cursor-pointer">
                <RadioGroupItem value="csv" id="csv" />
                <Label htmlFor="csv" className="flex items-center gap-2 cursor-pointer flex-1">
                  <FileSpreadsheet className="h-4 w-4 text-green-600" />
                  <div>
                    <p className="font-medium">CSV</p>
                    <p className="text-xs text-muted-foreground">Spreadsheet-friendly format</p>
                  </div>
                </Label>
              </div>
              <div className="flex items-center space-x-2 p-3 border rounded hover:bg-muted/50 cursor-pointer">
                <RadioGroupItem value="pdf" id="pdf" />
                <Label htmlFor="pdf" className="flex items-center gap-2 cursor-pointer flex-1">
                  <FileText className="h-4 w-4 text-red-600" />
                  <div>
                    <p className="font-medium">PDF</p>
                    <p className="text-xs text-muted-foreground">Professional report with charts</p>
                  </div>
                </Label>
              </div>
              <div className="flex items-center space-x-2 p-3 border rounded hover:bg-muted/50 cursor-pointer">
                <RadioGroupItem value="json" id="json" />
                <Label htmlFor="json" className="flex items-center gap-2 cursor-pointer flex-1">
                  <FileJson className="h-4 w-4 text-blue-600" />
                  <div>
                    <p className="font-medium">JSON</p>
                    <p className="text-xs text-muted-foreground">Raw data for custom processing</p>
                  </div>
                </Label>
              </div>
            </RadioGroup>
          </div>

          {/* Time Range */}
          <div className="space-y-3">
            <Label className="flex items-center gap-2">
              <Calendar className="h-4 w-4" />
              Time Range
            </Label>
            <RadioGroup value={timeRange} onValueChange={(value) => setTimeRange(value as TimeRange)}>
              <div className="grid grid-cols-2 gap-2">
                <div className="flex items-center space-x-2 p-2 border rounded hover:bg-muted/50 cursor-pointer">
                  <RadioGroupItem value="7d" id="7d" />
                  <Label htmlFor="7d" className="cursor-pointer flex-1 text-sm">Last 7 days</Label>
                </div>
                <div className="flex items-center space-x-2 p-2 border rounded hover:bg-muted/50 cursor-pointer">
                  <RadioGroupItem value="30d" id="30d" />
                  <Label htmlFor="30d" className="cursor-pointer flex-1 text-sm">Last 30 days</Label>
                </div>
                <div className="flex items-center space-x-2 p-2 border rounded hover:bg-muted/50 cursor-pointer">
                  <RadioGroupItem value="90d" id="90d" />
                  <Label htmlFor="90d" className="cursor-pointer flex-1 text-sm">Last 90 days</Label>
                </div>
                <div className="flex items-center space-x-2 p-2 border rounded hover:bg-muted/50 cursor-pointer">
                  <RadioGroupItem value="all" id="all" />
                  <Label htmlFor="all" className="cursor-pointer flex-1 text-sm">All time</Label>
                </div>
              </div>
            </RadioGroup>
          </div>

          {/* Data Sections */}
          <div className="space-y-3">
            <Label>Include Sections ({selectedSectionsCount} selected)</Label>
            <div className="space-y-2">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="overview"
                  checked={includeSections.overview}
                  onCheckedChange={(checked) =>
                    setIncludeSections({ ...includeSections, overview: !!checked })
                  }
                />
                <Label htmlFor="overview" className="text-sm cursor-pointer">
                  Cost Overview & Summary
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="byAgent"
                  checked={includeSections.byAgent}
                  onCheckedChange={(checked) =>
                    setIncludeSections({ ...includeSections, byAgent: !!checked })
                  }
                />
                <Label htmlFor="byAgent" className="text-sm cursor-pointer">
                  Cost by Agent
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="byModel"
                  checked={includeSections.byModel}
                  onCheckedChange={(checked) =>
                    setIncludeSections({ ...includeSections, byModel: !!checked })
                  }
                />
                <Label htmlFor="byModel" className="text-sm cursor-pointer">
                  Cost by Model
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="byDepartment"
                  checked={includeSections.byDepartment}
                  onCheckedChange={(checked) =>
                    setIncludeSections({ ...includeSections, byDepartment: !!checked })
                  }
                />
                <Label htmlFor="byDepartment" className="text-sm cursor-pointer">
                  Cost by Department
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="trends"
                  checked={includeSections.trends}
                  onCheckedChange={(checked) =>
                    setIncludeSections({ ...includeSections, trends: !!checked })
                  }
                />
                <Label htmlFor="trends" className="text-sm cursor-pointer">
                  Trends & Forecasts
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="recommendations"
                  checked={includeSections.recommendations}
                  onCheckedChange={(checked) =>
                    setIncludeSections({ ...includeSections, recommendations: !!checked })
                  }
                />
                <Label htmlFor="recommendations" className="text-sm cursor-pointer">
                  Optimization Recommendations
                </Label>
              </div>
            </div>
          </div>

          {/* Preview Info */}
          {selectedSectionsCount > 0 && (
            <Alert>
              <CheckCircle2 className="h-4 w-4" />
              <AlertDescription className="text-xs">
                Your report will include {selectedSectionsCount} section{selectedSectionsCount !== 1 ? 's' : ''} covering {timeRange === 'all' ? 'all available data' : `the last ${timeRange}`}.
              </AlertDescription>
            </Alert>
          )}
        </div>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={exportMutation.isPending}
          >
            Cancel
          </Button>
          <Button
            onClick={handleExport}
            disabled={exportMutation.isPending || selectedSectionsCount === 0}
          >
            <Download className="h-4 w-4 mr-2" />
            {exportMutation.isPending ? 'Exporting...' : 'Export Report'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

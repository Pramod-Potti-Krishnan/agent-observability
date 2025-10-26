'use client'

import { Button } from '@/components/ui/button'

interface QualityFiltersProps {
  timeRange: string
  onTimeRangeChange: (range: string) => void
}

export function QualityFilters({ timeRange, onTimeRangeChange }: QualityFiltersProps) {
  const timeRanges = [
    { value: '24h', label: 'Last 24h' },
    { value: '7d', label: 'Last 7 Days' },
    { value: '30d', label: 'Last 30 Days' }
  ]

  return (
    <div className="flex items-center gap-2">
      {timeRanges.map((range) => (
        <Button
          key={range.value}
          variant={timeRange === range.value ? 'default' : 'outline'}
          size="sm"
          onClick={() => onTimeRangeChange(range.value)}
          className="transition-all"
        >
          {range.label}
        </Button>
      ))}
    </div>
  )
}

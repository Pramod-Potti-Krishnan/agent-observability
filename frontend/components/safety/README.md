# Safety Dashboard Components

## Overview
Complete implementation of the Safety Dashboard for Phase 4 of the Agent Observability Platform.

## Components Created

### 1. ViolationKPICard.tsx (111 lines)
**Purpose**: Display total violations with severity breakdown

**Features**:
- Large total violation count display
- Color-coded severity badges (Critical: red, High: orange, Medium: yellow)
- Severity icons (AlertTriangle, Zap, Shield)
- Trend percentage indicator
- Loading state with skeleton UI

**Props**:
```typescript
interface ViolationKPICardProps {
  totalViolations: number
  criticalCount: number
  highCount: number
  mediumCount: number
  trend: number // percentage change
  loading?: boolean
}
```

### 2. ViolationTrendChart.tsx (116 lines)
**Purpose**: Line chart showing violation trends over time by severity

**Features**:
- Multi-line chart with 3 severity levels
- Color-coded lines (Critical: red, High: orange, Medium: yellow)
- Date formatting on X-axis
- Interactive tooltip with hover details
- Legend for severity levels
- Empty state message

**Props**:
```typescript
interface DataPoint {
  date: string
  critical: number
  high: number
  medium: number
}

interface ViolationTrendChartProps {
  data: DataPoint[]
  loading?: boolean
}
```

### 3. TypeBreakdown.tsx (125 lines)
**Purpose**: Pie chart showing distribution of violation types

**Features**:
- Pie chart with percentage labels
- Color-coded segments:
  * PII: Blue (#3b82f6)
  * Toxicity: Red (#ef4444)
  * Injection: Orange (#f97316)
- Icon legend with counts
- Interactive tooltip
- Empty state when no violations

**Props**:
```typescript
interface TypeData {
  pii: number
  toxicity: number
  injection: number
}

interface TypeBreakdownProps {
  data: TypeData
  loading?: boolean
}
```

### 4. ViolationTable.tsx (142 lines)
**Purpose**: Table displaying recent violations with redacted PII content

**Features**:
- Shows last 15 violations
- **PII Redaction Display**: Shows redacted content like "[REDACTED: EMAIL]"
- Color-coded severity badges
- Type icons (Shield, AlertTriangle, Zap)
- Clickable trace IDs linking to trace details
- Relative time display (e.g., "5m ago", "2h ago")
- Scrollable with max height
- Empty state message

**Props**:
```typescript
interface Violation {
  id: string
  trace_id: string
  violation_type: string
  severity: string
  detected_content: string
  redacted_content: string
  created_at: string
}

interface ViolationTableProps {
  violations: Violation[]
  loading?: boolean
}
```

## Main Page Implementation

### safety/page.tsx (150 lines)
**Purpose**: Main Safety Dashboard page integrating all components

**Layout**:
1. Header with title and time range selector (24h, 7d, 30d)
2. 3-column grid:
   - Column 1: ViolationKPICard
   - Columns 2-3: TypeBreakdown (pie chart)
3. Full-width ViolationTrendChart
4. Full-width ViolationTable

**Data Fetching**:
- API: `GET /api/v1/guardrails/violations?range={timeRange}`
- Refresh interval: 60 seconds
- Workspace-scoped using X-Workspace-ID header

**Data Processing**:
- Aggregates violations by date and severity for trend chart
- Sorts violations by created_at for table display
- Limits table to 15 most recent violations

**Response Schema**:
```typescript
interface ViolationResponse {
  violations: Violation[]
  total_count: number
  severity_breakdown: {
    critical: number
    high: number
    medium: number
  }
  type_breakdown: {
    pii: number
    toxicity: number
    injection: number
  }
  trend_percentage: number
}
```

## Design Patterns Used

### Color Coding
- **Critical**: Red (#ef4444, bg-red-100, text-red-800, border-red-500)
- **High**: Orange (#f97316, bg-orange-100, text-orange-800, border-orange-500)
- **Medium**: Yellow (#eab308, bg-yellow-100, text-yellow-800, border-yellow-500)

### Icons
- **PII Detection**: Shield icon (blue)
- **Toxicity**: AlertTriangle icon (red)
- **Prompt Injection**: Zap icon (orange)

### States
- **Loading**: Skeleton placeholders
- **Error**: Alert component with destructive variant
- **Empty**: Friendly message: "No violations detected - your agents are safe!"

### Responsive Design
- Mobile: Single column layout
- Desktop: 3-column grid for KPI and type breakdown
- All charts use ResponsiveContainer from Recharts

## Integration Points

### Dependencies
- shadcn/ui components (Card, Badge, Table, Alert, Skeleton)
- Recharts (LineChart, PieChart)
- TanStack Query (useQuery)
- lucide-react icons
- Next.js Link for navigation

### API Integration
- Uses existing apiClient from @/lib/api-client
- Authenticates with useAuth context
- Includes workspace_id in request headers

### Navigation
- Trace IDs link to `/dashboard/traces/{trace_id}` for detailed view

## File Structure
```
frontend/
├── app/dashboard/safety/
│   └── page.tsx (150 lines)
└── components/safety/
    ├── ViolationKPICard.tsx (111 lines)
    ├── ViolationTrendChart.tsx (116 lines)
    ├── TypeBreakdown.tsx (125 lines)
    └── ViolationTable.tsx (142 lines)

Total: 644 lines of TypeScript/React code
```

## Next Steps

To complete the Safety Dashboard integration:

1. **Backend Service**: Ensure guardrail service is running on port 8005
2. **Gateway Proxy**: Add route for `/api/v1/guardrails/*` in gateway
3. **Synthetic Data**: Generate violation data using `backend/db/seed-violations.sql`
4. **Testing**: Verify with various time ranges and violation types
5. **Polish**: Test responsive design on mobile/tablet devices

## Testing Checklist

- [ ] Page renders without errors
- [ ] All components display loading states
- [ ] Empty states show appropriate messages
- [ ] Data fetching works with workspace_id header
- [ ] Time range selector changes data
- [ ] Charts render with correct colors
- [ ] Table shows redacted content properly
- [ ] Trace ID links navigate correctly
- [ ] Severity badges use correct colors
- [ ] Auto-refresh works (60s interval)
- [ ] Error states display on API failure
- [ ] Responsive design works on mobile

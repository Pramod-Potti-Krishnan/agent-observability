# API Calling Standards Reference Guide

> **Purpose**: This guide establishes best practices for making API calls in the AI Agent Observability Platform to prevent authentication and header-related errors.

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Core Principles](#core-principles)
3. [Frontend API Calling](#frontend-api-calling)
4. [Common Pitfalls](#common-pitfalls)
5. [Backend API Requirements](#backend-api-requirements)
6. [Examples](#examples)
7. [Troubleshooting](#troubleshooting)

---

## Quick Reference

### ✅ DO THIS (Correct)

```typescript
import apiClient from '@/lib/api-client';

const { data } = useQuery({
  queryKey: ['my-data'],
  queryFn: async () => {
    const response = await apiClient.get('/api/v1/my-endpoint');
    return response.data;
  },
  enabled: !authLoading && !!user?.workspace_id,
});
```

### ❌ NOT THIS (Incorrect)

```typescript
// DON'T DO THIS!
const { data } = useQuery({
  queryFn: async () => {
    const res = await fetch('/api/v1/my-endpoint', {
      headers: { 'X-Workspace-ID': user.workspace_id }
    });
    return res.json();
  },
  enabled: !!user?.workspace_id, // Missing authLoading check!
});
```

---

## Core Principles

### 1. **Always Use apiClient**

**Why**: The `apiClient` is a configured Axios instance that automatically:
- Adds the `Authorization: Bearer <token>` header from localStorage
- Adds the `X-Workspace-ID` header from localStorage
- Handles common errors (401, network errors)
- Provides consistent timeout behavior (30s)

**Location**: `/frontend/lib/api-client.ts`

### 2. **Never Use Native fetch() for Backend API Calls**

**Why**: Native `fetch()` requires manual header management, which is error-prone and causes race conditions with React state.

**Exception**: Only use `fetch()` for external third-party APIs (non-backend calls).

### 3. **Always Check authLoading State**

**Why**: Queries should not execute until authentication completes. Use both `!authLoading` AND `!!user?.workspace_id` in the `enabled` property.

```typescript
const { user, loading: authLoading } = useAuth();

const { data } = useQuery({
  // ...
  enabled: !authLoading && !!user?.workspace_id,
});
```

---

## Frontend API Calling

### Step-by-Step Guide

#### 1. Import Dependencies

```typescript
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import apiClient from '@/lib/api-client';
```

#### 2. Get Auth State

```typescript
const { user, loading: authLoading } = useAuth();
```

**Important**: Always destructure `loading` as `authLoading` to avoid naming conflicts.

#### 3. Define Your Query

```typescript
const { data, isLoading, error } = useQuery<YourResponseType>({
  queryKey: ['unique-key', ...dependencies],
  queryFn: async () => {
    const response = await apiClient.get('/api/v1/your-endpoint');
    return response.data;
  },
  enabled: !authLoading && !!user?.workspace_id,
  staleTime: 5 * 60 * 1000, // Optional: 5 minute cache
});
```

#### 4. Query Methods by HTTP Verb

```typescript
// GET request
const response = await apiClient.get('/api/v1/endpoint');

// GET with query params
const response = await apiClient.get('/api/v1/endpoint?param=value');
// OR
const params = new URLSearchParams({ param: 'value' });
const response = await apiClient.get(`/api/v1/endpoint?${params.toString()}`);

// POST request
const response = await apiClient.post('/api/v1/endpoint', {
  key: 'value'
});

// PUT request
const response = await apiClient.put('/api/v1/endpoint/123', {
  key: 'newValue'
});

// DELETE request
const response = await apiClient.delete('/api/v1/endpoint/123');
```

#### 5. Handle Response

```typescript
// Response structure from apiClient (Axios)
const response = await apiClient.get('/api/v1/endpoint');
const data = response.data;        // Actual response data
const status = response.status;     // HTTP status code
const headers = response.headers;   // Response headers
```

### Query Keys Best Practices

```typescript
// ✅ Good: Include all dependencies
queryKey: ['agents', range, sortBy, limit]

// ✅ Good: Hierarchical structure
queryKey: ['departments', departmentId, 'agents']

// ❌ Bad: Static key with dynamic data
queryKey: ['agents'] // Won't refetch when params change
```

---

## Common Pitfalls

### Pitfall 1: Using fetch() Instead of apiClient

**Problem**:
```typescript
const res = await fetch('/api/v1/endpoint', {
  headers: { 'X-Workspace-ID': user.workspace_id }
});
```

**Issue**: `user.workspace_id` might be `undefined` during React re-renders, causing "missing X-Workspace-ID" errors.

**Solution**:
```typescript
const response = await apiClient.get('/api/v1/endpoint');
```

### Pitfall 2: Missing authLoading Check

**Problem**:
```typescript
enabled: !!user?.workspace_id
```

**Issue**: Query might execute before auth fully loads, causing empty/undefined workspace_id.

**Solution**:
```typescript
enabled: !authLoading && !!user?.workspace_id
```

### Pitfall 3: Forgetting to Import apiClient

**Problem**:
```typescript
// Missing import
const response = await apiClient.get(...); // Error: apiClient not defined
```

**Solution**:
```typescript
import apiClient from '@/lib/api-client';
```

### Pitfall 4: Incorrect Response Access

**Problem**:
```typescript
const data = await apiClient.get('/api/v1/endpoint');
return data; // Returns Axios response object, not data
```

**Solution**:
```typescript
const response = await apiClient.get('/api/v1/endpoint');
return response.data; // Return actual data
```

---

## Backend API Requirements

### All Authenticated Endpoints MUST:

1. **Require X-Workspace-ID Header**

```python
@router.get("/my-endpoint")
async def my_endpoint(
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    conn: asyncpg.Connection = Depends(get_postgres_connection)
):
    # x_workspace_id is automatically extracted from header
    pass
```

2. **Return Consistent Response Format**

```python
# Success response
return {
    "data": [...],  # Main response data
    "meta": {       # Optional metadata
        "total": 100,
        "page": 1
    }
}

# Error response (handled by FastAPI)
raise HTTPException(
    status_code=400,
    detail="Clear error message"
)
```

3. **Use UUID for Workspace IDs**

```python
from uuid import UUID

workspace_id = UUID(x_workspace_id)  # Validate UUID format
```

---

## Examples

### Example 1: Simple GET Request

```typescript
"use client";

import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import apiClient from '@/lib/api-client';

interface Agent {
  id: string;
  name: string;
  status: string;
}

interface AgentsResponse {
  data: Agent[];
  meta: {
    total: number;
  };
}

export function AgentsList() {
  const { user, loading: authLoading } = useAuth();

  const { data, isLoading } = useQuery<AgentsResponse>({
    queryKey: ['agents'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/agents');
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  if (isLoading) return <div>Loading...</div>;
  if (!data) return <div>No data</div>;

  return (
    <div>
      <h2>Agents ({data.meta.total})</h2>
      {data.data.map(agent => (
        <div key={agent.id}>{agent.name}</div>
      ))}
    </div>
  );
}
```

### Example 2: GET with Query Parameters

```typescript
export function FilteredAgents() {
  const { user, loading: authLoading } = useAuth();
  const [department, setDepartment] = useState('engineering');
  const [status, setStatus] = useState('active');

  const { data } = useQuery<AgentsResponse>({
    queryKey: ['agents', department, status],
    queryFn: async () => {
      const params = new URLSearchParams({
        department,
        status,
      });
      const response = await apiClient.get(`/api/v1/agents?${params.toString()}`);
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
  });

  // ... render component
}
```

### Example 3: POST Request (Mutation)

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

export function CreateAgentForm() {
  const { user, loading: authLoading } = useAuth();
  const queryClient = useQueryClient();

  const createAgent = useMutation({
    mutationFn: async (newAgent: { name: string; type: string }) => {
      const response = await apiClient.post('/api/v1/agents', newAgent);
      return response.data;
    },
    onSuccess: () => {
      // Invalidate and refetch agents list
      queryClient.invalidateQueries({ queryKey: ['agents'] });
    },
  });

  const handleSubmit = async (formData: FormData) => {
    if (!authLoading && user?.workspace_id) {
      await createAgent.mutateAsync({
        name: formData.get('name') as string,
        type: formData.get('type') as string,
      });
    }
  };

  // ... render form
}
```

### Example 4: Cascading Queries

```typescript
export function DepartmentAgents() {
  const { user, loading: authLoading } = useAuth();
  const [selectedDept, setSelectedDept] = useState<string | null>(null);

  // First query: Get departments
  const { data: departments } = useQuery({
    queryKey: ['departments'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/departments');
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
  });

  // Second query: Get agents for selected department
  const { data: agents } = useQuery({
    queryKey: ['agents', selectedDept],
    queryFn: async () => {
      const response = await apiClient.get(`/api/v1/agents?department=${selectedDept}`);
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id && !!selectedDept,
    // Only fetch when department is selected
  });

  // ... render component
}
```

---

## Troubleshooting

### Issue: "Field required" for X-Workspace-ID

**Symptoms**:
- Console shows: `{"detail":[{"type":"missing","loc":["header","X-Workspace-ID"],"msg":"Field required"}]}`
- 422 or 500 errors on API calls
- When accessing API endpoints directly in browser (without apiClient)

**Causes**:
1. Using native `fetch()` instead of `apiClient`
2. Missing `authLoading` check in query `enabled` prop
3. workspace_id not in localStorage (login issue)
4. Accessing endpoints directly without authentication headers

**Solutions**:
1. Replace all `fetch()` with `apiClient.get/post/etc`
2. Add `enabled: !authLoading && !!user?.workspace_id`
3. Check localStorage: `localStorage.getItem('workspace_id')`
4. Verify login flow sets workspace_id in localStorage
5. If testing endpoints directly, use tools like Postman/curl with proper headers

### Issue: "invalid UUID" Error

**Symptoms**:
- Error: `invalid input for query argument $1: '' (invalid UUID '': length must be between 32..36 characters, got 0)`
- Empty string being sent as workspace_id

**Causes**:
1. Query executing before auth completes
2. React re-render causing temporary undefined state

**Solutions**:
1. Always use `enabled: !authLoading && !!user?.workspace_id`
2. Use `apiClient` which reads from localStorage (synchronous)

### Issue: Query Not Fetching

**Symptoms**:
- Component renders but no API call is made
- Data remains undefined

**Causes**:
1. `enabled` condition is false
2. Query key is stale and cached

**Solutions**:
1. Check: Is `authLoading` false? Is `user.workspace_id` defined?
2. Use React Query DevTools to inspect query state
3. Invalidate query: `queryClient.invalidateQueries({ queryKey: ['my-key'] })`

### Issue: Stale Data

**Symptoms**:
- Component shows old data
- Changes don't reflect immediately

**Solutions**:
1. Reduce `staleTime` or remove it for real-time data
2. Use `refetchInterval` for polling:
   ```typescript
   {
     refetchInterval: 30000, // Refetch every 30s
   }
   ```
3. Invalidate queries after mutations:
   ```typescript
   onSuccess: () => {
     queryClient.invalidateQueries({ queryKey: ['my-data'] });
   }
   ```

### Issue: Backend 500 Errors on Filter Endpoints

**Symptoms**:
- Filter endpoints (/api/v1/filters/*) return 500 Internal Server Error
- Frontend receives workspace_id header but query fails
- TypeError about undefined `.toFixed()` in some components

**Root Cause**:
Backend filter endpoints were passing string `workspace_id` directly to PostgreSQL queries that expect UUID type, causing type mismatch errors.

**Fixed In**:
- `/backend/query/app/routes/filters.py` - All 4 endpoints now cast `x_workspace_id` string to UUID before database queries

**Backend Pattern (for reference)**:
```python
from uuid import UUID

@router.get("/my-endpoint")
async def my_endpoint(
    x_workspace_id: str = Header(..., alias="X-Workspace-ID"),
    conn: asyncpg.Connection = Depends(get_connection)
):
    try:
        # ALWAYS cast string workspace_id to UUID before using in queries
        workspace_uuid = UUID(x_workspace_id)

        rows = await conn.fetch(query, workspace_uuid)  # Use workspace_uuid, not x_workspace_id

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid workspace ID format: {str(e)}"
        )
```

**Prevention**:
- When creating new backend endpoints that use workspace_id in SQL queries
- Always cast the string header value to UUID: `UUID(x_workspace_id)`
- Add ValueError exception handling for invalid UUID formats

---

## Verification Checklist

Before deploying new API-calling code, verify:

- [ ] `import apiClient from '@/lib/api-client'` is present
- [ ] All backend API calls use `apiClient.get/post/put/delete`
- [ ] Native `fetch()` only used for external APIs (if any)
- [ ] Auth destructured: `const { user, loading: authLoading } = useAuth()`
- [ ] Query has: `enabled: !authLoading && !!user?.workspace_id`
- [ ] Response accessed as: `response.data` not `response`
- [ ] Query keys include all dependencies
- [ ] TypeScript interfaces defined for responses
- [ ] Loading and error states handled in UI

---

## Related Files

### Frontend
- `/frontend/lib/api-client.ts` - Axios instance with interceptors
- `/frontend/lib/auth-context.tsx` - Auth state management
- `/frontend/components/filters/FilterBar.tsx` - Reference implementation
- `/frontend/components/cost/TopCostlyAgentsTable.tsx` - Reference implementation

### Backend
- `/backend/gateway/app/dependencies.py` - Auth dependencies
- `/backend/gateway/app/auth/routes.py` - Auth endpoints
- `/backend/query/app/routes/*.py` - API route handlers

---

## Summary

**Golden Rule**: Always use `apiClient` with proper auth checks.

```typescript
// The Perfect Pattern™
import apiClient from '@/lib/api-client';
const { user, loading: authLoading } = useAuth();

const { data } = useQuery({
  queryKey: ['resource', ...params],
  queryFn: async () => {
    const response = await apiClient.get('/api/v1/endpoint');
    return response.data;
  },
  enabled: !authLoading && !!user?.workspace_id,
});
```

Follow this pattern, and you'll never encounter X-Workspace-ID or authentication errors again.

---

## Null Safety and Data Validation

### Why Null Safety Matters

Frontend code MUST be defensive when handling API responses. Never assume API data is complete or in the expected format. Missing or incomplete data should gracefully degrade UI, not crash the application.

### Critical Pattern: Three-Layer Defense

**Layer 1: Loading Guards** - Prevent rendering incomplete data
**Layer 2: Null Safety in Calculations** - Protect mathematical operations
**Layer 3: Optional Chaining** - Safe property access

### Common Crash Scenarios

#### Scenario 1: Division by Undefined/Zero

**Problem:**
```typescript
// ❌ CRASHES when data.meta.total is undefined or 0
const percentage = (item.value / data.meta.total) * 100;
{percentage.toFixed(1)}%  // TypeError if percentage is NaN
```

**Solution:**
```typescript
// ✅ SAFE: Use defaults to prevent NaN
const percentage = ((item.value || 0) / (data.meta.total || 1)) * 100;
{percentage.toFixed(1)}%
```

#### Scenario 2: Math Operations on Empty Arrays

**Problem:**
```typescript
// ❌ CRASHES: Math.min([]) returns Infinity
const lowest = Math.min(...data.items.map(i => i.cost));
{lowest.toFixed(2)}  // Error: Infinity.toFixed() fails
```

**Solution:**
```typescript
// ✅ SAFE: Filter nulls and provide fallback
const lowest = Math.min(...data.items.map(i => i.cost).filter(v => v != null)) || 0;
{lowest.toFixed(2)}
```

#### Scenario 3: Nested Property Access

**Problem:**
```typescript
// ❌ CRASHES if data.meta or data.meta.stats is undefined
const total = data.meta.stats.total_cost;
```

**Solution:**
```typescript
// ✅ SAFE: Use optional chaining
const total = data?.meta?.stats?.total_cost ?? 0;
```

### Complete Defensive Pattern

```typescript
export function DataTable() {
  const { user, loading: authLoading } = useAuth();

  const { data, isLoading } = useQuery<MyResponse>({
    queryKey: ['my-data'],
    queryFn: async () => {
      const response = await apiClient.get('/api/v1/my-endpoint');
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
  });

  // Step 1: Handle loading state
  if (isLoading) return <Skeleton />;

  // Step 2: Handle empty/null data
  if (!data || !data.data || data.data.length === 0) {
    return <EmptyState message="No data available" />;
  }

  return (
    <Card>
      <CardContent>
        {/* Step 3: Guard critical calculations */}
        {(!data.meta?.critical_field || data.meta.critical_field === 0) ? (
          <div>Insufficient data for calculations</div>
        ) : (
          <>
            <Table>
              <TableBody>
                {data.data.map((item) => {
                  // Step 4: Null safety in calculations
                  const ratio = ((item.value || 0) / (data.meta.critical_field || 1)) * 100;
                  const score = item.score || 0;

                  return (
                    <TableRow key={item.id}>
                      <TableCell>
                        {/* Step 5: Safe formatting with optional chaining */}
                        {ratio.toFixed(1)}%
                      </TableCell>
                      <TableCell>
                        ${item.cost?.toFixed(2) ?? '0.00'}
                      </TableCell>
                      <TableCell>
                        {item.name ?? 'Unknown'}
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>

            {/* Summary calculations also protected */}
            <div className="summary">
              <p>Total: ${data?.meta?.total?.toFixed(2) ?? '0.00'}</p>
              <p>Average: ${(data?.meta?.average || 0).toFixed(2)}</p>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
```

### JSX Conditional Rendering: React Fragment Requirement

When using ternary operators in JSX with multiple elements, wrap them in a React Fragment:

```typescript
// ❌ SYNTAX ERROR: Multiple elements without wrapper
{hasData ? (
  <div>Data</div>
) : (
  <Table>...</Table>
  <div>Summary</div>  // Second element causes error
)}

// ✅ CORRECT: Wrap in fragment
{hasData ? (
  <div>Data</div>
) : (
  <>
    <Table>...</Table>
    <div>Summary</div>
  </>
)}
```

### Common NaN-Producing Operations

Be especially careful with these operations:

```typescript
// Division
x / 0                    // Infinity
x / undefined            // NaN
undefined / x            // NaN

// Math functions
Math.min(...[])          // Infinity
Math.max(...[])          // -Infinity
Math.sqrt(-1)            // NaN

// Type coercion
Number(undefined)        // NaN
parseInt(undefined)      // NaN
parseFloat('')           // NaN

// Arithmetic with undefined
undefined + 5            // NaN
undefined * 100          // NaN
undefined - 10           // NaN
```

### Safe Alternatives Reference

```typescript
// Safe division
const ratio = (numerator || 0) / (denominator || 1);

// Safe Math operations
const min = Math.min(...array.filter(v => v != null)) || 0;
const max = Math.max(...array.filter(v => v != null)) || 0;

// Safe array reduce
const sum = array.reduce((acc, item) => acc + (item.value || 0), 0);

// Safe number formatting
const formatted = (value || 0).toFixed(2);
const currency = `$${(value || 0).toLocaleString()}`;

// Safe property access
const nested = obj?.level1?.level2?.value ?? defaultValue;

// Safe array operations
const first = array?.[0] ?? defaultItem;
const filtered = (array || []).filter(Boolean);
```

### TypeScript Strict Mode

Enable strict null checks in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "strict": true,
    "strictNullChecks": true,
    "strictPropertyInitialization": true
  }
}
```

This forces you to handle null/undefined explicitly:

```typescript
// ❌ TypeScript error with strictNullChecks
const total: number = data.meta.total;  // Error: might be undefined

// ✅ Correct with null handling
const total: number = data.meta?.total ?? 0;
```

### Backend Response Contract

Backend APIs MUST return complete metadata with sensible defaults:

```python
# ❌ BAD: Null values in critical fields
return {
    "data": results,
    "meta": {
        "total": None,              # Will crash frontend
        "total_cost": None,         # Will crash frontend
    }
}

# ✅ GOOD: Always provide defaults
return {
    "data": results,
    "meta": {
        "total": len(results),
        "total_cost": sum(r.cost for r in results) or 0.0,  # Never None
        "average": (sum(r.cost for r in results) / len(results)) if results else 0.0,
    }
}
```

### Testing for Null Safety

Test components with incomplete data:

```typescript
// Test data with missing fields
const testCases = [
  { data: [], meta: {} },                          // Empty array
  { data: null, meta: null },                      // Null data
  { data: [{id: 1}], meta: {total: 0} },          // Zero division
  { data: [{id: 1}], meta: {total: undefined} },  // Undefined
  { data: [{cost: undefined}], meta: {total: 100} }, // Undefined in items
];

testCases.forEach(testData => {
  // Component should render without errors
  const { container } = render(<MyComponent data={testData} />);

  // Should not contain NaN or Infinity
  expect(container.innerHTML).not.toContain('NaN');
  expect(container.innerHTML).not.toContain('Infinity');
});
```

### Checklist: Before Deploying Components

- [ ] All division operations have null coalescing: `(a || 0) / (b || 1)`
- [ ] Math operations filter null values: `.filter(v => v != null)`
- [ ] Optional chaining used for nested properties: `obj?.prop?.nested`
- [ ] Nullish coalescing provides fallbacks: `?? defaultValue`
- [ ] Loading guards prevent rendering incomplete data
- [ ] React fragments wrap multiple JSX elements in ternary branches
- [ ] TypeScript strict mode enabled
- [ ] Tested with null/undefined/empty data scenarios
- [ ] No `.toFixed()` called on potentially NaN values without guards

---

**Last Updated**: 2025-10-30
**Version**: 1.1
**Maintained By**: Engineering Team

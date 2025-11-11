# Action Implementation Playbook

**Purpose**: Step-by-step guide for implementing actionable interventions
**Version**: 1.0
**Last Updated**: October 27, 2025
**Status**: Blueprint for Enterprise Release

---

## Implementation Steps

Every actionable intervention follows this 4-step pattern:

1. **Database Schema** - Action audit log
2. **Backend API Endpoint** - Permission checks, execution, logging
3. **Frontend UI Component** - Button, dialog, confirmation
4. **Testing** - Permission validation, success/failure scenarios

---

## Step 1: Database Schema

### Action Audit Log Table

```sql
CREATE TABLE action_audit_log (
    action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id),
    action_type VARCHAR(100) NOT NULL,  -- 'pause_agent', 'set_budget', etc.
    action_scope VARCHAR(50),  -- 'fleet' | 'department' | 'agent'
    
    -- Actor information
    actor_user_id UUID REFERENCES users(id),
    actor_role VARCHAR(50),
    
    -- Action details
    action_params JSONB NOT NULL,
    status VARCHAR(20) NOT NULL,  -- 'pending' | 'in_progress' | 'completed' | 'failed' | 'rolled_back'
    result JSONB,
    error_message TEXT,
    
    -- Rollback capability
    rollback_action_id UUID REFERENCES action_audit_log(id),
    can_rollback BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    rolled_back_at TIMESTAMPTZ
);

CREATE INDEX idx_action_audit_workspace ON action_audit_log(workspace_id, created_at DESC);
CREATE INDEX idx_action_audit_actor ON action_audit_log(actor_user_id, created_at DESC);
CREATE INDEX idx_action_audit_type ON action_audit_log(action_type, created_at DESC);
```

---

## Step 2: Backend API Endpoint

### Template Pattern

```python
from fastapi import APIRouter, Depends, HTTPException
from uuid import UUID
from pydantic import BaseModel

router = APIRouter()

# Input validation model
class ActionParams(BaseModel):
    # Action-specific parameters
    agent_id: str
    reason: str
    duration_minutes: int = 30

# Response model
class ActionResponse(BaseModel):
    action_id: UUID
    status: str
    result: dict

@router.post("/api/v1/actions/{action_name}")
async def execute_action(
    action_name: str,
    params: ActionParams,
    workspace_id: UUID = Depends(get_workspace_id),
    user: User = Depends(get_current_user),
    db = Depends(get_db),
    cache = Depends(get_cache)
) -> ActionResponse:
    """
    Execute action with comprehensive error handling.
    
    Steps:
    1. Validate permissions
    2. Log action initiation
    3. Execute action logic
    4. Update action log
    5. Invalidate caches
    6. Trigger notifications
    """
    
    # 1. Validate permissions
    if not user.can_perform_action(action_name, workspace_id):
        raise HTTPException(
            status_code=403,
            detail={
                'code': 'INSUFFICIENT_PERMISSIONS',
                'message': f'User does not have permission to execute {action_name}',
                'required_permission': f'actions:{action_name}',
                'user_role': user.role
            }
        )
    
    # 2. Log action initiation
    action_log = await create_action_log(
        db,
        workspace_id=workspace_id,
        action_type=action_name,
        action_scope='agent',  # or 'fleet', 'department'
        actor_user_id=user.id,
        actor_role=user.role,
        action_params=params.dict(),
        status='pending'
    )
    
    # 3. Execute action with error handling
    try:
        await update_action_status(db, action_log.action_id, 'in_progress')
        
        # Perform the actual action
        result = await perform_action(db, workspace_id, params)
        
        # 4. Update action log (success)
        await update_action_log(
            db,
            action_log.action_id,
            status='completed',
            result=result,
            completed_at=datetime.now()
        )
        
        # 5. Invalidate relevant caches
        await invalidate_action_caches(cache, workspace_id, action_name, params)
        
        # 6. Trigger notifications
        await notify_stakeholders(workspace_id, action_name, result)
        
        return ActionResponse(
            action_id=action_log.action_id,
            status='completed',
            result=result
        )
        
    except Exception as e:
        # Log failure
        await update_action_log(
            db,
            action_log.action_id,
            status='failed',
            error_message=str(e),
            completed_at=datetime.now()
        )
        
        # Re-raise with context
        raise HTTPException(
            status_code=500,
            detail={
                'code': 'ACTION_EXECUTION_FAILED',
                'message': f'Failed to execute {action_name}',
                'action_id': str(action_log.action_id),
                'error': str(e)
            }
        )

# Action-specific logic
async def perform_action(db, workspace_id: UUID, params: ActionParams):
    # Implement action logic here
    # Example: Pause agent
    await db.execute("""
        UPDATE agents
        SET status = 'paused', paused_until = NOW() + INTERVAL '%s minutes'
        WHERE workspace_id = $1 AND agent_id = $2
    """, params.duration_minutes, workspace_id, params.agent_id)
    
    return {
        'agent_id': params.agent_id,
        'previous_status': 'active',
        'new_status': 'paused',
        'resume_at': (datetime.now() + timedelta(minutes=params.duration_minutes)).isoformat()
    }

# Cache invalidation
async def invalidate_action_caches(cache, workspace_id: UUID, action_name: str, params):
    # Invalidate affected caches
    await cache.invalidate_pattern(f"*:{workspace_id}:*")
```

---

## Step 3: Frontend UI Component

### Action Button Component

```typescript
import { useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { useToast } from '@/components/ui/use-toast'
import apiClient from '@/lib/api-client'

interface ActionButtonProps {
  agentId: string
  actionName: string
  buttonLabel: string
  onSuccess?: (result: any) => void
  onError?: (error: any) => void
}

export function ActionButton({
  agentId,
  actionName,
  buttonLabel,
  onSuccess,
  onError
}: ActionButtonProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [reason, setReason] = useState('')
  const [duration, setDuration] = useState(30)
  const { toast } = useToast()
  const queryClient = useQueryClient()

  // Mutation for action execution
  const mutation = useMutation({
    mutationFn: (params) => 
      apiClient.post(`/api/v1/actions/${actionName}`, params),
    onSuccess: (data) => {
      // Show success toast
      toast({
        title: 'Action Executed Successfully',
        description: `${actionName} completed for agent ${agentId}`,
      })

      // Invalidate relevant queries
      queryClient.invalidateQueries(['agents'])
      queryClient.invalidateQueries(['home-kpis'])

      // Close dialog
      setIsOpen(false)

      // Callback
      onSuccess?.(data)
    },
    onError: (error: any) => {
      // Show error toast
      toast({
        title: 'Action Failed',
        description: error?.response?.data?.error?.message || 'Unknown error',
        variant: 'destructive',
      })

      // Callback
      onError?.(error)
    },
  })

  const handleConfirm = () => {
    mutation.mutate({
      agent_id: agentId,
      reason,
      duration_minutes: duration,
    })
  }

  return (
    <>
      <Button onClick={() => setIsOpen(true)}>{buttonLabel}</Button>

      <Dialog open={isOpen} onOpenChange={setIsOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{buttonLabel}</DialogTitle>
            <DialogDescription>
              This will {actionName.replace('_', ' ')} the agent: {agentId}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="reason">Reason</Label>
              <Textarea
                id="reason"
                placeholder="Why are you performing this action?"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="duration">Duration (minutes)</Label>
              <Input
                id="duration"
                type="number"
                value={duration}
                onChange={(e) => setDuration(parseInt(e.target.value))}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleConfirm}
              disabled={mutation.isLoading || !reason}
            >
              {mutation.isLoading ? 'Executing...' : 'Confirm'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}
```

---

## Step 4: Testing

### Backend Tests

```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_action_requires_authentication(client: AsyncClient):
    """Action should require authentication"""
    response = await client.post(
        "/api/v1/actions/pause_agent",
        json={"agent_id": "eng-code-1", "reason": "Test"}
    )
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_action_requires_permission(client: AsyncClient, viewer_user):
    """Action should check user permissions"""
    response = await client.post(
        "/api/v1/actions/pause_agent",
        json={"agent_id": "eng-code-1", "reason": "Test"},
        headers={"Authorization": f"Bearer {viewer_user.token}"}
    )
    assert response.status_code == 403
    assert "INSUFFICIENT_PERMISSIONS" in response.json()["error"]["code"]

@pytest.mark.asyncio
async def test_action_execution_success(client: AsyncClient, admin_user, db):
    """Action should execute successfully with proper permissions"""
    response = await client.post(
        "/api/v1/actions/pause_agent",
        json={
            "agent_id": "eng-code-1",
            "reason": "Maintenance",
            "duration_minutes": 30
        },
        headers={"Authorization": f"Bearer {admin_user.token}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "completed"
    assert "action_id" in data
    
    # Verify action logged
    action_log = await db.fetchrow(
        "SELECT * FROM action_audit_log WHERE action_id = $1",
        data["action_id"]
    )
    assert action_log["status"] == "completed"
    assert action_log["actor_user_id"] == admin_user.id

@pytest.mark.asyncio
async def test_action_rollback(client: AsyncClient, admin_user):
    """Action should support rollback"""
    # Execute action
    response = await client.post(
        "/api/v1/actions/pause_agent",
        json={"agent_id": "eng-code-1", "reason": "Test"}
    )
    action_id = response.json()["action_id"]
    
    # Rollback
    rollback_response = await client.post(
        f"/api/v1/actions/{action_id}/rollback",
        headers={"Authorization": f"Bearer {admin_user.token}"}
    )
    
    assert rollback_response.status_code == 200
```

### Frontend Tests

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { ActionButton } from './ActionButton'

describe('ActionButton', () => {
  it('renders button with correct label', () => {
    render(
      <ActionButton
        agentId="eng-code-1"
        actionName="pause_agent"
        buttonLabel="Pause Agent"
      />
    )
    expect(screen.getByText('Pause Agent')).toBeInTheDocument()
  })

  it('opens dialog on button click', () => {
    render(<ActionButton agentId="eng-code-1" actionName="pause_agent" buttonLabel="Pause" />)
    fireEvent.click(screen.getByText('Pause'))
    expect(screen.getByRole('dialog')).toBeInTheDocument()
  })

  it('requires reason before confirming', () => {
    render(<ActionButton agentId="eng-code-1" actionName="pause_agent" buttonLabel="Pause" />)
    fireEvent.click(screen.getByText('Pause'))
    const confirmButton = screen.getByText('Confirm')
    expect(confirmButton).toBeDisabled()
  })

  it('executes action on confirm', async () => {
    const onSuccess = jest.fn()
    render(
      <ActionButton
        agentId="eng-code-1"
        actionName="pause_agent"
        buttonLabel="Pause"
        onSuccess={onSuccess}
      />
    )
    
    fireEvent.click(screen.getByText('Pause'))
    fireEvent.change(screen.getByPlaceholderText('Why are you performing this action?'), {
      target: { value: 'Maintenance' }
    })
    fireEvent.click(screen.getByText('Confirm'))
    
    await waitFor(() => {
      expect(onSuccess).toHaveBeenCalled()
    })
  })
})
```

---

## Checklist

- [ ] Database schema created with action_audit_log table
- [ ] Backend endpoint validates permissions
- [ ] Backend logs action initiation, execution, completion
- [ ] Backend handles errors gracefully
- [ ] Backend invalidates relevant caches
- [ ] Frontend button component created
- [ ] Frontend dialog with confirmation
- [ ] Frontend shows loading state during execution
- [ ] Frontend shows success/error toasts
- [ ] Frontend invalidates React Query caches
- [ ] Backend tests cover: auth, permissions, success, failure, rollback
- [ ] Frontend tests cover: rendering, interaction, error handling
- [ ] Action documented with examples

---

**Document Version**: 1.0
**Last Updated**: October 27, 2025
**Status**: Active Blueprint

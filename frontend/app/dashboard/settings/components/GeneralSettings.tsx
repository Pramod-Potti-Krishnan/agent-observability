'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { toast } from 'sonner'
import { Loader2 } from 'lucide-react'

interface WorkspaceData {
  id: string
  name: string
  description?: string
  timezone: string
  owner_id: string
  created_at: string
  updated_at: string
  member_count: number
  plan: string
  settings?: Record<string, any>
}

export function GeneralSettings() {
  const [workspace, setWorkspace] = useState<WorkspaceData | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    fetchWorkspace()
  }, [])

  const fetchWorkspace = async () => {
    try {
      const workspaceId = localStorage.getItem('workspace_id') || '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'
      const response = await fetch('http://localhost:8000/api/v1/workspace', {
        headers: {
          'X-Workspace-ID': workspaceId
        }
      })

      if (!response.ok) {
        throw new Error(`Failed to fetch workspace: ${response.status}`)
      }

      const data = await response.json()
      setWorkspace(data)
    } catch (error) {
      toast.error('Failed to load workspace settings')
      console.error('Fetch workspace error:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSave = async () => {
    if (!workspace) return

    setSaving(true)
    try {
      const workspaceId = localStorage.getItem('workspace_id') || '37160be9-7d69-43b5-8d5f-9d7b5e14a57a'
      const response = await fetch('http://localhost:8000/api/v1/workspace', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-Workspace-ID': workspaceId
        },
        body: JSON.stringify({
          name: workspace.name,
          description: workspace.description || '',
          timezone: workspace.timezone
        })
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.detail || `Failed to update workspace: ${response.status}`)
      }

      const updatedData = await response.json()
      setWorkspace(updatedData)
      toast.success('Workspace settings updated successfully')
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Failed to save workspace settings')
      console.error('Save workspace error:', error)
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="flex items-center justify-center">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
            <span className="ml-2 text-muted-foreground">Loading workspace settings...</span>
          </div>
        </CardContent>
      </Card>
    )
  }

  if (!workspace) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="text-center text-muted-foreground">
            No workspace found. Please check your configuration.
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>General Settings</CardTitle>
          <CardDescription>
            Manage your workspace name, description, and basic configuration
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="space-y-2">
            <Label htmlFor="workspace-name">Workspace Name *</Label>
            <Input
              id="workspace-name"
              value={workspace.name}
              onChange={(e) => setWorkspace({ ...workspace, name: e.target.value })}
              placeholder="Enter workspace name"
              disabled={saving}
            />
            <p className="text-sm text-muted-foreground">
              The display name for your workspace
            </p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="workspace-description">Description</Label>
            <Textarea
              id="workspace-description"
              value={workspace.description || ''}
              onChange={(e) => setWorkspace({ ...workspace, description: e.target.value })}
              placeholder="Enter workspace description"
              rows={3}
              disabled={saving}
            />
            <p className="text-sm text-muted-foreground">
              A brief description of your workspace (optional)
            </p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="workspace-timezone">Timezone *</Label>
            <Input
              id="workspace-timezone"
              value={workspace.timezone}
              onChange={(e) => setWorkspace({ ...workspace, timezone: e.target.value })}
              placeholder="e.g., America/New_York"
              disabled={saving}
            />
            <p className="text-sm text-muted-foreground">
              IANA timezone identifier (e.g., America/New_York, Europe/London, Asia/Tokyo)
            </p>
          </div>

          <div className="flex items-center justify-between pt-4 border-t">
            <Button
              onClick={handleSave}
              disabled={saving || !workspace.name || !workspace.timezone}
            >
              {saving ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Saving...
                </>
              ) : (
                'Save Changes'
              )}
            </Button>
            <Button
              variant="outline"
              onClick={fetchWorkspace}
              disabled={saving}
            >
              Reset
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Workspace Information</CardTitle>
          <CardDescription>
            Read-only workspace details
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label className="text-muted-foreground">Workspace ID</Label>
              <p className="font-mono text-sm mt-1">{workspace.id}</p>
            </div>
            <div>
              <Label className="text-muted-foreground">Plan</Label>
              <p className="font-semibold mt-1 capitalize">{workspace.plan}</p>
            </div>
            <div>
              <Label className="text-muted-foreground">Team Members</Label>
              <p className="font-semibold mt-1">{workspace.member_count}</p>
            </div>
            <div>
              <Label className="text-muted-foreground">Created</Label>
              <p className="text-sm mt-1">
                {new Date(workspace.created_at).toLocaleDateString()}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

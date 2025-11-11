"use client";

import React, { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Checkbox } from '@/components/ui/checkbox';
import { Progress } from '@/components/ui/progress';
import { Separator } from '@/components/ui/separator';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Plus, Loader2, CheckCircle2, XCircle, ChevronDown, ChevronUp, Trash2 } from 'lucide-react';
import { useQuery, useMutation } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import { apiClient } from '@/lib/api-client';
import { useToast } from '@/hooks/use-toast';

interface CreateEvaluationDialogProps {
  agentId: string;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSuccess?: () => void;
  trigger?: React.ReactNode;
}

interface UnevaluatedTrace {
  trace_id: string;
  input: string;
  output: string;
  timestamp: string;
  status: string;
}

interface CustomCriterion {
  name: string;
  description: string;
  weight: number;
}

interface EvaluationProgress {
  current: number;
  total: number;
  currentTraceId?: string;
}

export function CreateEvaluationDialog({
  agentId,
  open: controlledOpen,
  onOpenChange: controlledOnOpenChange,
  onSuccess,
  trigger
}: CreateEvaluationDialogProps) {
  const { user } = useAuth();
  const { toast } = useToast();

  // Dialog state (controlled or uncontrolled)
  const [internalOpen, setInternalOpen] = useState(false);
  const open = controlledOpen !== undefined ? controlledOpen : internalOpen;
  const setOpen = controlledOnOpenChange || setInternalOpen;

  // Mode state
  const [mode, setMode] = useState<'auto' | 'manual'>('auto');

  // Auto mode state
  const [autoCount, setAutoCount] = useState(10);

  // Manual mode state
  const [selectedTraces, setSelectedTraces] = useState<string[]>([]);

  // Custom criteria state
  const [showCustomCriteria, setShowCustomCriteria] = useState(false);
  const [customCriteria, setCustomCriteria] = useState<CustomCriterion[]>([]);
  const [newCriterion, setNewCriterion] = useState<CustomCriterion>({
    name: '',
    description: '',
    weight: 1.0
  });

  // Evaluation progress state
  const [evaluating, setEvaluating] = useState(false);
  const [progress, setProgress] = useState<EvaluationProgress>({ current: 0, total: 0 });

  // Fetch unevaluated traces for manual mode
  const { data: tracesData, isLoading: tracesLoading } = useQuery({
    queryKey: ['unevaluated-traces', agentId],
    queryFn: async () => {
      const response = await apiClient.get(
        `/api/v1/quality/agent/${agentId}/unevaluated-traces?limit=50`,
        {
          headers: {
            'X-Workspace-ID': user?.workspace_id || '',
          },
        }
      );
      return response.data;
    },
    enabled: open && mode === 'manual' && !!user?.workspace_id,
  });

  // Evaluate mutation
  const evaluateMutation = useMutation({
    mutationFn: async () => {
      const requestBody: any = {
        mode,
        custom_criteria: customCriteria.length > 0 ? customCriteria : undefined,
      };

      if (mode === 'manual') {
        requestBody.trace_ids = selectedTraces;
      } else {
        requestBody.count = autoCount;
      }

      const response = await apiClient.post(
        `/api/v1/evaluate/agent/${agentId}`,
        requestBody,
        {
          headers: {
            'X-Workspace-ID': user?.workspace_id || '',
          },
        }
      );
      return response.data;
    },
    onMutate: () => {
      setEvaluating(true);
      const total = mode === 'manual' ? selectedTraces.length : autoCount;
      setProgress({ current: 0, total });
    },
    onSuccess: (data) => {
      setEvaluating(false);
      setOpen(false);

      // Reset form
      setSelectedTraces([]);
      setCustomCriteria([]);
      setShowCustomCriteria(false);

      // Show success toast
      const { successful, failed, total } = data;
      if (failed === 0) {
        toast({
          title: "Evaluation Complete",
          description: `Successfully evaluated ${successful} trace${successful !== 1 ? 's' : ''}.`,
          variant: "default",
        });
      } else {
        toast({
          title: "Evaluation Partially Complete",
          description: `Evaluated ${successful}/${total} traces. ${failed} failed.`,
          variant: "destructive",
        });
      }

      // Trigger parent refetch
      if (onSuccess) {
        onSuccess();
      }
    },
    onError: (error: any) => {
      setEvaluating(false);
      toast({
        title: "Evaluation Failed",
        description: error.response?.data?.detail || error.message || "Failed to evaluate traces",
        variant: "destructive",
      });
    },
  });

  // Simulated progress updates (since we don't have real-time progress)
  React.useEffect(() => {
    if (evaluating && progress.total > 0) {
      const interval = setInterval(() => {
        setProgress((prev) => {
          if (prev.current < prev.total) {
            return { ...prev, current: prev.current + 1 };
          }
          return prev;
        });
      }, 2000); // Simulate progress every 2 seconds

      return () => clearInterval(interval);
    }
  }, [evaluating, progress.total]);

  const handleAddCriterion = () => {
    if (newCriterion.name && newCriterion.description) {
      setCustomCriteria([...customCriteria, newCriterion]);
      setNewCriterion({ name: '', description: '', weight: 1.0 });
    }
  };

  const handleRemoveCriterion = (index: number) => {
    setCustomCriteria(customCriteria.filter((_, i) => i !== index));
  };

  const handleToggleTrace = (traceId: string) => {
    if (selectedTraces.includes(traceId)) {
      setSelectedTraces(selectedTraces.filter(id => id !== traceId));
    } else {
      setSelectedTraces([...selectedTraces, traceId]);
    }
  };

  const handleSelectAll = () => {
    if (tracesData?.traces) {
      const allIds = tracesData.traces.map((t: UnevaluatedTrace) => t.trace_id);
      setSelectedTraces(allIds);
    }
  };

  const handleDeselectAll = () => {
    setSelectedTraces([]);
  };

  const canStartEvaluation = () => {
    if (mode === 'manual') {
      return selectedTraces.length > 0;
    } else {
      return autoCount > 0 && autoCount <= 100;
    }
  };

  const progressPercentage = progress.total > 0 ? (progress.current / progress.total) * 100 : 0;

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {trigger || (
          <Button variant="outline" size="sm">
            <Plus className="h-4 w-4 mr-2" />
            Create Evaluation
          </Button>
        )}
      </DialogTrigger>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-hidden flex flex-col">
        <DialogHeader>
          <DialogTitle>Create LLM As-a-Judge Evaluation</DialogTitle>
          <DialogDescription>
            Evaluate traces for this agent using Gemini LLM-as-Judge with standard or custom criteria.
          </DialogDescription>
        </DialogHeader>

        <ScrollArea className="flex-1 pr-4">
          <div className="space-y-6 py-4">
            {/* Mode Selection */}
            <div className="space-y-3">
              <Label className="text-base font-semibold">Evaluation Mode</Label>
              <RadioGroup value={mode} onValueChange={(value) => setMode(value as 'auto' | 'manual')}>
                <div className="flex items-start space-x-3 space-y-0">
                  <RadioGroupItem value="auto" id="auto" />
                  <div className="space-y-1 leading-none">
                    <Label htmlFor="auto" className="font-medium cursor-pointer">
                      Auto-Evaluate Recent Traces
                    </Label>
                    <p className="text-sm text-muted-foreground">
                      Automatically evaluate the N most recent un-evaluated traces
                    </p>
                  </div>
                </div>
                <div className="flex items-start space-x-3 space-y-0">
                  <RadioGroupItem value="manual" id="manual" />
                  <div className="space-y-1 leading-none">
                    <Label htmlFor="manual" className="font-medium cursor-pointer">
                      Manual Selection
                    </Label>
                    <p className="text-sm text-muted-foreground">
                      Browse and select specific traces to evaluate
                    </p>
                  </div>
                </div>
              </RadioGroup>
            </div>

            <Separator />

            {/* Auto Mode */}
            {mode === 'auto' && (
              <div className="space-y-3">
                <Label htmlFor="count">Number of Traces to Evaluate</Label>
                <Input
                  id="count"
                  type="number"
                  min={1}
                  max={100}
                  value={autoCount}
                  onChange={(e) => setAutoCount(parseInt(e.target.value) || 10)}
                  className="w-32"
                />
                <p className="text-sm text-muted-foreground">
                  Evaluates the most recent un-evaluated traces (max 100)
                </p>
              </div>
            )}

            {/* Manual Mode */}
            {mode === 'manual' && (
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <Label>Select Traces to Evaluate</Label>
                  <div className="flex gap-2">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={handleSelectAll}
                      disabled={tracesLoading || !tracesData?.traces?.length}
                    >
                      Select All
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={handleDeselectAll}
                      disabled={selectedTraces.length === 0}
                    >
                      Deselect All
                    </Button>
                  </div>
                </div>

                {tracesLoading && (
                  <div className="flex items-center justify-center py-8">
                    <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                  </div>
                )}

                {!tracesLoading && tracesData?.traces?.length === 0 && (
                  <div className="text-center py-8 text-muted-foreground">
                    <p>No un-evaluated traces found for this agent.</p>
                  </div>
                )}

                {!tracesLoading && tracesData?.traces?.length > 0 && (
                  <div className="border rounded-lg max-h-64 overflow-y-auto">
                    {tracesData.traces.map((trace: UnevaluatedTrace) => (
                      <div
                        key={trace.trace_id}
                        className="flex items-start gap-3 p-3 border-b last:border-b-0 hover:bg-muted/50"
                      >
                        <Checkbox
                          checked={selectedTraces.includes(trace.trace_id)}
                          onCheckedChange={() => handleToggleTrace(trace.trace_id)}
                        />
                        <div className="flex-1 space-y-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <code className="text-xs font-mono bg-muted px-1 py-0.5 rounded">
                              {trace.trace_id.substring(0, 12)}...
                            </code>
                            <span className="text-xs text-muted-foreground">
                              {new Date(trace.timestamp).toLocaleString()}
                            </span>
                          </div>
                          <p className="text-sm truncate text-muted-foreground">
                            {trace.input.substring(0, 100)}...
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                {selectedTraces.length > 0 && (
                  <Badge variant="secondary">
                    {selectedTraces.length} trace{selectedTraces.length !== 1 ? 's' : ''} selected
                  </Badge>
                )}
              </div>
            )}

            <Separator />

            {/* Custom Criteria Section */}
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <Label className="text-base font-semibold">Evaluation Criteria</Label>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setShowCustomCriteria(!showCustomCriteria)}
                >
                  {showCustomCriteria ? (
                    <>
                      <ChevronUp className="h-4 w-4 mr-1" />
                      Hide Custom Criteria
                    </>
                  ) : (
                    <>
                      <ChevronDown className="h-4 w-4 mr-1" />
                      Add Custom Criteria
                    </>
                  )}
                </Button>
              </div>

              <div className="text-sm text-muted-foreground">
                <p className="mb-2">Standard criteria (always included):</p>
                <ul className="list-disc list-inside space-y-1">
                  <li>Accuracy - Factual correctness</li>
                  <li>Relevance - On-topic responses</li>
                  <li>Helpfulness - Actionable and useful</li>
                  <li>Coherence - Well-structured</li>
                </ul>
              </div>

              {showCustomCriteria && (
                <div className="space-y-4 p-4 border rounded-lg bg-muted/30">
                  {/* Existing custom criteria */}
                  {customCriteria.length > 0 && (
                    <div className="space-y-2">
                      {customCriteria.map((criterion, index) => (
                        <div key={index} className="flex items-start gap-2 p-2 bg-background rounded border">
                          <div className="flex-1 space-y-1">
                            <div className="flex items-center gap-2">
                              <span className="font-medium text-sm">{criterion.name}</span>
                              <Badge variant="outline" className="text-xs">
                                Weight: {criterion.weight}
                              </Badge>
                            </div>
                            <p className="text-xs text-muted-foreground">{criterion.description}</p>
                          </div>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8"
                            onClick={() => handleRemoveCriterion(index)}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Add new criterion form */}
                  <div className="space-y-3">
                    <Label>Add Custom Criterion</Label>
                    <Input
                      placeholder="Criterion name (e.g., Tone)"
                      value={newCriterion.name}
                      onChange={(e) => setNewCriterion({ ...newCriterion, name: e.target.value })}
                    />
                    <Input
                      placeholder="Description (e.g., Is the tone professional and friendly?)"
                      value={newCriterion.description}
                      onChange={(e) => setNewCriterion({ ...newCriterion, description: e.target.value })}
                    />
                    <div className="flex items-center gap-2">
                      <Label htmlFor="weight" className="whitespace-nowrap">
                        Weight:
                      </Label>
                      <Input
                        id="weight"
                        type="number"
                        min={0}
                        max={2}
                        step={0.1}
                        value={newCriterion.weight}
                        onChange={(e) => setNewCriterion({ ...newCriterion, weight: parseFloat(e.target.value) || 1.0 })}
                        className="w-24"
                      />
                      <span className="text-sm text-muted-foreground">(0.0 - 2.0)</span>
                    </div>
                    <Button
                      size="sm"
                      onClick={handleAddCriterion}
                      disabled={!newCriterion.name || !newCriterion.description}
                    >
                      <Plus className="h-4 w-4 mr-1" />
                      Add Criterion
                    </Button>
                  </div>
                </div>
              )}
            </div>

            {/* Progress Section */}
            {evaluating && (
              <>
                <Separator />
                <div className="space-y-3">
                  <Label className="text-base font-semibold">Evaluation Progress</Label>
                  <div className="space-y-2">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted-foreground">
                        Evaluating traces... {progress.current} / {progress.total}
                      </span>
                      <span className="font-medium">{Math.round(progressPercentage)}%</span>
                    </div>
                    <Progress value={progressPercentage} className="h-2" />
                  </div>
                  {progress.currentTraceId && (
                    <p className="text-xs text-muted-foreground">
                      Current: {progress.currentTraceId.substring(0, 12)}...
                    </p>
                  )}
                </div>
              </>
            )}
          </div>
        </ScrollArea>

        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)} disabled={evaluating}>
            Cancel
          </Button>
          <Button
            onClick={() => evaluateMutation.mutate()}
            disabled={!canStartEvaluation() || evaluating}
          >
            {evaluating ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Evaluating...
              </>
            ) : (
              <>
                <CheckCircle2 className="h-4 w-4 mr-2" />
                Start Evaluation
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

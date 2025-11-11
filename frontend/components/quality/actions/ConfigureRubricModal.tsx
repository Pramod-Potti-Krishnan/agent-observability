"use client";

import React, { useState, useEffect } from 'react';
import { useAuth } from '@/lib/auth-context';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Slider } from '@/components/ui/slider';
import { useToast } from '@/hooks/use-toast';
import { Settings, Check } from 'lucide-react';

interface ConfigureRubricModalProps {
  isOpen: boolean;
  onClose: () => void;
}

interface RubricWeights {
  accuracy: number;
  relevance: number;
  helpfulness: number;
  coherence: number;
}

/**
 * ConfigureRubricModal - Modal for configuring evaluation rubric weights and thresholds
 *
 * Quality Action: Configure Evaluation Rubric (A5.1)
 * - Set criterion weights (accuracy, relevance, helpfulness, coherence)
 * - Configure overall quality threshold
 * - Set per-criterion minimum scores
 * - Weights must sum to 100%
 */
export function ConfigureRubricModal({ isOpen, onClose }: ConfigureRubricModalProps) {
  const { user } = useAuth();
  const { toast } = useToast();

  const [weights, setWeights] = useState<RubricWeights>({
    accuracy: 30,
    relevance: 30,
    helpfulness: 25,
    coherence: 15,
  });

  const [qualityThreshold, setQualityThreshold] = useState<number>(5.0);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Calculate total weight
  const totalWeight = weights.accuracy + weights.relevance + weights.helpfulness + weights.coherence;
  const isWeightValid = Math.abs(totalWeight - 100) < 0.1; // Allow small floating point errors

  // Update weight for a criterion
  const updateWeight = (criterion: keyof RubricWeights, value: number) => {
    setWeights((prev) => ({
      ...prev,
      [criterion]: value,
    }));
  };

  // Auto-balance weights to sum to 100%
  const autoBalanceWeights = () => {
    const remaining = 100 - weights.accuracy;
    const perCriterion = remaining / 3;
    setWeights({
      accuracy: weights.accuracy,
      relevance: perCriterion,
      helpfulness: perCriterion,
      coherence: perCriterion,
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validation
    if (!isWeightValid) {
      toast({
        title: 'Invalid Weights',
        description: `Weights must sum to 100%. Current total: ${totalWeight.toFixed(1)}%`,
        variant: 'destructive',
      });
      return;
    }

    if (qualityThreshold < 0 || qualityThreshold > 10) {
      toast({
        title: 'Invalid Threshold',
        description: 'Quality threshold must be between 0 and 10',
        variant: 'destructive',
      });
      return;
    }

    setIsSubmitting(true);

    // Simulate API call (in real implementation, this would POST to backend)
    await new Promise((resolve) => setTimeout(resolve, 800));

    toast({
      title: 'Rubric Configuration Saved',
      description: `Quality threshold set to ${qualityThreshold.toFixed(1)} with custom criterion weights`,
    });

    setIsSubmitting(false);
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <Settings className="h-5 w-5 text-blue-600" />
            <DialogTitle>Configure Evaluation Rubric</DialogTitle>
          </div>
          <DialogDescription>
            Customize how quality scores are calculated by adjusting criterion weights and thresholds
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit}>
          <div className="grid gap-6 py-4">
            {/* Overall Quality Threshold */}
            <div className="space-y-3 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <Label htmlFor="threshold" className="text-sm font-semibold">
                Overall Quality Threshold
              </Label>
              <div className="flex items-center gap-4">
                <Input
                  id="threshold"
                  type="number"
                  value={qualityThreshold}
                  onChange={(e) => setQualityThreshold(parseFloat(e.target.value) || 0)}
                  min="0"
                  max="10"
                  step="0.1"
                  required
                  className="w-24"
                />
                <span className="text-sm text-muted-foreground flex-1">
                  Agents with scores below this threshold are considered "failing"
                </span>
              </div>
              <div className="text-xs text-blue-700 mt-2">
                Current threshold: Scores below {qualityThreshold.toFixed(1)} will be flagged as failing
              </div>
            </div>

            {/* Criterion Weights */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label className="text-sm font-semibold">Criterion Weights</Label>
                <div className="flex items-center gap-2">
                  <span className={`text-sm font-medium ${isWeightValid ? 'text-green-600' : 'text-red-600'}`}>
                    Total: {totalWeight.toFixed(1)}%
                  </span>
                  {isWeightValid && <Check className="h-4 w-4 text-green-600" />}
                </div>
              </div>
              <p className="text-xs text-muted-foreground">
                Adjust how much each criterion contributes to the overall quality score. Total must equal 100%.
              </p>

              {/* Accuracy Weight */}
              <div className="space-y-2 p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center justify-between">
                  <Label htmlFor="accuracy" className="text-sm">
                    Accuracy
                  </Label>
                  <span className="text-sm font-medium">{weights.accuracy.toFixed(1)}%</span>
                </div>
                <Slider
                  id="accuracy"
                  min={0}
                  max={100}
                  step={1}
                  value={[weights.accuracy]}
                  onValueChange={(values) => updateWeight('accuracy', values[0])}
                  className="w-full"
                />
                <p className="text-xs text-muted-foreground">
                  Measures factual correctness and precision of responses
                </p>
              </div>

              {/* Relevance Weight */}
              <div className="space-y-2 p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center justify-between">
                  <Label htmlFor="relevance" className="text-sm">
                    Relevance
                  </Label>
                  <span className="text-sm font-medium">{weights.relevance.toFixed(1)}%</span>
                </div>
                <Slider
                  id="relevance"
                  min={0}
                  max={100}
                  step={1}
                  value={[weights.relevance]}
                  onValueChange={(values) => updateWeight('relevance', values[0])}
                  className="w-full"
                />
                <p className="text-xs text-muted-foreground">
                  Measures how well responses address the user's query
                </p>
              </div>

              {/* Helpfulness Weight */}
              <div className="space-y-2 p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center justify-between">
                  <Label htmlFor="helpfulness" className="text-sm">
                    Helpfulness
                  </Label>
                  <span className="text-sm font-medium">{weights.helpfulness.toFixed(1)}%</span>
                </div>
                <Slider
                  id="helpfulness"
                  min={0}
                  max={100}
                  step={1}
                  value={[weights.helpfulness]}
                  onValueChange={(values) => updateWeight('helpfulness', values[0])}
                  className="w-full"
                />
                <p className="text-xs text-muted-foreground">
                  Measures usefulness and actionability of responses
                </p>
              </div>

              {/* Coherence Weight */}
              <div className="space-y-2 p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center justify-between">
                  <Label htmlFor="coherence" className="text-sm">
                    Coherence
                  </Label>
                  <span className="text-sm font-medium">{weights.coherence.toFixed(1)}%</span>
                </div>
                <Slider
                  id="coherence"
                  min={0}
                  max={100}
                  step={1}
                  value={[weights.coherence]}
                  onValueChange={(values) => updateWeight('coherence', values[0])}
                  className="w-full"
                />
                <p className="text-xs text-muted-foreground">
                  Measures logical flow and clarity of responses
                </p>
              </div>

              {/* Auto-balance button */}
              {!isWeightValid && (
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={autoBalanceWeights}
                  className="w-full"
                >
                  Auto-Balance Remaining Weights
                </Button>
              )}
            </div>

            {/* Configuration Summary */}
            <div className="rounded-md bg-green-50 border border-green-200 p-3">
              <p className="text-xs font-semibold text-green-900 mb-2">Configuration Summary:</p>
              <div className="space-y-1 text-xs text-green-700">
                <p>• Quality Threshold: {qualityThreshold.toFixed(1)}/10</p>
                <p>• Accuracy: {weights.accuracy.toFixed(1)}%</p>
                <p>• Relevance: {weights.relevance.toFixed(1)}%</p>
                <p>• Helpfulness: {weights.helpfulness.toFixed(1)}%</p>
                <p>• Coherence: {weights.coherence.toFixed(1)}%</p>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={isSubmitting}>
              Cancel
            </Button>
            <Button type="submit" disabled={isSubmitting || !isWeightValid}>
              {isSubmitting ? 'Saving...' : 'Save Configuration'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

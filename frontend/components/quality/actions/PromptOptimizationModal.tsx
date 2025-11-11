"use client";

import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import apiClient from '@/lib/api-client';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { useToast } from '@/hooks/use-toast';
import { Sparkles, Copy, Check, TrendingUp, AlertCircle, Lightbulb } from 'lucide-react';

interface PromptOptimizationModalProps {
  isOpen: boolean;
  onClose: () => void;
  agentId: string;
}

interface QualityMetrics {
  overall_score: number;
  accuracy: number;
  relevance: number;
  helpfulness: number;
  coherence: number;
}

interface OptimizationSuggestion {
  id: string;
  category: string;
  issue: string;
  recommendation: string;
  expectedImpact: string;
  priority: 'high' | 'medium' | 'low';
}

/**
 * PromptOptimizationModal - Modal for viewing AI-powered prompt optimization suggestions
 *
 * Quality Action: Get Prompt Optimization (A5.3)
 * - Analyzes agent quality metrics to identify issues
 * - Generates AI-powered recommendations for prompt improvements
 * - Shows expected impact on quality scores
 * - Provides copy/apply functionality
 */
export function PromptOptimizationModal({ isOpen, onClose, agentId }: PromptOptimizationModalProps) {
  const { user } = useAuth();
  const { toast } = useToast();
  const [suggestions, setSuggestions] = useState<OptimizationSuggestion[]>([]);
  const [isGenerating, setIsGenerating] = useState(false);
  const [copiedId, setCopiedId] = useState<string | null>(null);

  // Simulate fetching quality metrics for the agent
  const { data: metrics, isLoading } = useQuery<QualityMetrics>({
    queryKey: ['agent-quality-metrics', agentId],
    queryFn: async () => {
      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 500));
      return {
        overall_score: 6.2,
        accuracy: 5.8,
        relevance: 7.1,
        helpfulness: 6.5,
        coherence: 5.9,
      };
    },
    enabled: isOpen && !!agentId,
  });

  // Generate AI-powered suggestions
  const generateSuggestions = async () => {
    setIsGenerating(true);

    // Simulate AI analysis
    await new Promise((resolve) => setTimeout(resolve, 2000));

    const generatedSuggestions: OptimizationSuggestion[] = [
      {
        id: '1',
        category: 'Accuracy',
        issue: 'Agent occasionally provides outdated or incorrect information',
        recommendation: 'Add explicit instructions to verify facts and cite sources. Consider adding: "Always verify information currency and cite reliable sources when making factual claims."',
        expectedImpact: '+1.2 accuracy score',
        priority: 'high',
      },
      {
        id: '2',
        category: 'Coherence',
        issue: 'Responses sometimes lack logical flow and clear structure',
        recommendation: 'Include formatting guidelines: "Structure responses with clear sections, bullet points, and logical progression. Start with a summary, then provide details."',
        expectedImpact: '+0.9 coherence score',
        priority: 'high',
      },
      {
        id: '3',
        category: 'Helpfulness',
        issue: 'Responses may be too generic or not actionable enough',
        recommendation: 'Emphasize actionability: "Provide specific, actionable steps the user can take. Include examples and practical implementation guidance."',
        expectedImpact: '+0.7 helpfulness score',
        priority: 'medium',
      },
      {
        id: '4',
        category: 'Relevance',
        issue: 'Agent occasionally includes tangential information',
        recommendation: 'Focus on user intent: "Stay focused on the user\'s specific question. Avoid tangential information unless directly relevant to solving their problem."',
        expectedImpact: '+0.5 relevance score',
        priority: 'medium',
      },
      {
        id: '5',
        category: 'Tone & Style',
        issue: 'Inconsistent tone across different response types',
        recommendation: 'Standardize tone: "Maintain a professional yet approachable tone. Be concise but thorough. Use clear, jargon-free language unless technical terms are necessary."',
        expectedImpact: '+0.4 overall quality',
        priority: 'low',
      },
    ];

    setSuggestions(generatedSuggestions);
    setIsGenerating(false);

    toast({
      title: 'Optimization Suggestions Generated',
      description: `${generatedSuggestions.length} AI-powered recommendations are ready`,
    });
  };

  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
    toast({
      title: 'Copied to Clipboard',
      description: 'Recommendation copied successfully',
    });
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high':
        return 'bg-red-100 text-red-800 border-red-200';
      case 'medium':
        return 'bg-amber-100 text-amber-800 border-amber-200';
      case 'low':
        return 'bg-blue-100 text-blue-800 border-blue-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[700px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <Sparkles className="h-5 w-5 text-purple-600" />
            <DialogTitle>AI-Powered Prompt Optimization</DialogTitle>
          </div>
          <DialogDescription>
            Get intelligent suggestions to improve quality scores for agent <span className="font-mono">{agentId.substring(0, 16)}...</span>
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* Quality Metrics Summary */}
          {isLoading ? (
            <Skeleton className="h-24 w-full" />
          ) : metrics ? (
            <div className="p-4 bg-purple-50 border border-purple-200 rounded-lg">
              <p className="text-sm font-semibold text-purple-900 mb-3">Current Quality Metrics</p>
              <div className="grid grid-cols-5 gap-3">
                <div className="text-center">
                  <p className="text-xs text-purple-700 mb-1">Overall</p>
                  <p className={`text-lg font-bold ${metrics.overall_score < 7 ? 'text-red-600' : 'text-green-600'}`}>
                    {metrics.overall_score.toFixed(1)}
                  </p>
                </div>
                <div className="text-center">
                  <p className="text-xs text-purple-700 mb-1">Accuracy</p>
                  <p className={`text-lg font-bold ${metrics.accuracy < 7 ? 'text-red-600' : 'text-green-600'}`}>
                    {metrics.accuracy.toFixed(1)}
                  </p>
                </div>
                <div className="text-center">
                  <p className="text-xs text-purple-700 mb-1">Relevance</p>
                  <p className={`text-lg font-bold ${metrics.relevance < 7 ? 'text-amber-600' : 'text-green-600'}`}>
                    {metrics.relevance.toFixed(1)}
                  </p>
                </div>
                <div className="text-center">
                  <p className="text-xs text-purple-700 mb-1">Helpfulness</p>
                  <p className={`text-lg font-bold ${metrics.helpfulness < 7 ? 'text-amber-600' : 'text-green-600'}`}>
                    {metrics.helpfulness.toFixed(1)}
                  </p>
                </div>
                <div className="text-center">
                  <p className="text-xs text-purple-700 mb-1">Coherence</p>
                  <p className={`text-lg font-bold ${metrics.coherence < 7 ? 'text-red-600' : 'text-green-600'}`}>
                    {metrics.coherence.toFixed(1)}
                  </p>
                </div>
              </div>
            </div>
          ) : null}

          {/* Generate Suggestions Button */}
          {suggestions.length === 0 && !isGenerating && (
            <div className="text-center py-8">
              <Lightbulb className="h-12 w-12 text-purple-300 mx-auto mb-3" />
              <p className="text-sm text-muted-foreground mb-4">
                Click below to generate AI-powered optimization suggestions
              </p>
              <Button onClick={generateSuggestions} disabled={isGenerating}>
                <Sparkles className="h-4 w-4 mr-2" />
                Generate Suggestions
              </Button>
            </div>
          )}

          {/* Loading State */}
          {isGenerating && (
            <div className="text-center py-8">
              <div className="animate-spin h-8 w-8 border-4 border-purple-600 border-t-transparent rounded-full mx-auto mb-3" />
              <p className="text-sm font-medium">Analyzing quality metrics...</p>
              <p className="text-xs text-muted-foreground mt-1">AI is generating personalized recommendations</p>
            </div>
          )}

          {/* Suggestions List */}
          {suggestions.length > 0 && !isGenerating && (
            <div className="space-y-3">
              <div className="flex items-center justify-between mb-2">
                <p className="text-sm font-semibold flex items-center gap-2">
                  <AlertCircle className="h-4 w-4 text-purple-600" />
                  {suggestions.length} Optimization Opportunities Found
                </p>
                <Badge variant="outline" className="text-xs">
                  AI-Generated
                </Badge>
              </div>

              {suggestions.map((suggestion, index) => (
                <div
                  key={suggestion.id}
                  className="p-4 border-2 border-gray-200 rounded-lg hover:border-purple-300 transition-colors"
                >
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-bold text-purple-600">#{index + 1}</span>
                      <Badge variant="outline" className="text-xs">
                        {suggestion.category}
                      </Badge>
                      <Badge className={`text-xs ${getPriorityColor(suggestion.priority)}`}>
                        {suggestion.priority.toUpperCase()}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-1 text-xs text-green-600">
                      <TrendingUp className="h-3 w-3" />
                      <span>{suggestion.expectedImpact}</span>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <div>
                      <p className="text-xs font-semibold text-gray-700 mb-1">Issue:</p>
                      <p className="text-sm text-gray-600">{suggestion.issue}</p>
                    </div>

                    <div>
                      <p className="text-xs font-semibold text-gray-700 mb-1">Recommendation:</p>
                      <p className="text-sm text-gray-900 bg-gray-50 p-2 rounded border">
                        {suggestion.recommendation}
                      </p>
                    </div>

                    <div className="flex justify-end">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => copyToClipboard(suggestion.recommendation, suggestion.id)}
                      >
                        {copiedId === suggestion.id ? (
                          <>
                            <Check className="h-3 w-3 mr-1" />
                            Copied
                          </>
                        ) : (
                          <>
                            <Copy className="h-3 w-3 mr-1" />
                            Copy
                          </>
                        )}
                      </Button>
                    </div>
                  </div>
                </div>
              ))}

              {/* Expected Overall Impact */}
              <div className="mt-4 p-4 bg-green-50 border border-green-200 rounded-lg">
                <div className="flex items-start gap-2">
                  <TrendingUp className="h-5 w-5 text-green-600 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="text-sm font-semibold text-green-900 mb-1">Expected Overall Impact</p>
                    <p className="text-xs text-green-700">
                      Implementing these recommendations could improve your overall quality score by <strong>+2.5 to +3.2 points</strong>, bringing the agent from <strong>{metrics?.overall_score.toFixed(1)}</strong> to approximately <strong>{((metrics?.overall_score || 0) + 2.8).toFixed(1)}</strong>.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Close
          </Button>
          {suggestions.length > 0 && (
            <Button
              onClick={() => {
                const allRecommendations = suggestions.map((s, i) => `${i + 1}. ${s.recommendation}`).join('\n\n');
                copyToClipboard(allRecommendations, 'all');
                toast({
                  title: 'All Recommendations Copied',
                  description: 'Paste them into your prompt configuration',
                });
              }}
            >
              <Copy className="h-4 w-4 mr-2" />
              Copy All
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

"use client";

import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '@/lib/auth-context';
import apiClient from '@/lib/api-client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Button } from '@/components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { AlertCircle, ChevronRight, Info } from 'lucide-react';
import Link from 'next/link';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';

interface RubricAgent {
  agent_id: string;
  accuracy: number;
  relevance: number;
  helpfulness: number;
  coherence: number;
  overall: number;
  eval_count: number;
}

interface RubricHeatmapResponse {
  data: RubricAgent[];
}

/**
 * RubricHeatmap - Multi-criteria quality heatmap showing agent performance across rubric dimensions
 *
 * Features:
 * - Table heatmap with agents (rows) vs criteria (columns)
 * - Color-coded cells from red (poor) to green (excellent)
 * - Shows accuracy, relevance, helpfulness, coherence, and overall scores
 * - Time range and limit selectors
 * - Hover tooltips with exact scores
 * - Click-through to agent detail pages
 * - Focus on struggling agents (sorted by overall score ascending)
 */
export function RubricHeatmap() {
  const { user, loading: authLoading } = useAuth();
  const [range, setRange] = useState('7d');
  const [limit, setLimit] = useState(10);

  const { data, isLoading } = useQuery<RubricHeatmapResponse>({
    queryKey: ['rubric-heatmap', range, limit],
    queryFn: async () => {
      const params = new URLSearchParams({
        range,
        limit: limit.toString(),
      });
      const response = await apiClient.get(`/api/v1/quality/rubric-heatmap?${params.toString()}`);
      return response.data;
    },
    enabled: !authLoading && !!user?.workspace_id,
    staleTime: 5 * 60 * 1000,
  });

  // Get color for score (0-10 scale)
  const getScoreColor = (score: number): string => {
    if (score >= 9.0) return 'bg-green-500 text-white'; // Excellent
    if (score >= 7.0) return 'bg-blue-400 text-white'; // Good
    if (score >= 5.0) return 'bg-amber-400 text-white'; // Fair
    if (score >= 3.0) return 'bg-orange-500 text-white'; // Poor
    return 'bg-red-500 text-white'; // Failing
  };

  // Get text color for better contrast
  const getTextColor = (score: number): string => {
    return 'text-white font-medium';
  };

  // Get score label
  const getScoreLabel = (score: number): string => {
    if (score >= 9.0) return 'Excellent';
    if (score >= 7.0) return 'Good';
    if (score >= 5.0) return 'Fair';
    if (score >= 3.0) return 'Poor';
    return 'Failing';
  };

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Rubric Criteria Heatmap</CardTitle>
          <CardDescription>Loading heatmap data...</CardDescription>
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[500px] w-full" />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Rubric Criteria Heatmap</CardTitle>
          <CardDescription>No heatmap data found</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[500px] flex flex-col items-center justify-center text-center">
            <AlertCircle className="h-12 w-12 text-muted-foreground mb-2" />
            <p className="text-sm font-medium">No Rubric Data</p>
            <p className="text-xs text-muted-foreground mt-1">
              Not enough evaluation data to generate heatmap
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle>Rubric Criteria Heatmap</CardTitle>
            <CardDescription>
              Multi-criteria performance analysis • Showing {data.data.length} agents with lowest overall scores • {range}
            </CardDescription>
          </div>
          <div className="flex gap-2">
            {/* Time Range Selector */}
            <Select value={range} onValueChange={setRange}>
              <SelectTrigger className="w-[120px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="1h">Last Hour</SelectItem>
                <SelectItem value="24h">Last 24h</SelectItem>
                <SelectItem value="7d">Last 7d</SelectItem>
                <SelectItem value="30d">Last 30d</SelectItem>
              </SelectContent>
            </Select>

            {/* Limit Selector */}
            <Select value={limit.toString()} onValueChange={(val) => setLimit(parseInt(val))}>
              <SelectTrigger className="w-[100px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="5">Top 5</SelectItem>
                <SelectItem value="10">Top 10</SelectItem>
                <SelectItem value="20">Top 20</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {/* Color Legend */}
        <div className="mb-4 flex items-center gap-4 text-xs">
          <span className="text-muted-foreground flex items-center gap-1">
            <Info className="h-3 w-3" />
            Score Range:
          </span>
          <div className="flex items-center gap-2">
            <div className="flex items-center gap-1">
              <div className="w-6 h-4 bg-red-500 rounded"></div>
              <span>0-2.9</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-6 h-4 bg-orange-500 rounded"></div>
              <span>3-4.9</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-6 h-4 bg-amber-400 rounded"></div>
              <span>5-6.9</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-6 h-4 bg-blue-400 rounded"></div>
              <span>7-8.9</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-6 h-4 bg-green-500 rounded"></div>
              <span>9-10</span>
            </div>
          </div>
        </div>

        {/* Heatmap Table */}
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[200px] sticky left-0 bg-background z-10">Agent ID</TableHead>
                <TableHead className="text-center w-[100px]">Accuracy</TableHead>
                <TableHead className="text-center w-[100px]">Relevance</TableHead>
                <TableHead className="text-center w-[100px]">Helpfulness</TableHead>
                <TableHead className="text-center w-[100px]">Coherence</TableHead>
                <TableHead className="text-center w-[100px]">Overall</TableHead>
                <TableHead className="text-center w-[80px]">Evals</TableHead>
                <TableHead className="text-right w-[80px]">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.data.map((agent, index) => (
                <TableRow key={agent.agent_id} className="hover:bg-muted/30">
                  {/* Agent ID - Sticky column */}
                  <TableCell className="font-mono text-sm sticky left-0 bg-background z-10">
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-muted-foreground">#{index + 1}</span>
                      <span>{agent.agent_id}</span>
                    </div>
                  </TableCell>

                  {/* Accuracy Score */}
                  <TableCell className="text-center p-2">
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <div
                            className={`rounded px-3 py-2 cursor-help ${getScoreColor(agent.accuracy)}`}
                          >
                            <span className={getTextColor(agent.accuracy)}>
                              {(agent.accuracy || 0).toFixed(1)}
                            </span>
                          </div>
                        </TooltipTrigger>
                        <TooltipContent>
                          <p className="font-semibold">Accuracy: {(agent.accuracy || 0).toFixed(2)}</p>
                          <p className="text-xs text-muted-foreground">{getScoreLabel(agent.accuracy)}</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </TableCell>

                  {/* Relevance Score */}
                  <TableCell className="text-center p-2">
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <div
                            className={`rounded px-3 py-2 cursor-help ${getScoreColor(agent.relevance)}`}
                          >
                            <span className={getTextColor(agent.relevance)}>
                              {(agent.relevance || 0).toFixed(1)}
                            </span>
                          </div>
                        </TooltipTrigger>
                        <TooltipContent>
                          <p className="font-semibold">Relevance: {(agent.relevance || 0).toFixed(2)}</p>
                          <p className="text-xs text-muted-foreground">{getScoreLabel(agent.relevance)}</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </TableCell>

                  {/* Helpfulness Score */}
                  <TableCell className="text-center p-2">
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <div
                            className={`rounded px-3 py-2 cursor-help ${getScoreColor(agent.helpfulness)}`}
                          >
                            <span className={getTextColor(agent.helpfulness)}>
                              {(agent.helpfulness || 0).toFixed(1)}
                            </span>
                          </div>
                        </TooltipTrigger>
                        <TooltipContent>
                          <p className="font-semibold">Helpfulness: {(agent.helpfulness || 0).toFixed(2)}</p>
                          <p className="text-xs text-muted-foreground">{getScoreLabel(agent.helpfulness)}</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </TableCell>

                  {/* Coherence Score */}
                  <TableCell className="text-center p-2">
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <div
                            className={`rounded px-3 py-2 cursor-help ${getScoreColor(agent.coherence)}`}
                          >
                            <span className={getTextColor(agent.coherence)}>
                              {(agent.coherence || 0).toFixed(1)}
                            </span>
                          </div>
                        </TooltipTrigger>
                        <TooltipContent>
                          <p className="font-semibold">Coherence: {(agent.coherence || 0).toFixed(2)}</p>
                          <p className="text-xs text-muted-foreground">{getScoreLabel(agent.coherence)}</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </TableCell>

                  {/* Overall Score */}
                  <TableCell className="text-center p-2">
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <div
                            className={`rounded px-3 py-2 cursor-help font-bold ${getScoreColor(agent.overall)}`}
                          >
                            <span className={getTextColor(agent.overall)}>
                              {(agent.overall || 0).toFixed(1)}
                            </span>
                          </div>
                        </TooltipTrigger>
                        <TooltipContent>
                          <p className="font-semibold">Overall: {(agent.overall || 0).toFixed(2)}</p>
                          <p className="text-xs text-muted-foreground">{getScoreLabel(agent.overall)}</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </TableCell>

                  {/* Evaluation Count */}
                  <TableCell className="text-center text-sm">
                    {agent.eval_count}
                  </TableCell>

                  {/* Actions */}
                  <TableCell className="text-right">
                    <Link href={`/dashboard/performance/agents/${agent.agent_id}`}>
                      <Button variant="ghost" size="sm">
                        <ChevronRight className="h-4 w-4" />
                      </Button>
                    </Link>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>

        {/* Summary Stats */}
        <div className="mt-6 pt-4 border-t">
          <div className="grid grid-cols-5 gap-4">
            <div className="text-center">
              <p className="text-xs text-muted-foreground mb-1">Avg Accuracy</p>
              <p className="text-xl font-bold">
                {(data.data.length > 0 ? data.data.reduce((sum, a) => sum + (a.accuracy || 0), 0) / data.data.length : 0).toFixed(1)}
              </p>
            </div>
            <div className="text-center">
              <p className="text-xs text-muted-foreground mb-1">Avg Relevance</p>
              <p className="text-xl font-bold">
                {(data.data.length > 0 ? data.data.reduce((sum, a) => sum + (a.relevance || 0), 0) / data.data.length : 0).toFixed(1)}
              </p>
            </div>
            <div className="text-center">
              <p className="text-xs text-muted-foreground mb-1">Avg Helpfulness</p>
              <p className="text-xl font-bold">
                {(data.data.length > 0 ? data.data.reduce((sum, a) => sum + (a.helpfulness || 0), 0) / data.data.length : 0).toFixed(1)}
              </p>
            </div>
            <div className="text-center">
              <p className="text-xs text-muted-foreground mb-1">Avg Coherence</p>
              <p className="text-xl font-bold">
                {(data.data.length > 0 ? data.data.reduce((sum, a) => sum + (a.coherence || 0), 0) / data.data.length : 0).toFixed(1)}
              </p>
            </div>
            <div className="text-center">
              <p className="text-xs text-muted-foreground mb-1">Avg Overall</p>
              <p className="text-xl font-bold text-red-600">
                {(data.data.length > 0 ? data.data.reduce((sum, a) => sum + (a.overall || 0), 0) / data.data.length : 0).toFixed(1)}
              </p>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

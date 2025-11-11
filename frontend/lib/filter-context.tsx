"use client";

import React, { createContext, useContext, useState, useEffect, useCallback, Suspense } from 'react';
import { useRouter, useSearchParams, usePathname } from 'next/navigation';

/**
 * Filter configuration for multi-dimensional filtering across the platform.
 * These filters apply globally to all metrics, charts, and data views.
 */
export interface FilterConfig {
  /** Time range: 1h, 24h, 7d, 30d */
  range: string;
  /** Department code (e.g., 'engineering', 'sales') */
  department: string | null;
  /** Environment code (e.g., 'production', 'staging', 'development') */
  environment: string | null;
  /** Version string (e.g., 'v2.1', 'v2.0') */
  version: string | null;
  /** Specific agent ID */
  agent_id: string | null;
}

/**
 * Filter context value with state and setters
 */
interface FilterContextValue {
  filters: FilterConfig;
  setFilters: (filters: Partial<FilterConfig>) => void;
  resetFilters: () => void;
  isFiltered: boolean;
}

const DEFAULT_FILTERS: FilterConfig = {
  range: '30d',
  department: null,
  environment: null,
  version: null,
  agent_id: null,
};

const STORAGE_KEY = 'agent-monitoring-filters';

const FilterContext = createContext<FilterContextValue | undefined>(undefined);

/**
 * Internal FilterProvider that uses useSearchParams
 */
function FilterProviderInternal({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  // Initialize state from URL params or localStorage
  const [filters, setFiltersState] = useState<FilterConfig>(() => {
    // Priority: URL params > localStorage > defaults

    // Try URL params first
    if (searchParams) {
      const urlFilters: Partial<FilterConfig> = {
        range: searchParams.get('range') || undefined,
        department: searchParams.get('department') || undefined,
        environment: searchParams.get('environment') || undefined,
        version: searchParams.get('version') || undefined,
        agent_id: searchParams.get('agent_id') || undefined,
      };

      // Remove undefined values
      Object.keys(urlFilters).forEach(key => {
        if (urlFilters[key as keyof FilterConfig] === undefined) {
          delete urlFilters[key as keyof FilterConfig];
        }
      });

      // MIGRATION: Auto-upgrade old 24h default to 30d from URL params
      if (urlFilters.range === '24h') {
        urlFilters.range = '30d';
      }

      if (Object.keys(urlFilters).length > 0) {
        return { ...DEFAULT_FILTERS, ...urlFilters };
      }
    }

    // Try localStorage next (client-side only)
    if (typeof window !== 'undefined') {
      try {
        const stored = localStorage.getItem(STORAGE_KEY);
        if (stored) {
          const parsed = JSON.parse(stored);

          // MIGRATION: Auto-upgrade old 24h default to 30d
          // This handles the data staleness issue where traces are 4-28 days old
          if (parsed.range === '24h') {
            parsed.range = '30d';
            console.log('[Filter Migration] Upgraded time range from 24h to 30d');
          }

          return { ...DEFAULT_FILTERS, ...parsed };
        }
      } catch (e) {
        console.warn('Failed to parse stored filters:', e);
      }
    }

    // Fall back to defaults
    return DEFAULT_FILTERS;
  });

  // Sync to URL params whenever filters change
  useEffect(() => {
    if (!pathname) return;

    const params = new URLSearchParams();

    // Always include range
    params.set('range', filters.range);

    // Include other filters if set
    if (filters.department) params.set('department', filters.department);
    if (filters.environment) params.set('environment', filters.environment);
    if (filters.version) params.set('version', filters.version);
    if (filters.agent_id) params.set('agent_id', filters.agent_id);

    const newUrl = `${pathname}?${params.toString()}`;

    // Only update URL if it changed (avoid infinite loops)
    if (window.location.search !== `?${params.toString()}`) {
      router.push(newUrl, { scroll: false });
    }
  }, [filters, pathname, router]);

  // Sync to localStorage whenever filters change
  useEffect(() => {
    if (typeof window !== 'undefined') {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(filters));
      } catch (e) {
        console.warn('Failed to store filters:', e);
      }
    }
  }, [filters]);

  // Update filters (merge with existing)
  const setFilters = useCallback((newFilters: Partial<FilterConfig>) => {
    setFiltersState(prev => ({ ...prev, ...newFilters }));
  }, []);

  // Reset all filters to defaults
  const resetFilters = useCallback(() => {
    setFiltersState(DEFAULT_FILTERS);
  }, []);

  // Check if any filters are active (besides default range)
  const isFiltered = filters.department !== null ||
                     filters.environment !== null ||
                     filters.version !== null ||
                     filters.agent_id !== null ||
                     filters.range !== '30d';

  const value: FilterContextValue = {
    filters,
    setFilters,
    resetFilters,
    isFiltered,
  };

  return (
    <FilterContext.Provider value={value}>
      {children}
    </FilterContext.Provider>
  );
}

/**
 * FilterProvider component wrapped with Suspense boundary
 * This wrapper is necessary because useSearchParams requires a Suspense boundary
 */
export function FilterProvider({ children }: { children: React.ReactNode }) {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <FilterProviderInternal>{children}</FilterProviderInternal>
    </Suspense>
  );
}

/**
 * Hook to access filter context
 * @throws Error if used outside FilterProvider
 */
export function useFilters(): FilterContextValue {
  const context = useContext(FilterContext);
  if (!context) {
    throw new Error('useFilters must be used within a FilterProvider');
  }
  return context;
}

/**
 * Build query string for API calls based on current filters
 */
export function useFilterQueryString(): string {
  const { filters } = useFilters();

  const params = new URLSearchParams();
  params.set('range', filters.range);

  if (filters.department) params.set('department', filters.department);
  if (filters.environment) params.set('environment', filters.environment);
  if (filters.version) params.set('version', filters.version);
  if (filters.agent_id) params.set('agent_id', filters.agent_id);

  return params.toString();
}

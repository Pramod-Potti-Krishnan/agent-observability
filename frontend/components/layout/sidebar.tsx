'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  Home,
  BarChart3,
  DollarSign,
  Zap,
  Award,
  Shield,
  TrendingUp,
  Menu,
} from 'lucide-react'

const navigation = [
  { name: 'Home', href: '/dashboard', icon: Home },
  { name: 'Usage', href: '/dashboard/usage', icon: BarChart3 },
  { name: 'Cost', href: '/dashboard/cost', icon: DollarSign },
  { name: 'Performance', href: '/dashboard/performance', icon: Zap },
  { name: 'Quality', href: '/dashboard/quality', icon: Award },
  { name: 'Safety', href: '/dashboard/safety', icon: Shield },
  { name: 'Impact', href: '/dashboard/impact', icon: TrendingUp },
]

interface SidebarProps {
  isOpen: boolean
  onToggle: () => void
}

export function Sidebar({ isOpen, onToggle }: SidebarProps) {
  const pathname = usePathname()
  const [isHovered, setIsHovered] = useState(false)

  // Sidebar is expanded when: explicitly open OR hovered (when collapsed)
  const isExpanded = isOpen || isHovered

  return (
    <div
      className={cn(
        'relative flex h-full flex-col border-r bg-card transition-all duration-300 ease-in-out',
        isExpanded ? 'w-64' : 'w-16'
      )}
      onMouseEnter={() => !isOpen && setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      {/* Hamburger Menu Button at Top */}
      <div className={cn(
        'flex items-center border-b h-16 transition-all',
        isExpanded ? 'px-3' : 'px-0 justify-center'
      )}>
        <Button
          variant="ghost"
          size="icon"
          onClick={onToggle}
          className="flex-shrink-0"
          title={isOpen ? "Collapse sidebar" : "Expand sidebar"}
        >
          <Menu className="h-6 w-6" />
        </Button>
      </div>

      {/* Navigation */}
      <nav className="flex-1 space-y-1 p-2 pt-4">
        {navigation.map((item) => {
          const isActive = pathname === item.href
          const Icon = item.icon

          return (
            <Link key={item.name} href={item.href}>
              <Button
                variant={isActive ? 'secondary' : 'ghost'}
                className={cn(
                  'w-full transition-all duration-200',
                  isExpanded ? 'justify-start px-3' : 'justify-center px-0',
                  isActive && 'bg-secondary'
                )}
                title={!isExpanded ? item.name : undefined}
              >
                <Icon className={cn('h-5 w-5 flex-shrink-0', isExpanded && 'mr-3')} />
                {isExpanded && <span className="whitespace-nowrap">{item.name}</span>}
              </Button>
            </Link>
          )
        })}
      </nav>

      {/* Workspace Info */}
      {isExpanded && (
        <div className="border-t p-4">
          <div className="rounded-lg bg-muted p-3">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium">Development Workspace</span>
              <Badge variant="secondary">Pro</Badge>
            </div>
            <p className="text-xs text-muted-foreground">
              API calls: 1,234 / 10,000
            </p>
          </div>
        </div>
      )}

      {/* Collapsed indicator */}
      {!isExpanded && (
        <div className="border-t p-2">
          <div className="flex items-center justify-center">
            <div className="h-2 w-2 rounded-full bg-green-500" title="Development Workspace" />
          </div>
        </div>
      )}
    </div>
  )
}

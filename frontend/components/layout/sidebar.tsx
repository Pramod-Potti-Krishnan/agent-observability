'use client'

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
  Settings,
} from 'lucide-react'

const navigation = [
  { name: 'Home', href: '/dashboard', icon: Home },
  { name: 'Usage', href: '/dashboard/usage', icon: BarChart3 },
  { name: 'Cost', href: '/dashboard/cost', icon: DollarSign },
  { name: 'Performance', href: '/dashboard/performance', icon: Zap },
  { name: 'Quality', href: '/dashboard/quality', icon: Award },
  { name: 'Safety', href: '/dashboard/safety', icon: Shield },
  { name: 'Impact', href: '/dashboard/impact', icon: TrendingUp },
  { name: 'Settings', href: '/dashboard/settings', icon: Settings },
]

export function Sidebar() {
  const pathname = usePathname()

  return (
    <div className="flex h-full w-64 flex-col border-r bg-card">
      {/* Logo */}
      <div className="flex h-16 items-center border-b px-6">
        <h1 className="text-xl font-bold">Agent Observability</h1>
      </div>

      {/* Navigation */}
      <nav className="flex-1 space-y-1 p-4">
        {navigation.map((item) => {
          const isActive = pathname === item.href
          const Icon = item.icon

          return (
            <Link key={item.name} href={item.href}>
              <Button
                variant={isActive ? 'secondary' : 'ghost'}
                className={cn(
                  'w-full justify-start',
                  isActive && 'bg-secondary'
                )}
              >
                <Icon className="mr-3 h-5 w-5" />
                {item.name}
              </Button>
            </Link>
          )
        })}
      </nav>

      {/* Workspace Info */}
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
    </div>
  )
}

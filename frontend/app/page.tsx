import Link from 'next/link'
import { Button } from '@/components/ui/button'

export const dynamic = 'force-dynamic'

export default function HomePage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="text-center space-y-6">
        <div>
          <h1 className="text-4xl font-bold mb-4">Agent Observability Platform</h1>
          <p className="text-muted-foreground mb-8">
            AI Agent and LLM Observability Solution
          </p>
        </div>

        <div className="flex gap-4 justify-center">
          <Link href="/dashboard">
            <Button size="lg">
              Go to Dashboard
            </Button>
          </Link>
          <Link href="/dashboard/settings">
            <Button size="lg" variant="outline">
              Settings
            </Button>
          </Link>
        </div>

        <div className="mt-8 text-sm text-muted-foreground">
          <p>Phase 0: Foundation & Infrastructure</p>
          <p className="mt-2">10,000 traces loaded • Ready for development</p>
        </div>
      </div>
    </div>
  )
}

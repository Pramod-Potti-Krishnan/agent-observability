import { NextRequest } from 'next/server'

export const dynamic = 'force-dynamic'

function getBackendBaseUrl(): string {
  const base =
    process.env.API_URL ||
    process.env.BACKEND_URL ||
    process.env.GATEWAY_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    'http://localhost:8000'

  return base.replace(/\/$/, '')
}

function buildTargetUrl(req: NextRequest): string {
  const base = getBackendBaseUrl()
  const pathname = req.nextUrl.pathname
  const search = req.nextUrl.search || ''
  return `${base}${pathname}${search}`
}

async function proxy(req: NextRequest) {
  const targetUrl = buildTargetUrl(req)

  const headers = new Headers()
  req.headers.forEach((value, key) => {
    const lowerKey = key.toLowerCase()
    if (lowerKey === 'host' || lowerKey === 'content-length') {
      return
    }
    headers.set(key, value)
  })

  const authorization = req.headers.get('authorization')
  if (authorization) {
    headers.set('authorization', authorization)
  }

  headers.delete('host')
  headers.delete('content-length')

  const init: RequestInit = {
    method: req.method,
    headers,
    redirect: 'manual',
  }

  if (req.method !== 'GET' && req.method !== 'HEAD') {
    init.body = await req.arrayBuffer()
  }

  let upstream: Response
  try {
    upstream = await fetch(targetUrl, init)
  } catch {
    return Response.json(
      { error: 'Gateway unreachable' },
      { status: 503 }
    )
  }

  const responseHeaders = new Headers(upstream.headers)
  responseHeaders.delete('content-encoding')
  responseHeaders.delete('transfer-encoding')

  return new Response(upstream.body, {
    status: upstream.status,
    statusText: upstream.statusText,
    headers: responseHeaders,
  })
}

export async function GET(req: NextRequest) {
  return proxy(req)
}

export async function POST(req: NextRequest) {
  return proxy(req)
}

export async function PUT(req: NextRequest) {
  return proxy(req)
}

export async function PATCH(req: NextRequest) {
  return proxy(req)
}

export async function DELETE(req: NextRequest) {
  return proxy(req)
}

export async function OPTIONS(req: NextRequest) {
  return proxy(req)
}

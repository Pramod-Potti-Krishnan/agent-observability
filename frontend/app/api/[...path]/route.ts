import { NextRequest, NextResponse } from 'next/server'

const GATEWAY_URL = process.env.GATEWAY_URL || 'http://gateway:8000'

export async function GET(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  return proxyRequest(request, params.path)
}

export async function POST(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  return proxyRequest(request, params.path)
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  return proxyRequest(request, params.path)
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  return proxyRequest(request, params.path)
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  return proxyRequest(request, params.path)
}

async function proxyRequest(request: NextRequest, pathSegments: string[]) {
  const path = pathSegments.join('/')
  const search = request.nextUrl.search
  const url = `${GATEWAY_URL}/api/${path}${search}`

  // Forward headers (exclude host)
  const headers = new Headers()
  request.headers.forEach((value, key) => {
    if (key.toLowerCase() !== 'host') {
      headers.set(key, value)
    }
  })

  try {
    // Get request body for non-GET/HEAD requests
    const body = request.method !== 'GET' && request.method !== 'HEAD'
      ? await request.text()
      : undefined

    // Forward request to gateway
    const response = await fetch(url, {
      method: request.method,
      headers,
      body,
    })

    // Get response data
    const data = await response.text()

    // Return proxied response
    return new NextResponse(data, {
      status: response.status,
      headers: response.headers,
    })
  } catch (error) {
    console.error('Proxy error:', error)
    return NextResponse.json(
      { error: 'Gateway unreachable' },
      { status: 503 }
    )
  }
}

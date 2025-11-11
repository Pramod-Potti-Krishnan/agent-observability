"""Proxy routes to forward requests to backend services"""
import httpx
from fastapi import APIRouter, Request, Response, HTTPException
from fastapi.responses import StreamingResponse
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

# Service URLs
QUERY_SERVICE_URL = "http://query:8003"
INGESTION_SERVICE_URL = "http://ingestion:8001"

# Phase 4 Service URLs
EVALUATION_SERVICE_URL = "http://evaluation:8004"
GUARDRAIL_SERVICE_URL = "http://guardrail:8005"
ALERT_SERVICE_URL = "http://alert:8006"
GEMINI_SERVICE_URL = "http://gemini:8007"


async def proxy_request(
    request: Request,
    target_url: str,
) -> Response:
    """
    Proxy a request to a backend service

    Args:
        request: Incoming request
        target_url: Target service URL

    Returns:
        Response from the backend service
    """
    # Build target URL
    path = request.url.path
    query_params = str(request.url.query)
    if query_params:
        full_url = f"{target_url}{path}?{query_params}"
    else:
        full_url = f"{target_url}{path}"

    # Get request body
    body = await request.body()

    # Forward headers (excluding host)
    headers = dict(request.headers)
    headers.pop("host", None)

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Forward the request
            response = await client.request(
                method=request.method,
                url=full_url,
                headers=headers,
                content=body,
            )

            # Return the response
            return Response(
                content=response.content,
                status_code=response.status_code,
                headers=dict(response.headers),
            )

    except httpx.RequestError as e:
        logger.error(f"Proxy request failed: {e}")
        raise HTTPException(
            status_code=503,
            detail=f"Service unavailable: {str(e)}"
        )


# Query Service Proxy Routes
@router.api_route(
    "/api/v1/metrics/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"]
)
async def proxy_metrics(request: Request, path: str):
    """Proxy metrics requests to query service"""
    return await proxy_request(request, QUERY_SERVICE_URL)


@router.api_route(
    "/api/v1/usage/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"]
)
async def proxy_usage(request: Request, path: str):
    """Proxy usage analytics requests to query service"""
    return await proxy_request(request, QUERY_SERVICE_URL)


@router.api_route(
    "/api/v1/cost/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"]
)
async def proxy_cost(request: Request, path: str):
    """Proxy cost management requests to query service"""
    return await proxy_request(request, QUERY_SERVICE_URL)


@router.api_route(
    "/api/v1/performance/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"]
)
async def proxy_performance(request: Request, path: str):
    """Proxy performance monitoring requests to query service"""
    return await proxy_request(request, QUERY_SERVICE_URL)


@router.api_route(
    "/api/v1/filters/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"]
)
async def proxy_filters(request: Request, path: str):
    """Proxy filter requests to query service"""
    return await proxy_request(request, QUERY_SERVICE_URL)


@router.api_route(
    "/api/v1/analytics/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"]
)
async def proxy_analytics(request: Request, path: str):
    """Proxy analytics requests to query service"""
    return await proxy_request(request, QUERY_SERVICE_URL)


@router.api_route(
    "/api/v1/activity/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"]
)
async def proxy_activity(request: Request, path: str):
    """Proxy activity stream requests to query service"""
    return await proxy_request(request, QUERY_SERVICE_URL)


@router.api_route(
    "/api/v1/quality/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"]
)
async def proxy_quality(request: Request, path: str):
    """Proxy quality monitoring requests to query service"""
    return await proxy_request(request, QUERY_SERVICE_URL)


@router.api_route(
    "/api/v1/impact/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"]
)
async def proxy_impact(request: Request, path: str):
    """Proxy business impact requests to query service"""
    return await proxy_request(request, QUERY_SERVICE_URL)


# Ingestion Service Proxy Routes
@router.api_route(
    "/api/v1/traces/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"]
)
async def proxy_traces(request: Request, path: str):
    """Proxy trace ingestion requests to ingestion service"""
    return await proxy_request(request, INGESTION_SERVICE_URL)


# Phase 4 Routes - Evaluation Service
@router.api_route("/api/v1/evaluate/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_evaluate(request: Request, path: str):
    """
    Proxy requests to Evaluation Service (Phase 4).
    Handles trace evaluations, criteria management, and evaluation history.
    """
    return await proxy_request(request, EVALUATION_SERVICE_URL)


# Phase 4 Routes - Guardrail Service
@router.api_route("/api/v1/guardrails/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_guardrails(request: Request, path: str):
    """
    Proxy requests to Guardrail Service (Phase 4).
    Handles PII detection, toxicity checking, and violation tracking.
    """
    return await proxy_request(request, GUARDRAIL_SERVICE_URL)


# Phase 4 Routes - Alert Service (Alerts)
@router.api_route("/api/v1/alerts/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_alerts(request: Request, path: str):
    """
    Proxy requests to Alert Service (Phase 4) - Alerts endpoint.
    Handles alert notifications, acknowledgments, and resolutions.
    """
    return await proxy_request(request, ALERT_SERVICE_URL)


# Phase 4 Routes - Alert Service (Alert Rules)
@router.api_route("/api/v1/alert-rules/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_alert_rules(request: Request, path: str):
    """
    Proxy requests to Alert Service (Phase 4) - Alert Rules endpoint.
    Handles alert rule creation, updates, and management.
    """
    return await proxy_request(request, ALERT_SERVICE_URL)


# Phase 4 Routes - Gemini Service (Insights)
@router.api_route("/api/v1/insights/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_insights(request: Request, path: str):
    """
    Proxy requests to Gemini Service (Phase 4) - Insights endpoint.
    Handles AI-powered cost optimization, error diagnosis, and feedback analysis.
    """
    return await proxy_request(request, GEMINI_SERVICE_URL)


# Phase 4 Routes - Gemini Service (Business Goals)
@router.api_route("/api/v1/business-goals/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def proxy_business_goals(request: Request, path: str):
    """
    Proxy requests to Gemini Service (Phase 4) - Business Goals endpoint.
    Handles business goal tracking, ROI calculations, and impact metrics.
    """
    return await proxy_request(request, GEMINI_SERVICE_URL)

from fastapi import FastAPI, HTTPException, Query

from .database import get_conn
from .schemas import CaseItem, HealthResponse, SearchResponse

app = FastAPI(title="AI_SYS API", version="0.1.0")


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(status="ok")


@app.get("/cases/{case_number}", response_model=CaseItem)
def get_case(case_number: str) -> CaseItem:
    sql = """
        SELECT
            id::text,
            case_number,
            case_name,
            court_name,
            decision_date,
            subject,
            issue_summary,
            holding_summary,
            exam_points,
            source_url,
            updated_at
        FROM published_cases
        WHERE case_number = %(case_number)s
        LIMIT 1
    """
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, {"case_number": case_number})
            row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Case not found or not published")

    return CaseItem(
        id=row[0],
        case_number=row[1],
        case_name=row[2],
        court_name=row[3],
        decision_date=row[4],
        subject=row[5],
        issue_summary=row[6],
        holding_summary=row[7],
        exam_points=row[8],
        source_url=row[9],
        updated_at=row[10],
    )


@app.get("/search", response_model=SearchResponse)
def search_cases(
    q: str = Query(..., min_length=1, description="사건번호 또는 키워드"),
    limit: int = Query(10, ge=1, le=50),
) -> SearchResponse:
    sql = """
        SELECT
            c.id::text,
            c.case_number,
            c.case_name,
            c.court_name,
            c.decision_date,
            c.subject,
            c.issue_summary,
            c.holding_summary,
            c.exam_points,
            c.source_url,
            c.updated_at
        FROM cases c
        LEFT JOIN case_keywords k ON c.id = k.case_id
        WHERE c.status = 'published'
          AND (
              c.case_number ILIKE %(q_like)s
              OR c.case_name ILIKE %(q_like)s
              OR c.issue_summary ILIKE %(q_like)s
              OR k.keyword ILIKE %(q_like)s
          )
        GROUP BY
            c.id,
            c.case_number,
            c.case_name,
            c.court_name,
            c.decision_date,
            c.subject,
            c.issue_summary,
            c.holding_summary,
            c.exam_points,
            c.source_url,
            c.updated_at
        ORDER BY c.updated_at DESC
        LIMIT %(limit)s
    """

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, {"q_like": f"%{q}%", "limit": limit})
            rows = cur.fetchall()

    items = [
        CaseItem(
            id=row[0],
            case_number=row[1],
            case_name=row[2],
            court_name=row[3],
            decision_date=row[4],
            subject=row[5],
            issue_summary=row[6],
            holding_summary=row[7],
            exam_points=row[8],
            source_url=row[9],
            updated_at=row[10],
        )
        for row in rows
    ]
    return SearchResponse(total=len(items), items=items)

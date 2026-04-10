from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel


class CaseItem(BaseModel):
    id: str
    case_number: str
    case_name: str
    court_name: str
    decision_date: Optional[date] = None
    subject: str
    issue_summary: Optional[str] = None
    holding_summary: Optional[str] = None
    exam_points: Optional[str] = None
    source_url: Optional[str] = None
    updated_at: datetime


class HealthResponse(BaseModel):
    status: str


class SearchResponse(BaseModel):
    total: int
    items: list[CaseItem]

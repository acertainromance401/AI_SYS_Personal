from datetime import date, datetime
from typing import Literal, Optional

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


class SearchEvidence(BaseModel):
    rank: int
    case_number: str
    case_name: str
    snippet: str
    matched_fields: list[str]
    relevance_score: float
    source_url: Optional[str] = None


class SearchResponseV2(BaseModel):
    query: str
    normalized_query: str
    total: int
    items: list[CaseItem]
    evidence: list[SearchEvidence]
    generated_at: datetime


class Citation(BaseModel):
    case_number: str
    case_name: str
    quoted_text: str
    reason: str


class GroundedAnswerRequest(BaseModel):
    question: str
    intent: Literal["summary", "compare", "qa", "quiz"]
    top_k: int = 3


class GroundedAnswerResponse(BaseModel):
    question: str
    answer: str
    citations: list[Citation]
    safety_flags: list[str]
    generated_at: datetime

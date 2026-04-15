from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class HallucinationRule:
    key: str
    description: str


HALLUCINATION_RULES: tuple[HallucinationRule, ...] = (
    HallucinationRule(
        key="must_have_citation",
        description="Every legal claim must map to at least one citation case_number.",
    ),
    HallucinationRule(
        key="citation_must_exist_in_retrieval",
        description="All cited case_number values must be present in retrieved evidence.",
    ),
    HallucinationRule(
        key="no_unsupported_numeric_facts",
        description="Do not include unsupported dates, article numbers, or percentages.",
    ),
    HallucinationRule(
        key="uncertainty_on_missing_evidence",
        description="When evidence is insufficient, output an explicit uncertainty statement.",
    ),
    HallucinationRule(
        key="quote_must_match_snippet",
        description="Quoted text should be a direct or near-direct match to evidence snippet.",
    ),
)


def validate_grounded_answer(
    answer_text: str,
    cited_case_numbers: list[str],
    retrieved_case_numbers: set[str],
) -> list[str]:
    """Return violated rule keys for lightweight server-side checks."""

    violations: list[str] = []

    if not cited_case_numbers:
        violations.append("must_have_citation")

    if cited_case_numbers and not set(cited_case_numbers).issubset(retrieved_case_numbers):
        violations.append("citation_must_exist_in_retrieval")

    if "unknown" in answer_text.lower() and "insufficient" not in answer_text.lower():
        violations.append("uncertainty_on_missing_evidence")

    return violations

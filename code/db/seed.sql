-- AI_SYS PostgreSQL seed data (v1.0)
-- Run after db/schema.sql

BEGIN;

WITH inserted_cases AS (
    INSERT INTO cases (
        case_number,
        case_name,
        court_name,
        decision_date,
        case_type,
        subject,
        raw_text,
        issue_summary,
        holding_summary,
        exam_points,
        source_url,
        source_name,
        status
    ) VALUES
    (
        '2019도12345',
        '위법수집증거 관련 판결',
        '대법원',
        '2019-10-10',
        '형사',
        '형사소송법',
        '압수수색 절차 위반으로 확보된 증거의 증거능력 판단에 관한 판결문 원문 예시',
        '위법수집증거의 증거능력 인정 범위',
        '절차 위반의 중대성에 따라 증거능력을 제한',
        '위법수집증거 배제법칙의 적용 요건 정리',
        'https://example.org/case/2019do12345',
        '공식사이트',
        'published'
    ),
    (
        '2020도56789',
        '정당방위 범위 판결',
        '대법원',
        '2020-07-22',
        '형사',
        '형법',
        '현재의 부당한 침해에 대응하는 정당방위 요건 판단에 관한 판결문 원문 예시',
        '정당방위 상당성 판단 기준',
        '방위행위의 상당성이 인정되는 범위를 제시',
        '침해의 급박성/상당성/필요성 비교 포인트',
        'https://example.org/case/2020do56789',
        '파일데이터',
        'reviewed'
    ),
    (
        '2018도11111',
        '현행범 체포 적법성 판결',
        '대법원',
        '2018-03-15',
        '형사',
        '경찰학',
        '현행범 체포 요건 충족 여부 및 절차 위반의 효과에 관한 판결문 원문 예시',
        '현행범 체포의 요건과 한계',
        '현행범 해당성 판단 시점과 절차 준수 강조',
        '현행범 요건 체크리스트 기반으로 암기',
        'https://example.org/case/2018do11111',
        '공식사이트',
        'collected'
    )
    ON CONFLICT (case_number) DO NOTHING
    RETURNING id, case_number
),
selected_cases AS (
    SELECT id, case_number FROM inserted_cases
    UNION
    SELECT id, case_number
    FROM cases
    WHERE case_number IN ('2019도12345', '2020도56789', '2018도11111')
),
insert_chunks AS (
    INSERT INTO case_chunks (case_id, chunk_index, chunk_text, token_count)
    SELECT id, 0, '쟁점 개요: 핵심 법리 및 사실관계 요약', 18
    FROM selected_cases
    ON CONFLICT (case_id, chunk_index) DO NOTHING
    RETURNING case_id
),
insert_keywords AS (
    INSERT INTO case_keywords (case_id, keyword, weight, source)
    SELECT id, '위법수집증거', 10.00, 'manual'
    FROM selected_cases WHERE case_number = '2019도12345'
    ON CONFLICT (case_id, keyword) DO NOTHING
    RETURNING case_id
),
insert_keywords_2 AS (
    INSERT INTO case_keywords (case_id, keyword, weight, source)
    SELECT id, '정당방위', 10.00, 'manual'
    FROM selected_cases WHERE case_number = '2020도56789'
    ON CONFLICT (case_id, keyword) DO NOTHING
    RETURNING case_id
),
insert_keywords_3 AS (
    INSERT INTO case_keywords (case_id, keyword, weight, source)
    SELECT id, '현행범 체포', 9.50, 'manual'
    FROM selected_cases WHERE case_number = '2018도11111'
    ON CONFLICT (case_id, keyword) DO NOTHING
    RETURNING case_id
),
insert_rel AS (
    INSERT INTO case_relations (case_id, related_case_id, relation, reason)
    SELECT c1.id, c2.id, 'related', '수사절차 적법성 관련 공통 쟁점'
    FROM selected_cases c1
    JOIN selected_cases c2 ON c1.case_number = '2019도12345' AND c2.case_number = '2018도11111'
    ON CONFLICT (case_id, related_case_id, relation) DO NOTHING
    RETURNING case_id
)
INSERT INTO user_case_history (user_id, case_id, action_type, is_wrong_answer, solved_at, review_due_at, note)
SELECT
    'demo-user',
    sc.id,
    'review',
    TRUE,
    NOW() - INTERVAL '1 day',
    NOW() + INTERVAL '3 days',
    '초기 시드: 오답 복습 큐'
FROM selected_cases sc
WHERE sc.case_number = '2019도12345'
ON CONFLICT DO NOTHING;

COMMIT;

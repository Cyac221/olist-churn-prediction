--Customer Understanding - RFM
-- R = Recency, F = Frenquency, M = Monetary

-- Reference date: one day after last record in dataset (2018-10-16)

-- =============================================
-- RFM completo: Etapas 1, 2 y 3 — v2
-- Autor: Carlos Jose Yepes Aristizábal
-- Fecha de referencia: 2018-10-17
-- =============================================

WITH rfm_base AS (

    -- Etapa 1: métricas brutas por cliente
    SELECT
        c.customer_unique_id,
        '2018-10-17'::DATE - MAX(o.order_purchase_timestamp)::DATE  AS recency_days,
        COUNT(DISTINCT o.order_id)                                   AS frequency,
        ROUND(SUM(oi.price)::NUMERIC, 2)                            AS monetary_value,
        ROUND(AVG(r.review_score)::NUMERIC, 2)                      AS avg_review_score

    FROM olist_orders AS o
    JOIN olist_customers AS c    ON o.customer_id  = c.customer_id
    JOIN olist_order_items AS oi ON o.order_id     = oi.order_id
    LEFT JOIN olist_order_reviews AS r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id

),

rfm_scores AS (

    -- Etapa 2: convertir métricas en scores
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary_value,
        avg_review_score,

        6 - NTILE(5) OVER (ORDER BY recency_days ASC)               AS r_score,

        CASE
            WHEN frequency = 1             THEN 0
            WHEN frequency BETWEEN 2 AND 3 THEN 1
            WHEN frequency BETWEEN 4 AND 6 THEN 2
            WHEN frequency > 6             THEN 3
        END                                                          AS f_score,

        NTILE(5) OVER (ORDER BY monetary_value ASC)                 AS m_score,

        NTILE(5) OVER (
            ORDER BY avg_review_score ASC NULLS FIRST
        )                                                            AS experience_score

    FROM rfm_base

),

rfm_segmented AS (

    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary_value,
        avg_review_score,
        r_score,
        f_score,
        m_score,
        experience_score,
        r_score + f_score + m_score + experience_score              AS rfm_total,

        CASE
            -- Champions: recientes, recurrentes, alto gasto
            WHEN r_score >= 4 AND f_score >= 1 AND m_score >= 4
                THEN 'Champions'

            -- Loyal: recurrentes con buen gasto, algo menos recientes
            WHEN f_score >= 1 AND m_score >= 3 AND r_score >= 3
                THEN 'Loyal'

            -- Cannot lose: altísimo valor, llevan mucho sin comprar
            WHEN r_score <= 2 AND m_score = 5
                THEN 'Cannot lose'

            -- At risk: buen gasto histórico, se están alejando
            WHEN r_score <= 2 AND m_score >= 4
                THEN 'At risk'

            -- Lost: los más inactivos y de menor valor
            -- Va ANTES de Hibernating porque sus condiciones se solapan
            WHEN r_score = 1 AND m_score = 1
                THEN 'Lost'

            -- Hibernating: inactivos con poco valor histórico
            WHEN r_score <= 2 AND m_score <= 2
                THEN 'Hibernating'

            -- Promising: recientes pero aún poco gasto
            WHEN r_score >= 4 AND m_score BETWEEN 2 AND 3
                THEN 'Promising'

            -- New customer: primera compra muy reciente, gasto mínimo
            WHEN r_score >= 4 AND f_score = 0 AND m_score = 1
                THEN 'New customer'

            -- About to sleep: recencia media cayendo, poco gasto
            WHEN r_score = 3 AND m_score <= 2
                THEN 'About to sleep'

            -- Potential loyalist: recientes con buena experiencia,
            -- aún no recurrentes
            WHEN r_score >= 3 AND f_score = 0
              AND experience_score >= 4 AND m_score BETWEEN 2 AND 4
                THEN 'Potential loyalist'

            -- Price sensitive: recencia media, gasto bajo pero compran
            WHEN r_score BETWEEN 2 AND 3
              AND m_score <= 2 AND f_score >= 1
                THEN 'Price sensitive'

            -- Todo lo que no encaja
            ELSE 'Need attention'
        END                                                          AS segment

    FROM rfm_scores

)

-- Distribución final por segmento
SELECT
    segment,
    COUNT(*)                                                         AS total_clients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)              AS percentage,
    ROUND(AVG(recency_days), 0)                                      AS avg_recency_days,
    ROUND(AVG(monetary_value), 2)                                    AS avg_monetary,
    ROUND(AVG(avg_review_score), 2)                                  AS avg_review,
    ROUND(AVG(r_score), 2)                                           AS avg_r,
    ROUND(AVG(m_score), 2)                                           AS avg_m
FROM rfm_segmented
GROUP BY segment
ORDER BY total_clients DESC;

--Save in a view
CREATE VIEW rfm_final AS
WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        '2018-10-17'::DATE - MAX(o.order_purchase_timestamp)::DATE  AS recency_days,
        COUNT(DISTINCT o.order_id)                                   AS frequency,
        ROUND(SUM(oi.price)::NUMERIC, 2)                            AS monetary_value,
        ROUND(AVG(r.review_score)::NUMERIC, 2)                      AS avg_review_score
    FROM olist_orders AS o
    JOIN olist_customers AS c    ON o.customer_id  = c.customer_id
    JOIN olist_order_items AS oi ON o.order_id     = oi.order_id
    LEFT JOIN olist_order_reviews AS r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary_value,
        avg_review_score,
        6 - NTILE(5) OVER (ORDER BY recency_days ASC)               AS r_score,
        CASE
            WHEN frequency = 1             THEN 0
            WHEN frequency BETWEEN 2 AND 3 THEN 1
            WHEN frequency BETWEEN 4 AND 6 THEN 2
            WHEN frequency > 6             THEN 3
        END                                                          AS f_score,
        NTILE(5) OVER (ORDER BY monetary_value ASC)                 AS m_score,
        NTILE(5) OVER (
            ORDER BY avg_review_score ASC NULLS FIRST
        )                                                            AS experience_score
    FROM rfm_base
)
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary_value,
    avg_review_score,
    r_score,
    f_score,
    m_score,
    experience_score,
    r_score + f_score + m_score + experience_score                  AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 1 AND m_score >= 4        THEN 'Champions'
        WHEN f_score >= 1 AND m_score >= 3 AND r_score >= 3        THEN 'Loyal'
        WHEN r_score <= 2 AND m_score = 5                          THEN 'Cannot lose'
        WHEN r_score <= 2 AND m_score >= 4                         THEN 'At risk'
        WHEN r_score = 1  AND m_score = 1                          THEN 'Lost'
        WHEN r_score <= 2 AND m_score <= 2                         THEN 'Hibernating'
        WHEN r_score >= 4 AND m_score BETWEEN 2 AND 3              THEN 'Promising'
        WHEN r_score >= 4 AND f_score = 0 AND m_score = 1          THEN 'New customer'
        WHEN r_score = 3  AND m_score <= 2                         THEN 'About to sleep'
        WHEN r_score >= 3 AND f_score = 0
         AND experience_score >= 4 AND m_score BETWEEN 2 AND 4     THEN 'Potential loyalist'
        WHEN r_score BETWEEN 2 AND 3
         AND m_score <= 2 AND f_score >= 1                         THEN 'Price sensitive'
        ELSE 'Need attention'
    END                                                             AS segment
FROM rfm_scores;

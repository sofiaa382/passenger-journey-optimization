WITH global_baseline AS (
    -- Compute the absolute baseline across the entire dataset once
    SELECT AVG(liked) * 100 AS global_avg_pct 
    FROM `airline_analytics.view_normalized_passenger_journey`
),

grouped_metrics AS (
    -- Group and collapse passenger cohorts
    SELECT 
        passenger_process_type,
        CASE 
            WHEN arrival_lead_time_hours < 1.0 THEN 'Tight Window (<1hr)'
            WHEN arrival_lead_time_hours BETWEEN 1.0 AND 2.5 THEN 'Standard Window (1-2.5hr)'
            WHEN arrival_lead_time_hours BETWEEN 2.5 AND 4.0 THEN 'High Dwell Window (2.5-4hr)'
            ELSE 'Extreme Wait (>4hr)'
        END AS terminal_dwell_profile,
        COUNT(*) AS customer_volume,
        ROUND(AVG(ground_processing_index), 2) AS ground_processing_performance,
        ROUND(AVG(norm_fb_price_value), 2) AS food_concession_price_rating,
        ROUND(AVG(liked) * 100, 2) AS passenger_satisfaction_rate_pct
    FROM `airline_analytics.view_normalized_passenger_journey`
    -- Restrict exclusively to outbound departing profiles with valid time entries
    WHERE LOWER(TRIM(passenger_process_type)) = 'boarding' 
      AND arrival_lead_time_hours IS NOT NULL 
      AND arrival_lead_time_hours > 0
    GROUP BY 1, 2
)

-- Calculate the exact delta variance
SELECT 
    g.*,
    ROUND(g.passenger_satisfaction_rate_pct - b.global_avg_pct, 2) AS variance_from_global_average
FROM grouped_metrics g
CROSS JOIN global_baseline b
ORDER BY g.passenger_process_type, g.terminal_dwell_profile;
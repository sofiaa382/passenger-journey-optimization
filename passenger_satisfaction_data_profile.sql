-- checking general dataset overview
SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN liked IS NULL THEN 1 ELSE 0 END) AS null_target_count,
    ROUND(AVG(liked) * 100, 2) AS baseline_satisfaction_pct,
    
    MIN(checkin_process) AS min_survey_value,
    MAX(checkin_process) AS max_survey_value,
    COUNTIF(checkin_process IS NULL) AS missing_checkin_responses
FROM airline_analytics.passenger_survey_balanced;

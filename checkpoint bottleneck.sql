SELECT 
    CASE 
        WHEN sovereign_checkpoint_index >= 75 THEN 'Green Zone: High Efficiency'
        WHEN sovereign_checkpoint_index BETWEEN 45 AND 74.99 THEN 'Warning Zone: Moderate Delay'
        ELSE 'Critical Red Zone: Systemic Bottlenecks'
    END AS checkpoint_experience_tier,
    COUNT(*) AS total_passengers_impacted,
    ROUND(AVG(terminal_comfort_index), 2) AS perceived_terminal_comfort,
    ROUND(AVG(liked) * 100, 2) AS passenger_satisfaction_rate_pct
FROM `airline_analytics.view_normalized_passenger_journey`
GROUP BY 1
ORDER BY 1;
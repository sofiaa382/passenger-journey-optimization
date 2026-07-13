CREATE OR REPLACE VIEW airline_analytics.view_normalized_passenger_journey AS
WITH normalized_survey AS (
    SELECT 
        -- Structural Metadata
        process AS passenger_process_type,
        month,
        flight_type,
        connection,
        trip_purpose,
        liked,
        
        -- Time Metric Conversions
        ROUND(SAFE_DIVIDE(arrival_lead_time, 3600.0), 2) AS arrival_lead_time_hours,
        ROUND(SAFE_DIVIDE(connection_wait_time, 3600.0), 2) AS connection_wait_time_hours,

        -- MECE Domain 1: Access & Ground Processing
        IF(checkin_process_is_applicable = 1, ROUND(SAFE_DIVIDE(checkin_process - 1, 4.0) * 100, 2), NULL) AS norm_checkin_process,
        IF(checkin_queue_wait_time_is_applicable = 1, ROUND(SAFE_DIVIDE(checkin_queue_wait_time - 1, 4.0) * 100, 2), NULL) AS norm_checkin_wait,
        IF(checkin_queue_organization_is_applicable = 1, ROUND(SAFE_DIVIDE(checkin_queue_organization - 1, 4.0) * 100, 2), NULL) AS norm_checkin_org,
        IF(curbside_dropoff_ease_is_applicable = 1, ROUND(SAFE_DIVIDE(curbside_dropoff_ease - 1, 4.0) * 100, 2), NULL) AS norm_curbside_dropoff,
        IF(ticket_purchase_process_is_applicable = 1, ROUND(SAFE_DIVIDE(ticket_purchase_process - 1, 4.0) * 100, 2), NULL) AS norm_ticket_purchase,
        
        -- MECE Domain 2: Sovereign Checkpoints
        IF(security_screening_process_is_applicable = 1, ROUND(SAFE_DIVIDE(security_screening_process - 1, 4.0) * 100, 2), NULL) AS norm_security_process,
        IF(security_queue_wait_time_is_applicable = 1, ROUND(SAFE_DIVIDE(security_queue_wait_time - 1, 4.0) * 100, 2), NULL) AS norm_security_wait,
        IF(immigration_queue_wait_time_is_applicable = 1, ROUND(SAFE_DIVIDE(immigration_queue_wait_time - 1, 4.0) * 100, 2), NULL) AS norm_immigration_wait,
        IF(customs_control_is_applicable = 1, ROUND(SAFE_DIVIDE(customs_control - 1, 4.0) * 100, 2), NULL) AS norm_customs_control,

        -- MECE Domain 3: Terminal Facilities & Ambience
        IF(boarding_lounge_comfort_is_applicable = 1, ROUND(SAFE_DIVIDE(boarding_lounge_comfort - 1, 4.0) * 100, 2), NULL) AS norm_lounge_comfort,
        ROUND(SAFE_DIVIDE(overall_airport_cleanliness - 1, 4.0) * 100, 2) AS norm_airport_cleanliness,
        IF(restroom_cleanliness_is_applicable = 1, ROUND(SAFE_DIVIDE(restroom_cleanliness - 1, 4.0) * 100, 2), NULL) AS norm_restroom_cleanliness,
        IF(airport_internet_is_applicable = 1, ROUND(SAFE_DIVIDE(airport_internet - 1, 4.0) * 100, 2), NULL) AS norm_internet,
        IF(signage_is_applicable = 1, ROUND(SAFE_DIVIDE(signage - 1, 4.0) * 100, 2), NULL) AS norm_signage,
        
        -- MECE Domain 4: Commercial & Concessions
        IF(food_beverage_price_quality_is_applicable = 1, ROUND(SAFE_DIVIDE(food_beverage_price_quality - 1, 4.0) * 100, 2), NULL) AS norm_fb_price_value,
        IF(retail_price_quality_is_applicable = 1, ROUND(SAFE_DIVIDE(retail_price_quality - 1, 4.0) * 100, 2), NULL) AS norm_retail_price_value,

        -- MECE Domain 5: Arrival & Post-Flight
        IF(disembarkation_method_rating_is_applicable = 1, ROUND(SAFE_DIVIDE(disembarkation_method_rating - 1, 4.0) * 100, 2), NULL) AS norm_disembarkation,
        IF(baggage_claim_process_is_applicable = 1, ROUND(SAFE_DIVIDE(baggage_claim_process - 1, 4.0) * 100, 2), NULL) AS norm_baggage_process,
        IF(baggage_claim_time_is_applicable = 1, ROUND(SAFE_DIVIDE(baggage_claim_time - 1, 4.0) * 100, 2), NULL) AS norm_baggage_time
    FROM airline_analytics.passenger_survey_balanced
),

cross_domain_cleaning AS (
    SELECT 
        * EXCEPT(
            norm_checkin_process, norm_checkin_wait, norm_checkin_org, norm_ticket_purchase,
            norm_immigration_wait, norm_customs_control,
            norm_lounge_comfort, norm_internet,
            norm_disembarkation, norm_baggage_process, norm_baggage_time,
            connection_wait_time_hours
        ),
        
        -- Masking transit fields if connection status matches exact string representation
        IF(LOWER(TRIM(connection)) = 'not applicable', NULL, connection_wait_time_hours) AS connection_wait_time_hours,

        -- Rule Group A: If Arriving, mask departure steps completely
        IF(LOWER(TRIM(passenger_process_type)) = 'disembarkation', NULL, norm_checkin_process) AS norm_checkin_process,
        IF(LOWER(TRIM(passenger_process_type)) = 'disembarkation', NULL, norm_checkin_wait) AS norm_checkin_wait,
        IF(LOWER(TRIM(passenger_process_type)) = 'disembarkation', NULL, norm_checkin_org) AS norm_checkin_org,
        IF(LOWER(TRIM(passenger_process_type)) = 'disembarkation', NULL, norm_ticket_purchase) AS norm_ticket_purchase,
        IF(LOWER(TRIM(passenger_process_type)) = 'disembarkation', NULL, norm_lounge_comfort) AS norm_lounge_comfort,
        IF(LOWER(TRIM(passenger_process_type)) = 'disembarkation', NULL, norm_internet) AS norm_internet,
        
        -- Rule Group B: If Departing, mask post-flight arrival items completely
        IF(LOWER(TRIM(passenger_process_type)) = 'boarding', NULL, norm_disembarkation) AS norm_disembarkation,
        IF(LOWER(TRIM(passenger_process_type)) = 'boarding', NULL, norm_baggage_process) AS norm_baggage_process,
        IF(LOWER(TRIM(passenger_process_type)) = 'boarding', NULL, norm_baggage_time) AS norm_baggage_time,
        
        -- Rule Group C: If Domestic, clear border control metrics completely
        IF(LOWER(TRIM(flight_type)) = 'domestic', NULL, norm_immigration_wait) AS norm_immigration_wait,
        IF(LOWER(TRIM(flight_type)) = 'domestic', NULL, norm_customs_control) AS norm_customs_control
    FROM normalized_survey
),

mece_domain_aggregation AS (
    SELECT 
        *,
        -- Generate dynamic composite indices that scale cleanly across remaining non-null metrics
        ROUND(
            (SAFE_ADD(SAFE_ADD(norm_checkin_process, norm_checkin_wait), norm_checkin_org)) / 
            (IF(norm_checkin_process IS NULL, 0, 1) + IF(norm_checkin_wait IS NULL, 0, 1) + IF(norm_checkin_org IS NULL, 0, 1)), 
            2
        ) AS ground_processing_index,
        
        ROUND(
            (SAFE_ADD(SAFE_ADD(norm_security_process, norm_security_wait), norm_immigration_wait)) / 
            (IF(norm_security_process IS NULL, 0, 1) + IF(norm_security_wait IS NULL, 0, 1) + IF(norm_immigration_wait IS NULL, 0, 1)), 
            2
        ) AS sovereign_checkpoint_index,
        
        ROUND(
            (SAFE_ADD(SAFE_ADD(norm_airport_cleanliness, norm_restroom_cleanliness), norm_lounge_comfort)) / 
            (IF(norm_airport_cleanliness IS NULL, 0, 1) + IF(norm_restroom_cleanliness IS NULL, 0, 1) + IF(norm_lounge_comfort IS NULL, 0, 1)), 
            2
        ) AS terminal_comfort_index
    FROM cross_domain_cleaning
)

SELECT * FROM mece_domain_aggregation;

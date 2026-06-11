CREATE OR REFRESH MATERIALIZED VIEW bronze_bookings
COMMENT "Bookings from samples.wanderbricks, lightly renamed for the tutorial."
AS
SELECT
  booking_id,
  user_id,
  property_id,
  check_in,
  check_out,
  guests_count,
  CAST(total_amount AS DOUBLE) AS total_amount,
  status,
  created_at,
  updated_at
FROM samples.wanderbricks.bookings;

CREATE OR REFRESH MATERIALIZED VIEW bronze_payments
COMMENT "Payments from samples.wanderbricks."
AS
SELECT
  payment_id,
  booking_id,
  CAST(amount AS DOUBLE) AS amount,
  payment_method,
  status,
  payment_date
FROM samples.wanderbricks.payments;

CREATE OR REFRESH MATERIALIZED VIEW bronze_reviews
COMMENT "Non-deleted Wanderbricks reviews with property context."
AS
SELECT
  r.review_id,
  r.booking_id,
  r.property_id,
  r.user_id,
  CAST(r.rating AS DOUBLE) AS rating,
  r.comment,
  r.created_at,
  r.updated_at,
  p.title AS property_title,
  p.property_type,
  d.destination,
  d.country
FROM samples.wanderbricks.reviews r
JOIN samples.wanderbricks.properties p
  ON r.property_id = p.property_id
JOIN samples.wanderbricks.destinations d
  ON p.destination_id = d.destination_id
WHERE r.is_deleted = false OR r.is_deleted IS NULL;

CREATE OR REFRESH MATERIALIZED VIEW bronze_support_messages
COMMENT "Support conversation messages exploded to one row per message."
AS
SELECT
  s.ticket_id,
  s.user_id,
  s.support_agent_id,
  to_timestamp(s.created_at) AS ticket_created_at,
  message_position,
  message.sender AS sender,
  message.sentiment AS sentiment,
  message.message AS message_text,
  to_timestamp(message.timestamp) AS created_at
FROM samples.wanderbricks.customer_support_logs s
LATERAL VIEW posexplode(s.messages) exploded AS message_position, message;

CREATE OR REFRESH MATERIALIZED VIEW silver_booking_revenue
COMMENT "Booking revenue with destination and payment context."
AS
WITH payment_rollup AS (
  SELECT
    booking_id,
    SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) AS paid_amount,
    SUM(CASE WHEN status = 'refunded' THEN amount ELSE 0 END) AS refunded_amount,
    COUNT(*) AS payment_events
  FROM bronze_payments
  GROUP BY booking_id
)
SELECT
  b.booking_id,
  b.user_id,
  b.property_id,
  p.title AS property_title,
  p.property_type,
  d.destination,
  d.country,
  b.check_in,
  b.check_out,
  b.guests_count,
  b.status AS booking_status,
  b.total_amount,
  CASE
    WHEN b.status IN ('confirmed', 'completed') THEN b.total_amount
    ELSE 0
  END AS gross_booking_value,
  COALESCE(pr.paid_amount, 0) AS paid_amount,
  COALESCE(pr.refunded_amount, 0) AS refunded_amount,
  COALESCE(pr.payment_events, 0) AS payment_events,
  b.created_at,
  b.updated_at
FROM bronze_bookings b
JOIN samples.wanderbricks.properties p
  ON b.property_id = p.property_id
JOIN samples.wanderbricks.destinations d
  ON p.destination_id = d.destination_id
LEFT JOIN payment_rollup pr
  ON b.booking_id = pr.booking_id;

CREATE OR REFRESH MATERIALIZED VIEW gold_destination_revenue
COMMENT "Destination-level revenue and booking health for Genie and dashboards."
AS
SELECT
  destination,
  country,
  COUNT(*) AS booking_count,
  SUM(CASE WHEN booking_status = 'completed' THEN 1 ELSE 0 END) AS completed_booking_count,
  SUM(gross_booking_value) AS gross_booking_value,
  SUM(paid_amount) AS paid_amount,
  SUM(refunded_amount) AS refunded_amount,
  CASE
    WHEN COUNT(*) = 0 THEN 0
    ELSE SUM(gross_booking_value) / COUNT(*)
  END AS average_booking_value,
  MIN(check_in) AS first_check_in,
  MAX(check_out) AS last_check_out
FROM silver_booking_revenue
GROUP BY destination, country;

CREATE OR REFRESH MATERIALIZED VIEW gold_property_quality
COMMENT "Property-level quality and value signals for guest recovery decisions."
AS
WITH booking_rollup AS (
  SELECT
    property_id,
    COUNT(*) AS booking_count,
    SUM(CASE WHEN booking_status = 'completed' THEN 1 ELSE 0 END) AS completed_booking_count,
    SUM(gross_booking_value) AS gross_booking_value,
    SUM(paid_amount) AS paid_amount,
    MAX(destination) AS destination,
    MAX(country) AS country,
    MAX(property_title) AS property_title,
    MAX(property_type) AS property_type
  FROM silver_booking_revenue
  GROUP BY property_id
),
review_rollup AS (
  SELECT
    property_id,
    COUNT(*) AS review_count,
    AVG(rating) AS average_rating,
    SUM(CASE WHEN rating < 3.0 THEN 1 ELSE 0 END) AS low_rating_count
  FROM bronze_reviews
  GROUP BY property_id
)
SELECT
  p.property_id,
  COALESCE(br.property_title, p.title) AS property_title,
  COALESCE(br.property_type, p.property_type) AS property_type,
  d.destination,
  d.country,
  COALESCE(br.booking_count, 0) AS booking_count,
  COALESCE(br.completed_booking_count, 0) AS completed_booking_count,
  COALESCE(br.gross_booking_value, 0) AS gross_booking_value,
  COALESCE(br.paid_amount, 0) AS paid_amount,
  COALESCE(rr.review_count, 0) AS review_count,
  COALESCE(rr.average_rating, 0) AS average_rating,
  COALESCE(rr.low_rating_count, 0) AS low_rating_count,
  CASE
    WHEN COALESCE(rr.review_count, 0) >= 5 AND COALESCE(rr.average_rating, 0) < 3.5 THEN 'review'
    WHEN COALESCE(br.gross_booking_value, 0) >= 10000 AND COALESCE(rr.review_count, 0) < 5 THEN 'watch'
    ELSE 'stable'
  END AS guest_recovery_signal
FROM samples.wanderbricks.properties p
JOIN samples.wanderbricks.destinations d
  ON p.destination_id = d.destination_id
LEFT JOIN booking_rollup br
  ON p.property_id = br.property_id
LEFT JOIN review_rollup rr
  ON p.property_id = rr.property_id;


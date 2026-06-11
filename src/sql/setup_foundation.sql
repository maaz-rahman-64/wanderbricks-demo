USE CATALOG IDENTIFIER(:catalog);
USE SCHEMA IDENTIFIER(:schema);

CREATE OR REPLACE TABLE serving_property_quality AS
SELECT
  property_id,
  property_title,
  property_type,
  destination,
  country,
  booking_count,
  completed_booking_count,
  gross_booking_value,
  paid_amount,
  review_count,
  average_rating,
  low_rating_count,
  guest_recovery_signal
FROM gold_property_quality;

CREATE OR REPLACE TABLE support_review_corpus
TBLPROPERTIES ("delta.enableChangeDataFeed" = "true")
AS
SELECT
  CONCAT('review:', CAST(review_id AS STRING)) AS doc_id,
  'review' AS doc_type,
  property_id,
  destination,
  user_id,
  rating,
  CAST(NULL AS STRING) AS ticket_id,
  CONCAT(
    'Review for ', property_title, ' in ', destination,
    '. Rating: ', CAST(rating AS STRING), ' stars. ',
    comment
  ) AS text,
  created_at
FROM bronze_reviews
WHERE comment IS NOT NULL

UNION ALL

SELECT
  CONCAT('support:', ticket_id, ':', CAST(message_position AS STRING)) AS doc_id,
  'support' AS doc_type,
  CAST(NULL AS BIGINT) AS property_id,
  CAST(NULL AS STRING) AS destination,
  user_id,
  CAST(NULL AS DOUBLE) AS rating,
  ticket_id,
  CONCAT(
    'Support ticket ', ticket_id,
    '. Sender: ', sender,
    '. Sentiment: ', COALESCE(sentiment, 'unknown'),
    '. Message: ', message_text
  ) AS text,
  created_at
FROM bronze_support_messages
WHERE message_text IS NOT NULL;

CREATE OR REPLACE VIEW wanderbricks_destination_metrics
WITH METRICS
LANGUAGE YAML
AS
$$
version: 1.1
comment: "Destination-level Wanderbricks booking value, payment, and volume metrics for business Q&A."
source: gold_destination_revenue

dimensions:
  - name: Destination
    display_name: Destination
    expr: destination
    comment: "City or travel market where the booking happened."
    synonyms: ["city", "market", "travel market"]

  - name: Country
    display_name: Country
    expr: country
    comment: "Country for the destination."
    synonyms: ["nation", "region"]

measures:
  - name: Gross Booking Value
    display_name: Gross Booking Value
    expr: SUM(gross_booking_value)
    comment: "Total value of confirmed and completed bookings before refunds."
    synonyms: ["revenue", "booking value", "gross value"]

  - name: Paid Amount
    display_name: Paid Amount
    expr: SUM(paid_amount)
    comment: "Total amount successfully collected through completed payments."
    synonyms: ["collected amount", "payments collected"]

  - name: Refunded Amount
    display_name: Refunded Amount
    expr: SUM(refunded_amount)
    comment: "Total amount refunded to guests."
    synonyms: ["refunds", "refunded value"]

  - name: Booking Count
    display_name: Booking Count
    expr: SUM(booking_count)
    comment: "Number of booking records."
    synonyms: ["bookings", "booking volume", "trips"]

  - name: Completed Booking Count
    display_name: Completed Booking Count
    expr: SUM(completed_booking_count)
    comment: "Number of bookings with completed status."
    synonyms: ["completed bookings", "completed trips"]

  - name: Average Booking Value
    display_name: Average Booking Value
    expr: SUM(gross_booking_value) / NULLIF(SUM(booking_count), 0)
    comment: "Average confirmed or completed booking value."
    synonyms: ["average revenue", "average trip value"]
$$;

CREATE OR REPLACE VIEW wanderbricks_property_quality_metrics
WITH METRICS
LANGUAGE YAML
AS
$$
version: 1.1
comment: "Property-level guest quality and value metrics for recovery workflows."
source: gold_property_quality

dimensions:
  - name: Property
    display_name: Property
    expr: property_title
    comment: "Guest-facing property title."
    synonyms: ["listing", "rental", "stay"]

  - name: Property Type
    display_name: Property Type
    expr: property_type
    comment: "Type of property, such as apartment, hotel, or villa."
    synonyms: ["listing type", "accommodation type"]

  - name: Destination
    display_name: Destination
    expr: destination
    comment: "City or travel market where the property is listed."
    synonyms: ["city", "market", "travel market"]

  - name: Guest Recovery Signal
    display_name: Guest Recovery Signal
    expr: guest_recovery_signal
    comment: "Simple action band: review, watch, or stable."
    synonyms: ["risk signal", "action band", "recovery status"]

measures:
  - name: Gross Booking Value
    display_name: Gross Booking Value
    expr: SUM(gross_booking_value)
    comment: "Total value of confirmed and completed bookings for the property."
    synonyms: ["revenue", "booking value", "gross value"]

  - name: Booking Count
    display_name: Booking Count
    expr: SUM(booking_count)
    comment: "Number of bookings for the property."
    synonyms: ["bookings", "booking volume", "trips"]

  - name: Review Count
    display_name: Review Count
    expr: SUM(review_count)
    comment: "Number of non-deleted guest reviews."
    synonyms: ["reviews", "guest reviews"]

  - name: Average Rating
    display_name: Average Rating
    expr: SUM(average_rating * review_count) / NULLIF(SUM(review_count), 0)
    comment: "Review-count weighted average guest rating."
    synonyms: ["rating", "guest score", "satisfaction score"]

  - name: Low Rating Count
    display_name: Low Rating Count
    expr: SUM(low_rating_count)
    comment: "Number of reviews below three stars."
    synonyms: ["bad reviews", "low reviews", "unhappy reviews"]
$$;

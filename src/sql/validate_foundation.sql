USE CATALOG IDENTIFIER(:catalog);
USE SCHEMA IDENTIFIER(:schema);

SELECT 'gold_destination_revenue' AS object_name, COUNT(*) AS row_count
FROM gold_destination_revenue
UNION ALL
SELECT 'gold_property_quality', COUNT(*)
FROM gold_property_quality
UNION ALL
SELECT 'support_review_corpus', COUNT(*)
FROM support_review_corpus
UNION ALL
SELECT 'serving_property_quality', COUNT(*)
FROM serving_property_quality;

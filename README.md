# Wanderbricks Databricks Platform Tutorial

This tutorial is for someone who is new to Databricks, is not trying to become a SQL expert today, and wants to understand how the platform pieces fit together by clicking through the workspace.

You will use the built-in `samples.wanderbricks` dataset. Wanderbricks is a simulated vacation rental marketplace with destinations, properties, bookings, payments, reviews, support conversations, and clickstream activity.

The tutorial is split into two parts:

1. A **Declarative Automation Bundle**, also called a DAB, deploys data engineering foundations.
2. You use the Databricks UI to inspect the data foundations click through the remaining pieces by hand.

## What You Will Build

You will build an agent chatbot app with short-term memory, end-to-end, on Databricks.

## Prerequisites

You will need to set up an Express workspace, as described here under "Try Databricks": https://www.databricks.com/try-databricks

Use these values throughout the tutorial:


| Placeholder          | Meaning                               | Example                                     |
| -------------------- | ------------------------------------- | ------------------------------------------- |
| `<catalog>`          | Writable Unity Catalog catalog        | `demo_<your name>`                                      |
| `<schema>`           | Tutorial schema created by the bundle | `wanderbricks_tutorial`                     |
| `<warehouse>`        | DAB-created serverless SQL warehouse  | `Wanderbricks Tutorial Warehouse - wanderbricks_tutorial` |
| `<app_name>`         | Databricks App name                   | `wanderbricks-agent-chat`                   |
| `<genie_space>`      | Genie Space name                      | `Wanderbricks Revenue and Guest Experience` |
| `<agent_name>`       | Supervisor Agent name                 | `wanderbricks-guest-recovery-supervisor`    |
| `<lakebase_project>` | Lakebase Autoscaling project          | `wanderbricks-ops`                          |

# 1. Setup

The bundle creates a series of foundational assets, which will be discussed as we go. This facilitates native CI/CD of all assets across environments, ensuring SDLC best practices are adopted as data and AI assets evolve.

### Deploy From The Workspace UI

1. In the left sidebar, click **Workspace**.
2. Click **Create** -> **Git Folder**.
3. Open the Git folder for this repository.
4. Confirm the branch shown at the top is `main`.
5. Click **Open in Editor**.
6. Click the rocketship icon to open the deployment pane.
7. Review the bundle resources and variables. Pay particular attention to the **catalog** (it starts with `demo_`)
8. **Deploy** the resources
9. Once deployed, hover over the Job  **Wanderbricks tutorial setup - `<schema>`**, and click the play button to run the job.
10. Wait for the job to finish. This will take about 2 minutes.

What to notice:

- The DAB gave the workspace a repeatable starting point. This covers data and AI assets, ensuring entire data products can be deployed and managed.

# 2. What was created

## 2. Inspect Unity Catalog

Unity Catalog is the governance layer for data and AI assets. It covers access control, discovery, business semantics, data sharing, lineage, AI governance, cost controls and quality monitoring. Objects in it use a three-part name:

```text
catalog.schema.object
```

Start with the sample data:

1. In the left sidebar, click **Catalog**.
2. Open the `samples` catalog.
3. Open the `wanderbricks` schema.
4. Click a few tables, such as `bookings`, `properties`, `reviews`, and `customer_support_logs`.
5. Open **Sample Data** to preview rows.
6. Open **Details** to see metadata.

Now inspect what the DAB created:

1. Still in **Catalog**, open `<catalog>`.
2. Open `<schema>`.
3. Find these tables:
   - `bronze_bookings`
   - `bronze_payments`
   - `bronze_reviews`
   - `bronze_support_messages`
   - `silver_booking_revenue`
   - `gold_destination_revenue`
   - `gold_property_quality`
   - `support_review_corpus`
   - `serving_property_quality`
4. Open `gold_destination_revenue`.
5. Open **Sample Data**.
6. Open **Lineage**.
7. Repeat for `gold_property_quality`.
8. Open `support_review_corpus` and preview the `text` column.

What to notice:

- The sample catalog is read-only. This was done through the OpenSharing protocol, which allows secure sharing of data and AI assets across clouds and organisations without direct copying.
- Lineage shows how curated tables were created from sample source tables. It also includes the jobs that were run to create them, providing full observability and governance.
- Permissions, quality, and usage can all be inspected here, since all actions on Databricks using data and AI are audited and tracked.

## 3. Inspect The Lakeflow Pipeline

Lakeflow Spark Declarative Pipelines lets you describe the tables you want in SQL or Python, and Databricks manages dependencies, refreshes, retries, and monitoring.

1. In the left sidebar, click **Jobs & Pipelines**.
2. Stay on the **Jobs & pipelines** tab.
3. Open **Wanderbricks Lakeflow SDP - `<schema>`**. If older tutorial runs are also listed, use the unsuffixed name that includes your `<schema>`.
4. Look at the pipeline graph.
5. Click `gold_destination_revenue`.
6. Click `gold_property_quality`.
7. Open the event log or update details for the most recent run.

What to notice:

- The pipeline graph is easier to understand than a long chain of SQL files.
- You can, by clicking the pipeline settings, easily toggle between triggered (batch) and continuous (streaming) behaviour, without any code changes.
- Lakeflow SDP includes row-level tracking, which can selectively update rows based on changes in upstream data, minimising pipeline cost.
- Note that in a Lakeflow Job, you can run and orchestrate **dbt** core jobs as well.
- SDP is an open-source transformation framework. Databricks provides services on top of it to simplify working with them.

## 4. Inspect Metric Views

Metric Views are the semantic layer for business metrics. They give business-friendly names, definitions and synonyms to the tables Lakeflow created.

1. In **Catalog**, open `<catalog>.<schema>`.
2. Click `wanderbricks_destination_metrics`.
3. Open **Overview** and read the description.
4. Look for fields such as `Destination` and measures such as `Gross Booking Value`.
5. Open `wanderbricks_property_quality_metrics`.
6. Look for measures such as `Average Rating`, `Review Count`, and `Low Rating Count`.
7. Click "Edit" to see how these semantics can be configured.

What to notice:

- AI and BI applications can use `Gross Booking Value` instead of making every user understand column names.
- Metrics are governed in Unity Catalog like tables.
- This is where teams document what a metric means, including friendly names, comments, and synonyms.

## 5. Inspect The AI/BI Dashboard

The DAB also created a starter dashboard.

1. In the left sidebar, click **Dashboards**.
2. Open **Wanderbricks Revenue and Guest Experience**.
3. Review:
   - Gross booking value.
   - Booking count.
   - Top destinations by booking value.
   - Guest recovery watchlist.
4. Click **Data** or **Queries** if available to see which tables power the visuals.

What to notice:

- Dashboards are for repeated, trusted views.
- Genie is better for follow-up questions.
- Both can sit on the same governed tables and Metric Views.

# 3. Side quests

## 1. Genie Code

Genie Code is available throughout the platform. You can access it by clicking the colourful genie lamp in the top-right corner of the UI. It is an assistant that helps with building assets on the platform, grounded in your data and AI assets, so feel free to ask questions as you go. You can also configure it and connect your own MCP servers or skills by clicking the settings cog.

## 2. Notice How Other Data Enters The Platform

This tutorial uses `samples.wanderbricks`, but real projects usually start elsewhere, usually with data in a cloud storage bucket, or from an event stream, or from some other database / warehouse or SaaS source. 

1. In the left sidebar, click **New** -> **Add or upload data**.
2. Notice the available data entry paths, such as upload, cloud storage, databases, and connectors.
3. Close the page without uploading anything.

What to notice:

- Unity Catalog can govern unstructured and structured data.
- Databricks can also pull from other databases and SaaS data sources
- Databricks can also integrate with other cloud data warehouses, such as BigQuery, without requiring data to be copied. This is called Lakehouse Federation: https://docs.databricks.com/aws/en/query-federation/
- Databricks can integrate with Fivetran if needed as well

## 3. Optional: Try Lakeflow Designer

Lakeflow Designer is a visual data prep experience. Use this section if you want to see a no-code path for creating a table.

1. Click **New**.
2. Click **Visual data prep**.
3. Add these sources:
   - `samples.wanderbricks.properties`
   - `samples.wanderbricks.bookings`
   - `samples.wanderbricks.reviews`
4. Join properties to bookings on `property_id`.
5. Join properties to reviews on `property_id`.
6. Filter out deleted reviews.
7. Aggregate by property, title, destination, and property type.
8. Add booking count, total booking value, review count, and average rating.
9. Save the output as `<catalog>.<schema>.designer_property_performance`.

What to notice:

- Designer is useful for people who understand data but do not want to write SQL.
- The output is still a Unity Catalog table, and the tool generates Python code which can go through standard CI/CD processes.
- You can compare the visual flow to the DAB-created Lakeflow pipeline.

## 4. Explore Unity AI Gateway

Unity AI Gateway is the governance layer for model and agent traffic. It helps teams manage access, usage tracking, inference tables, guardrails, rate limits, and routing. You can use both Databricks hosted models, which are from all the frontier model providers, or externally hosted models hosted elsewhere.

1. Return to the **Lakehouse** app.
2. In the left sidebar under **AI/ML**, click **AI Gateway**.
3. Open a model endpoint such as a Databricks-hosted Claude or Llama model.
4. Review the controls for permissions, usage tracking, inference tables, guardrails, and rate limits or budgets.
5. Click **+ AI Gateway Endpoint**.
6. Select a Databricks-hosted model, such as **Claude Sonnet 4.6**, as the starting point.
7. Review the options for fallbacks, route splitting, and guardrails.
8. Cancel the flow if you do not want to create another endpoint for the tutorial.

What to notice:

- Different foundation models can sit behind the same platform governance story.
- Gateway controls help production teams understand and shape AI usage.
- Both Databricks-hosted and External models can be governed using this plane.
- The current app template calls the Supervisor Agent endpoint directly. Routing through a Gateway endpoint is possible, but requires a small app configuration change outside this UI-only walkthrough.

Other notes:
- There are also mechanims to centrally control costs around AI models: https://www.databricks.com/blog/introducing-ai-spend-controls-unity-ai-gateway

# 4. Building the app

## 1. Create A Genie Space

Genie Spaces let business users ask natural-language questions about their data, and provide you mechanisms to maintain and control their quality.

1. In the left sidebar, click **Genie Spaces**.
2. Click **New**.
3. Choose **Connect your data**.
4. Add these Metric Views:
   - `<catalog>.<schema>.wanderbricks_destination_metrics`
   - `<catalog>.<schema>.wanderbricks_property_quality_metrics`
5. Name the space `<genie_space>`.
6. Select `<warehouse>`, the SQL warehouse created by the DAB.
7. Add instructions:

```text
You help Wanderbricks revenue, operations, and guest experience teams.
Use Gross Booking Value when users ask about revenue or booking value.
Use Booking Count when users ask about booking volume.
Use Average Rating, Review Count, and Low Rating Count when users ask about guest satisfaction.
When ranking quality, prefer properties with at least 5 reviews unless the user asks otherwise.
Explain which metric or table you used.
Do not expose guest email addresses.
```

8. Save the space.

Genie uses the metadata you stored in Unity Catalog, plus these instructions, to turn everyday questions into governed queries.

### Test Genie

Ask:

```text
Which destinations generate the most booking value?
```

Then ask:

```text
Which high-value properties have lower guest satisfaction?
```

Open the generated SQL if Genie shows it. You do not need to write the SQL, but it is useful to see how Genie maps everyday language to governed metrics.

Chat mode is useful for direct what/which questions. Agent mode is better for deeper, multi-step analysis around patterns and trends. As Genie answers, use **Inspection** to see how it reviewed its answers.

### Improve Genie

1. Open the **Monitoring** tab.
2. Review your questions and Genie answers.
3. Add feedback if an answer is not right.
4. Open the **Benchmarks** tab.
5. Create a benchmark question such as:

```text
Which three destinations have the highest Gross Booking Value?
```

6. Add the expected answer from the dashboard or Metric View result.
7. Run the benchmark.

What to notice:

- Good Genie Spaces use curated data, business-friendly metrics, instructions, and feedback.
- Monitoring and benchmarks create a loop for improving answer quality.

## 2. Use Genie One

Genie One is the business-user entry point for finding BI and app assets such as dashboards, Genie Spaces, and Databricks Apps, and asking questions over all the data in Unity Catalog.

1. Click the nine-dot app switcher in the top-right corner.
2. Select **Genie One**.
3. Select **Search**.
4. Search for `Wanderbricks Revenue`.
5. Open the `Wanderbricks Revenue and Guest Experience` Genie Space or dashboard from the results.
6. Return to the Genie One home page.
7. Select **Ask**.
8. Ask a question such as:

```text
Which three destinations have the highest Gross Booking Value?
```

What to notice:

- Genie One is designed for a business user who knows what they want to ask or find, and it can search across all your assets.
- The assets you created earlier are now discoverable from a single business-facing entry point.

## 3. Create And Test The AI Search Index

AI Search creates a searchable index over text. The DAB created the source table and the AI Search endpoint. You will create the Delta Sync index yourself.

### Create The Index

1. Switch back to the **Lakehouse** app by opening the app switcher.
2. Open **Catalog**.
3. Open `<catalog>.<schema>.support_review_corpus`.
4. Open **Sample Data** and look at the `text` column. This is the review and support-message text the index will search.
5. Click **Create**.
6. Select **AI Search index**.
7. Use these settings:
   - Source table: `<catalog>.<schema>.support_review_corpus`
   - Primary key: `doc_id`
   - Index name: `support_review_corpus_index`
   - AI Search endpoint: `wanderbricks-search-endpoint`
   - Sync mode: **Triggered**
   - Index type: **Hybrid**
   - Text column or embedding source column: `text`
   - Embedding model: `databricks-gte-large-en`
   - Columns to sync: `doc_id`, `doc_type`, `property_id`, `destination`, `user_id`, `rating`, `ticket_id`, `text`, and `created_at`
8. Click **Create**.
9. Wait for the index to finish provisioning and syncing. Refresh if the page still shows provisioning after a few minutes.

### Test The Index

1. In **Catalog**, open `<catalog>.<schema>.support_review_corpus_index`.
2. In the overview, confirm the source table is `support_review_corpus` and the AI Search endpoint is `wanderbricks-search-endpoint`.
3. Confirm the index is synced or ready.
4. Click **Try in Playground**.
5. Use a model such as `Claude Sonnet 4.6`.
6. Ask a question such as:

```text
Tell me about reviews describing properties as dirty
```

What to notice:

- Delta Sync keeps the index connected to the governed source table you inspected.
- This can be connected to agents through **AI Search indexes** tools.
- Databricks lets you try the same governed data with different foundation models.

## 4. Create A Supervisor Agent

The Supervisor Agent coordinates tools. Here, Genie answers structured metric questions, and AI Search retrieves review and support evidence.

1. Open **Agents**.
2. Click **Create Agent**.
3. Select **Supervisor Agent**.
4. Click **Add a Genie Space** and add `<genie_space>` as the structured analytics tool.
5. Click **Add an AI Search index** and add `<catalog>.<schema>.support_review_corpus_index`.
6. Name it `<agent_name>`.
7. Add these instructions:

```text
You are a Wanderbricks guest recovery supervisor.
Use Genie for structured questions about revenue, destinations, properties, bookings, ratings, and review counts.
Use AI Search for qualitative evidence from guest reviews and support conversations.
Separate metric evidence from text evidence.
Do not invent guest, booking, property, or support details.
If evidence is weak or missing, say what is missing.
```

8. Review the tool list. It should include the Genie Space and `support_review_corpus_index` under **AI Search indexes**.
9. Ask:

```text
Which high-value destinations have signs of guest satisfaction risk?
```

Then ask:

```text
Show me the review or support evidence behind that recommendation.
```

What to notice:

- The Supervisor Agent is configured declaratively.
- In the **Examples** tab, you can provide question and guideline examples that the Supervisor Agent can learn from.
- Databricks Agent Bricks also provides a full agent framework for custom agents.

## 5. Explore MLflow For GenAI (optional)

MLflow is the lifecycle and observability layer. This ensures your agents are providing safe and accurate responses.

Start from the Supervisor Agent page:

1. Open the Experiment from the agent page.
2. Look for the experiment or run associated with the agent.
3. Open a recent trace if available.

Important MLflow GenAI features:


| Feature                      | What it's used for                                                                 |
| ---------------------------- | ---------------------------------------------------------------------------------- |
| Traces & Sessions            | Show each step the agent took, including tool calls, inputs, outputs, and latency. |
| Evaluations                  | Test whether answers are grounded, useful, and safe.                               |
| Judges                       | Turn quality expectations into repeatable checks.                                  |
| Datasets & Evaluation runs   | Create repeatable evaluations to track and monitor AI agents over time             |
| Labelling schemas & sessions | Get and evaluate human in the loop feedback                                        |
| Versions                     | Track and improve your agents as you develop them                                  |

What to notice:

- Traces answer "what happened?"
- Evaluations and Judges answer "was it good?"
- Labelling schemas & sessions answer "what does good look like?"
- Registry and versions answer "what are we deploying?"
- Databricks offers a full suite for custom AI agent development and deployment, as well as Classic ML development
- mlflow is open-sourced. This managed service includes integrations with the Databricks Lakehouse (e.g. inference tables) to simplify the AI model lifecycle.

## 6. Create A Databricks App

The supervisor agent can't be directly consumed by business users through Genie One. Databricks Apps lets you deploy secure data and AI apps directly inside Databricks, with authentication managed by Databricks via Unity Catalog. For this tutorial, we'll use a template.

1. Use the app switcher and open **Databricks Apps**.
2. Click **Create app**.
3. Open the **Agents** template tab.
4. Select **Chat UI for Existing Agent**.
5. Name the app `<app_name>`.
6. Select the serving endpoint for the agent. This comes from the endpoint details from the supervisor agent.
7. Review any requested resources.
8. Click **Create**. Wait for the intial app deployment.
9. Click **Settings** in the new window.
10. Under **User authorization**, add the `model-serving` scope. This allows Databricks apps to access model serving endpoints on behalf of the user.
11. Click **Deploy** once the compute is spun up.
12. Open the app when it is ready.
13. Ask:

```text
Which high-value destinations have signs of guest satisfaction risk?
```

Then ask:

```text
Show me the text evidence behind those recommendations.
```

14. Refresh the page. Notice that the chat history disappears. You will fix this with Lakebase Postgres, an OLTP data store integrated with Databricks.

What to notice:

- The app is a user experience over the agent.
- The app does not need to know how the metrics or search index are built.
- Apps can be built using most popular frameworks, with a Python and Node.js runtime backed in


## 7. Add Lakebase Autoscaling For App State

The template chat app is useful, but it does not automatically give you a durable application database for conversation history and other state. Lakebase Autoscaling gives you managed Postgres for low-latency app state. Storage and compute are separated, so you can scale up and down depending on your application's demands near instantly, as well as roll back to previous database versions with the click of a button.

### Create The Project

1. Use the app switcher and open **Lakebase Postgres**.
2. Open **Autoscaling**.
3. Click **New project**.
4. Name the project `<lakebase_project>`.
5. Click **Create**.
6. Open the **production** branch.
7. Open the endpoint or compute settings for the branch.
8. Set the autoscaling range to `0.5` minimum CU and `2` maximum CU.
9. Confirm scale-to-zero is on.
10. Save the change.

### Create A Development Branch

1. Open **Branches**.
2. Click **New branch**.
3. Name it `demo-dev`.
4. Use `production` as the parent branch.
5. Choose an auto-delete setting if the UI asks for one.
6. Create the branch.

What to notice:

- Branches give apps a safe place to test changes. These are logical clones of the branched database. Reads and writes are isolated from the production branch, but there is zero data copy.
- Autoscaling lets small demos and development environments avoid fixed always-on capacity, and avoid noisy-neighbour effects.

## 16. Attach Lakebase To The App

1. Open **Databricks Apps**.
2. Open `<app_name>`.
3. Open **Settings**.
4. Under **Resources**, add a database resource.
5. Select:
   - Project: `<lakebase_project>`
   - Branch: `production`
   - Database: the default app database shown by the UI. Otherwise, `databricks_postgres` is a good default.
6. Save the resource.
7. Redeploy the app. All the necessary tables for the app will be automatically created by the next deployment.
8. Open the app again and ask a question.
9. Refresh the page. Note that the conversation history has been persisted.

What to notice:

- Lakebase is the transactional state store.
- Unity Catalog remains the analytical governance layer.
- Apps can use both.

## 17. Sync Lakehouse Data Into Lakebase

Now sync curated Lakehouse data into Lakebase so an app can read property quality with low latency.

1. Use the app switcher to return to the **Lakehouse** app.
2. Open **Catalog**.
3. Open `<catalog>.<schema>.gold_property_quality`.
4. Click **Create** and choose **Synced table**.
5. Set the Lakebase table name to `gold_property_quality_synced`.
6. Select the Lakebase project `<lakebase_project>`.
7. Select the `production` branch.
8. Select the `databricks_postgres` database, unless the UI shows a different app database you intentionally want to use.
9. Use `property_id` as the primary key.
10. Choose on-demand sync for the tutorial.
11. Create a new sync pipeline when prompted.
12. Click **Create**.
13. Open the Lakebase project link.
14. In the **Tables** tab, find `gold_property_quality_synced` under the `production` branch and selected database.

What to notice:

- The source of truth is still the Lakehouse table.
- Lakebase gives the app a Postgres-shaped serving table. This ensures data can be served at low latency and by Postgres clients for low-latency high-concurrency querying.

## 18. Surface Lakebase Data Back Into The Lakehouse

After the app writes memory or conversation state into Lakebase, bring that operational state back to the Lakehouse for analytics and governance.

1. Use the app switcher to return to **Lakehouse**.
2. Open **Catalog**.
3. **Create** a **Catalog**.
4. Enter a catalog name, such as `lakebase_catalog`.
5. Select **Lakebase Postgres** as the catalog type, then choose the Autoscaling option.
6. Select your project, branch, and Postgres database.
7. Click **Create**.

Now you can examine Lakebase Postgres tables from Unity Catalog. This reaches directly into the database and returns operational data through the governed catalog experience. For larger analytical use cases, Databricks can also replicate Lakebase changes into Lakehouse formats. See: https://docs.databricks.com/aws/en/oltp/projects/lakebase-cdf

What to notice:

- Lakebase handles low-latency operational state.
- The Lakehouse stores governed analytical history.
- The same app loop can serve users and feed monitoring, evaluation, and reporting.

## Cleanup

When you are done:

1. Stop the Databricks App.
2. Delete or stop the AI Search endpoint if you no longer need it.
3. Delete the Lakebase development branch.
4. Delete the Lakebase project
5. Delete the DAB deployment or the `<schema>` if you do not need the tutorial assets.

## Reference Docs

- [Wanderbricks dataset](https://docs.databricks.com/aws/en/discover/wanderbricks-dataset)
- [Unity Catalog](https://docs.databricks.com/aws/en/data-governance/unity-catalog/)
- [Declarative Automation Bundles](https://docs.databricks.com/aws/en/dev-tools/bundles/)
- [DAB resource reference](https://docs.databricks.com/aws/en/dev-tools/bundles/resources)
- [DAB direct deployment engine](https://docs.databricks.com/aws/en/dev-tools/bundles/direct)
- [Lakeflow Spark Declarative Pipelines](https://docs.databricks.com/aws/en/dlt/)
- [Lakeflow Designer](https://docs.databricks.com/aws/en/designer/what-is-lakeflow-designer)
- [Metric Views](https://docs.databricks.com/aws/en/business-semantics/metric-views)
- [Genie Spaces](https://docs.databricks.com/aws/genie/)
- [Databricks AI Search](https://docs.databricks.com/aws/en/ai-search/ai-search)
- [Supervisor Agent](https://docs.databricks.com/aws/en/generative-ai/agent-bricks/multi-agent-supervisor)
- [MLflow GenAI](https://docs.databricks.com/aws/en/mlflow3/genai/)
- [Databricks Apps](https://docs.databricks.com/aws/en/dev-tools/databricks-apps)
- [Unity AI Gateway](https://docs.databricks.com/aws/en/ai-gateway/)
- [Lakebase Autoscaling](https://docs.databricks.com/aws/en/oltp/projects/autoscaling)
- [Lakebase branches](https://docs.databricks.com/aws/en/oltp/projects/branches)

# Content Publishing Pipeline

## Scenario

An editorial team manages article drafts in one database. A separate publishing platform stores the publicly visible posts in its own database. When an editor is ready to go live, they trigger a publish action — an integration that reads the draft, validates it, writes the published post to the publishing platform, and marks the draft as done.

This walkthrough shows how WSO2 BI's **persist database connections** make it straightforward to build that integration. You will create two connectors — one for each database — and use the generated clients to read and write across both systems with a single HTTP call.

---

## What this demonstrates

| Capability | Where it appears |
|---|---|
| Multiple DB connectors | Content DB (MySQL) + Publishing DB (PostgreSQL) |
| One connector = one DB type + one database | Each connector configured separately |
| FK table auto-import | Selecting `drafts` automatically brings in `authors` and `tags` |
| Joined retrieval — one-to-one | `author` returned as a nested record inside the draft |
| Joined retrieval — one-to-many | `tags` returned as an array inside the draft |
| Field selection including FK fields | `author.name`, `author.email`, `tags.label` selected explicitly |
| CRUD via generated client | Get row (draft), Post row (published post), Put row (draft status) |

---

## Databases

**Content DB (MySQL, port 3306)** — the editorial team's system:

| Table | Columns |
|---|---|
| `authors` | author_id (PK), name, email |
| `drafts` | draft_id (PK), title, body, status, author_id (FK → authors) |
| `tags` | tag_id (PK), draft_id (FK → drafts), label |

`drafts` → `authors` is a **one-to-one** relationship (each draft has one author).
`drafts` → `tags` is a **one-to-many** relationship (each draft can have multiple tags).

**Publishing DB (PostgreSQL, port 5433)** — the publishing platform:

| Table | Columns |
|---|---|
| `published_posts` | draft_id (PK), title, author_name |

---

## Prerequisites

- Docker Desktop installed and running

---

## Step 0 — Start the databases

```bash
./start-databases.sh
```

Both containers will start and the script will wait until each is healthy.

```
content-db    MySQL      localhost:3306   db=content_db     user=content_user     pass=content_pass
publishing-db PostgreSQL localhost:5433   db=publishing_db  user=publishing_user  pass=publishing_pass
```

---

## Step 1 — Create the Content DB connector (MySQL)

1. Click `+ Add Artifact`.
2. Select `Connection` from **Other Artifacts**.
3. Click `Connect to a Database`.
4. In the **Introspect Database** form, select `MySQL` as the **Database Type** (the default) and enter the following connection details:

   | Field | Value |
   |---|---|
   | Host | `localhost` |
   | Port | `3306` |
   | Database Name | `content_db` |
   | Username | `content_user` |
   | Password | `content_pass` |

5. Click `Connect & Introspect Database`.
6. In the **Select Tables** form, select all tables and click `Continue to Connection Details`.
7. In the **Create Connection** form, set the **Connection Name** to `contentDB` and click `Save Connection`.

### Step 1.1 - Visualize the database entities

1. Click on the generated `contentDB` connection artifact.
2. Click on the **View ER Diagram** button.
3. You should see the ER diagram showing the relationships between the tables.

---

## Step 2 — Create the Publishing DB connector (PostgreSQL)

Repeat the same steps for the publishing database:

1. Click `+ Add Artifact` and select `Connection` from **Other Artifacts**.
2. Click `Connect to a Database`.
3. In the **Introspect Database** form, select `PostgreSQL` as the **Database Type** and enter:

   | Field | Value |
   |---|---|
   | Host | `localhost` |
   | Port | `5433` |
   | Database Name | `publishing_db` |
   | Username | `publishing_user` |
   | Password | `publishing_pass` |

4. Click `Connect & Introspect Database`.
5. In the **Select Tables** form, select `published_posts` and click `Continue to Connection Details`.
6. In the **Create Connection** form, set the **Connection Name** to `publishingDB` and click `Save Connection`.

---

## Step 3 — Build the integration: `POST /publish`

1. Click `+ Add Artifact` and select `HTTP Service` from **Integration as API**.
2. Set the **Service Base Path** to `/api` and click `Create`.
3. Click `+ Add Resource`, set the **HTTP Method** to `POST`, and set the **Resource Path** to `publish`.
4. Click `+ Define Payload` and paste the following JSON to define the request body schema:

```json
{
  "draftId": "string"
}
```

5. Set the **Type Name** to `PublishRequest` and click `Import Type`.
6. Click the edit icon on the `201` response. Expand **Advanced Configurations**, click the **Response Body Schema** field, and select `+ Create New Type`.
7. Switch to the **Import** tab and paste the following JSON:

```json
{
  "title": "string",
  "author": {
    "name": "string",
    "email": "string"
  },
  "tags": [
    {
      "label": "string"
    }
  ]
}
```

8. Set the **Type Name** to `PublishSuccess` and click `Import`.
9. Select `PublishSuccess` as the **Response Body Schema**. Check **Make This Response Reusable**, set the **Response Definition Name** to `PublishSuccessResponse`, and click `Save`.
10. Click `+ Response` to add the following additional responses. Use the JSON schema below to create the `ErrorMessage` type when prompted:

| Status Code | Description | Response Body Schema | Response Definition Name |
|---|---|---|---|
| `404` | Draft not found | `ErrorMessage` (new type, schema below) | `DraftNotFound` |
| `409` | Conflict (already published or not ready) | `ErrorMessage` (same type) | `PublishConflict` |

```json
{
  "error": {
    "code": "string",
    "message": "string"
  }
}
```

### 3.1 — Get the draft from Content DB

Add a `Get rows from drafts` action node from the `contentDB` connection. Expand **Advanced Configurations** and set:

| Setting | Value |
|---|---|
| Where Clause | `draft_id = payload.draftId` |
| Limit Clause | `1` |

Set the **Result** name to `drafts`. In the **Target Type**, select the following fields:

- `title`, `body`, `status`
- from `author`: `name`, `email`
- from `tags`: `label`

### 3.2 — Handle: draft not found

Add an `If` control node with the condition:

```
drafts.length() == 0
```

Inside the If block, add a `Declare Variable` statement node with:

- **Name:** `draftNotFound`
- **Type:** `DraftNotFound`
- **Expression:**

```json
{
  "body": {
    "error": {
      "code": "DRAFT_NOT_FOUND",
      "message": "No draft found with ID: " + payload.draftId
    }
  }
}
```

Add a `Return` control node to return `draftNotFound`.

### 3.3 — Extract the single draft record

Add a `Declare Variable` statement node with:

- **Name:** `draft`
- **Type:** `DraftsType`
- **Expression:** `drafts.pop()`

### 3.4 — Handle: draft already published

Add an `If` control node with the condition:

```
draft.status == "PUBLISHED"
```

Inside the If block, add a `Declare Variable` statement node with:

- **Name:** `alreadyPublished`
- **Type:** `PublishConflict`
- **Expression:**

```json
{
  "body": {
    "error": {
      "code": "ALREADY_PUBLISHED",
      "message": "Draft '" + payload.draftId + "' has already been published"
    }
  }
}
```

Add a `Return` control node to return `alreadyPublished`.

### 3.5 — Handle: draft not ready

Add an `If` control node with the condition:

```
draft.status != "READY"
```

Inside the If block, add a `Declare Variable` statement node with:

- **Name:** `draftNotReady`
- **Type:** `PublishConflict`
- **Expression:**

```json
{
  "body": {
    "error": {
      "code": "DRAFT_NOT_READY",
      "message": "Draft '" + payload.draftId + "' is not ready for publishing. Current status: " + draft.status
    }
  }
}
```

Add a `Return` control node to return `draftNotReady`.

### 3.6 — Create the published post in Publishing DB

Add an `Insert row into published_posts` action node from the `publishingDB` connection. Toggle the **Array** option and click `+ Initialize Array`, then set the row value:

```
{
	draftId: payload.draftId,
	title: draft.title,
	authorName: draft.author.name
}
```

Set the **Result** name to `publishResult`.

### 3.7 — Update the draft status in Content DB

Add an `Update row in drafts` action node from the `contentDB` connection. Select `draftId` as the key and set its value to `payload.draftId`. In the **Value** section, select `status` and set it to `"PUBLISHED"`:

```
{
    status: "PUBLISHED"
}
```

Set the **Result** name to `updateStatusResult`.

### 3.8 — Return the confirmation

Add a `Declare Variable` statement node with:

- **Name:** `publishSuccess`
- **Type:** `PublishSuccessResponse`
- **Expression:**

```
{
	"body": {
		"title": draft.title,
		"author": draft.author,
		"tags": draft.tags
	}
}
```

Add a `Return` control node to return `publishSuccess`.

---

## Step 4 - Run the integration

Click the **Run** button to start the service. It will ask to create a Config.toml to create the required configuration for the database connections. Click `Create Config.toml` and then provide the password values for the two database connections when prompted:

```
Enter value for contentDBPassword: content_pass
Enter value for publishingDBPassword: publishing_pass
```

---

## Sample requests & responses

### Publish a ready draft

```
POST /publish
Content-Type: application/json

{ "draftId": "DRAFT-001" }
```

```json
200 OK
{
  "title": "Getting Started with WSO2 BI",
  "author": {
    "name": "Jane Smith",
    "email": "jane@example.com"
  },
  "tags": [
    { "label": "integration" },
    { "label": "tutorial" },
    { "label": "wso2" }
  ]
}
```

### Draft is not ready yet

```
POST /publish
Content-Type: application/json

{ "draftId": "DRAFT-002" }
```

```json
409 Conflict
{
  "error": {
    "code": "DRAFT_NOT_READY",
    "message": "Draft 'DRAFT-002' is not ready for publishing. Current status: DRAFT"
  }
}
```

### Draft already published (run the first request a second time)

```
POST /publish
Content-Type: application/json

{ "draftId": "DRAFT-001" }
```

```json
409 Conflict
{
  "error": {
    "code": "ALREADY_PUBLISHED",
    "message": "Draft 'DRAFT-001' has already been published"
  }
}
```

### Draft not found

```
POST /publish
Content-Type: application/json

{ "draftId": "DRAFT-999" }
```

```json
404 Not Found
{
  "error": {
    "code": "DRAFT_NOT_FOUND",
    "message": "No draft found with ID: DRAFT-999"
  }
}
```

---

## Seed data reference

### Content DB — `authors`

| author_id | name | email |
|---|---|---|
| AUTH-001 | Jane Smith | jane@example.com |
| AUTH-002 | Mark Lee | mark@example.com |

### Content DB — `drafts`

| draft_id | title | status | author_id |
|---|---|---|---|
| DRAFT-001 | Getting Started with WSO2 BI | `READY` | AUTH-001 |
| DRAFT-002 | Advanced Integration Patterns | `DRAFT` | AUTH-002 |

> `DRAFT-001` is the publishable draft. `DRAFT-002` is intentionally left in `DRAFT` status to demonstrate the not-ready error case.

### Content DB — `tags`

| tag_id | draft_id | label |
|---|---|---|
| TAG-001 | DRAFT-001 | integration |
| TAG-002 | DRAFT-001 | tutorial |
| TAG-003 | DRAFT-001 | wso2 |
| TAG-004 | DRAFT-002 | advanced |
| TAG-005 | DRAFT-002 | patterns |

### Publishing DB — `published_posts`

Empty on startup. The integration creates the first row.

---

## Resetting to a clean state

```bash
docker compose -f docker/docker-compose.yml down -v && ./start-databases.sh
```

This wipes all data volumes and re-seeds from the init scripts, so all test scenarios are reproducible from scratch.

---

## Stopping the databases

```bash
./stop-databases.sh
```

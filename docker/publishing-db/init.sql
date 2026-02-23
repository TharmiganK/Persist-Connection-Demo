CREATE TABLE published_posts (
    post_id         VARCHAR(36)  NOT NULL,
    draft_id        VARCHAR(36)  NOT NULL UNIQUE,
    title           VARCHAR(200) NOT NULL,
    author_name     VARCHAR(100) NOT NULL,
    tags_summary    TEXT,
    published_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    PRIMARY KEY (post_id)
);

-- Empty on start — the integration creates the first record.

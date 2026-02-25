CREATE TABLE published_posts (
    draft_id        VARCHAR(36)  NOT NULL,
    title           VARCHAR(200) NOT NULL,
    author_name     VARCHAR(100) NOT NULL,
    PRIMARY KEY (draft_id)
);

-- Empty on start — the integration creates the first record.

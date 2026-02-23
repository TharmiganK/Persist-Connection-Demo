CREATE TABLE authors (
    author_id   VARCHAR(36)  NOT NULL,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NOT NULL,
    PRIMARY KEY (author_id)
);

CREATE TABLE drafts (
    draft_id    VARCHAR(36)  NOT NULL,
    title       VARCHAR(200) NOT NULL,
    body        TEXT         NOT NULL,
    status      VARCHAR(20)  NOT NULL DEFAULT 'DRAFT',
    author_id   VARCHAR(36)  NOT NULL,
    PRIMARY KEY (draft_id),
    CONSTRAINT fk_drafts_author FOREIGN KEY (author_id) REFERENCES authors (author_id)
);

CREATE TABLE tags (
    tag_id      VARCHAR(36)  NOT NULL,
    draft_id    VARCHAR(36)  NOT NULL,
    label       VARCHAR(50)  NOT NULL,
    PRIMARY KEY (tag_id),
    CONSTRAINT fk_tags_draft FOREIGN KEY (draft_id) REFERENCES drafts (draft_id)
);

-- Authors
INSERT INTO authors (author_id, name, email) VALUES
    ('AUTH-001', 'Jane Smith',  'jane@example.com'),
    ('AUTH-002', 'Mark Lee',    'mark@example.com');

-- Drafts
-- DRAFT-001: ready to publish (happy path)
-- DRAFT-002: still in progress (triggers DRAFT_NOT_READY error)
INSERT INTO drafts (draft_id, title, body, status, author_id) VALUES
    ('DRAFT-001', 'Getting Started with WSO2 BI',
     'WSO2 BI makes it easy to build integrations that span multiple databases...', 'READY', 'AUTH-001'),
    ('DRAFT-002', 'Advanced Integration Patterns',
     'Once you are comfortable with the basics, you can explore more advanced patterns...', 'DRAFT', 'AUTH-002');

-- Tags
INSERT INTO tags (tag_id, draft_id, label) VALUES
    ('TAG-001', 'DRAFT-001', 'integration'),
    ('TAG-002', 'DRAFT-001', 'tutorial'),
    ('TAG-003', 'DRAFT-001', 'wso2'),
    ('TAG-004', 'DRAFT-002', 'advanced'),
    ('TAG-005', 'DRAFT-002', 'patterns');

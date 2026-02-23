import ballerina/persist as _;
import ballerina/time;
import ballerinax/persist.sql;

@sql:Name {value: "published_posts"}
public type PublishedPost record {|
    @sql:Name {value: "post_id"}
    @sql:Varchar {length: 36}
    readonly string postId;
    @sql:Name {value: "draft_id"}
    @sql:Varchar {length: 36}
    @sql:UniqueIndex {name: "published_posts_draft_id_key"}
    string draftId;
    @sql:Varchar {length: 200}
    string title;
    @sql:Name {value: "author_name"}
    @sql:Varchar {length: 100}
    string authorName;
    @sql:Name {value: "tags_summary"}
    string? tagsSummary;
    @sql:Name {value: "published_at"}
    time:Utc publishedAt;
|};

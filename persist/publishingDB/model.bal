import ballerina/persist as _;
import ballerinax/persist.sql;

@sql:Name {value: "published_posts"}
public type PublishedPost record {|
    @sql:Name {value: "draft_id"}
    @sql:Varchar {length: 36}
    readonly string draftId;
    @sql:Varchar {length: 200}
    string title;
    @sql:Name {value: "author_name"}
    @sql:Varchar {length: 100}
    string authorName;
|};

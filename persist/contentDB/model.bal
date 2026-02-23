import ballerina/persist as _;
import ballerinax/persist.sql;

@sql:Name {value: "drafts"}
public type Draft record {|
    @sql:Name {value: "draft_id"}
    @sql:Varchar {length: 36}
    readonly string draftId;
    @sql:Varchar {length: 200}
    string title;
    string body;
    @sql:Varchar {length: 20}
    string status;
    @sql:Name {value: "author_id"}
    @sql:Varchar {length: 36}
    @sql:Index {name: "fk_drafts_author"}
    string authorId;
    @sql:Relation {keys: ["authorId"]}
    Author author;
    Tag[] tags;
|};

@sql:Name {value: "authors"}
public type Author record {|
    @sql:Name {value: "author_id"}
    @sql:Varchar {length: 36}
    readonly string authorId;
    @sql:Varchar {length: 100}
    string name;
    @sql:Varchar {length: 100}
    string email;
    Draft[] drafts;
|};

@sql:Name {value: "tags"}
public type Tag record {|
    @sql:Name {value: "tag_id"}
    @sql:Varchar {length: 36}
    readonly string tagId;
    @sql:Name {value: "draft_id"}
    @sql:Varchar {length: 36}
    @sql:Index {name: "fk_tags_draft"}
    string draftId;
    @sql:Varchar {length: 50}
    string label;
    @sql:Relation {keys: ["draftId"]}
    Draft draft;
|};

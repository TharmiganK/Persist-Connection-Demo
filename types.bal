import ballerina/http;

public type PublishRequest record {|
    string draftId;
|};

public type Author record {|
    string name;
    string email;
|};

public type TagsItem record {|
    string label;
|};

public type Tags TagsItem[];

public type PublishSuccess record {|
    string postId;
    string title;
    Author author;
    Tags tags;
    string publishedAt;
|};

public type PublishSuccessResponse record {|
    *http:Ok;
    PublishSuccess body;
    record {|
        (string|int|boolean|string[]|int[]|boolean[])...;
    |} headers?;
|};

public type Error record {|
    string code;
    string message;
|};

public type ErrorMessage record {|
    Error 'error;
|};

public type DraftNotFound record {|
    *http:NotFound;
    ErrorMessage body;
    record {|
        (string|int|boolean|string[]|int[]|boolean[])...;
    |} headers?;
|};

public type PublishConflict record {|
    *http:Conflict;
    ErrorMessage body;
    record {|
        (string|int|boolean|string[]|int[]|boolean[])...;
    |} headers?;
|};

public type DraftType record {|
    DraftAuthorType author;
    string title;
    string body;
    string status;
    DraftTagsType[] tags;
|};

public type DraftAuthorType record {|
    string name;
    string email;
|};

public type DraftTagsType record {|
    string label;
|};

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
    string title;
    Author author;
    Tags tags;
|};

public type Error record {|
    string code;
    string message;
|};

public type ErrorMessage record {|
    Error 'error;
|};

public type PublishSuccessResponse record {|
    *http:Created;
    PublishSuccess body;
    record {|
        (string|int|boolean|string[]|int[]|boolean[])...;
    |} headers?;
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

public type DraftsType record {|
    DraftsAuthorType author;
    DraftsTagsType[] tags;
    string title;
    string body;
    string status;
|};

public type DraftsTagsType record {|
    string label;
|};

public type DraftsAuthorType record {|
    string name;
    string email;
|};

import persist_connection_demo.contentDB;

import ballerina/http;
import ballerina/time;
import ballerina/uuid;

listener http:Listener httpDefaultListener = http:getDefaultListener();

service /api on httpDefaultListener {
    resource function post publish(@http:Payload PublishRequest payload) returns error|PublishSuccessResponse|DraftNotFound|PublishConflict {
        do {
            DraftType[] drafts = check contentDB->/drafts.get(whereClause = `draft_id=${payload.draftId}`, limitClause = `1`);
            if drafts.length() == 0 {
                DraftNotFound draftNotFound = {
                    "body": {
                        "error": {
                            "code": "DRAFT_NOT_FOUND",
                            "message": "No draft found with ID: " + payload.draftId
                        }
                    }
                };
                return draftNotFound;
            }
            DraftType draft = drafts.pop();
            if draft.status == "PUBLISHED" {
                PublishConflict alreadyPublished = {
                    "body": {
                        "error": {
                            "code": "ALREADY_PUBLISHED",
                            "message": "Draft '" + payload.draftId + "' has already been published"
                        }
                    }
                };
                return alreadyPublished;
            }
            if draft.status != "READY" {
                PublishConflict draftNotReady = {
                    "body": {
                        "error": {
                            "code": "DRAFT_NOT_READY",
                            "message": "Draft '" + payload.draftId + "' is not ready for publishing. Current status: " + draft.status
                        }
                    }
                };
                return draftNotReady;
            }
            string postId = uuid:createType4AsString();
            string tagsSummary = string:'join(",", ...draft.tags.map(tag => tag.label));
            time:Utc publishedAt = time:utcNow();
            string[] publishResult = check publishingDB->/publishedposts.post([
                {
                    postId: postId,
                    draftId: payload.draftId,
                    title: draft.title,
                    authorName: draft.author.name,
                    tagsSummary: tagsSummary,
                    publishedAt: publishedAt
                }
            ]);
            contentDB:Draft updateStatusResult = check contentDB->/drafts/[payload.draftId].put({
                status: "PUBLISHED"
            });
            PublishSuccessResponse publishSuccess = {
                "body": {
                    "postId": postId,
                    "title": draft.title,
                    "author": draft.author,
                    "tags": draft.tags,
                    "publishedAt": time:utcToString(publishedAt)
                }
            };
            return publishSuccess;
        } on fail error err {
            // handle error
            return error("unhandled error", err);
        }
    }

}

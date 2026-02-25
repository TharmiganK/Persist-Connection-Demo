import persist_connection_demo.contentDB;
import persist_connection_demo.publishingDB;

final contentDB:Client contentDB = check new (contentDBHost, contentDBPort, contentDBUser, contentDBPassword, contentDBDatabase);
final publishingDB:Client publishingDB = check new (publishingDBHost, publishingDBPort, publishingDBUser, publishingDBPassword, publishingDBDatabase);


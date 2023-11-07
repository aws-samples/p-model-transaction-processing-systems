## API Mongo API Container

A Container that receives API requests, writes to an MongoDB Atlas databases, and invokes an API

### States

![API Mongo API Container States!](images/ApiMongoApiContainerStates.jpg)

### Events

1. eAPIMongoAPIContainer(name: string, region: int, databaseName: string, database: MongoDBAtlas, outAPIName: string, outAPI: APIMongoKafkaContainer)
2. eAPIMongoAPIContainerInvoke: (name: string, region: int, record: tRecord, invoker: machine)
3. eAPIMongoAPIContainerInvokeCompleted: (name: string, region: int, record: tRecord, success: bool)
4. eAPIMongoAPIContainerReceiveNotification: (name: string, region: int, count: int, invoker: machine)
5. eAPIMongoAPIContainerReceiveNotificationResponse: (name: string, region: int, count: int, success: bool)
6. eAPIMongoAPIContainerSetDatabase: (name: string, region: int, database: MongoDBAtlas, invoker: machine)
7. eAPIMongoAPIContainerSetDatabaseCompleted: (name: string, region: int, database: MongoDBAtlas, success: bool)
8. eAPIMongoAPIContainerSetOutAPI: (name: string, region: int, outAPI: APIMongoKafkaContainer, invoker: machine)
9. eAPIMongoAPIContainerSetOutAPICompleted: (name: string, region: int, outAPI: APIMongoKafkaContainer, success: bool)
10. eAPIMongoAPIContainerFail: (name: string, region: int)
11. eAPIMongoAPIContainerRecover: (name: string, region: int)
12. eAPIMongoAPIContainerKill: (name: string, region: int)
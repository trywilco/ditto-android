# Ditto - Sample MongoDB Connector `Solar System Guides` App

This is a sample application that demonstrates how to use the MongoDB Connector for Ditto with the `guides` sample data that comes with MongoDb Atlas. 

# Prerequisites

## MongoDb Atlas 

- Basic understanding of MongoDB Atlas
- Active MongoDB Atlas account with cluster pre-configured 
- [MongoDB Shell Installed](https://www.mongodb.com/docs/mongodb-shell/)

## SwiftUI 

- Basic understanding of Swift and SwiftUI for SwiftUI app
- XCode 16 or higher

# Setup in MongoDB Atlas

## Setup Atlas User from within MongoDB Atlas
**TODO**

## Setup Atlas Networking from within MongoDB Atlas
**TODO**

## Load the Sample Data

This sample application uses the [sample_guides](https://www.mongodb.com/docs/atlas/sample-data/sample-guides/) database from the MongoDB Atlas cluster and the planets collection.  Use the [MongoDB Atlas documentation](https://www.mongodb.com/docs/guides/atlas/sample-data/) to load the sample_guides data into your cluster before moving forward.  More information on the sample_guides data can be found [here](https://www.mongodb.com/docs/atlas/sample-data/#std-label-load-sample-data).

This dataset was chosen for its small size, which eliminates the need to load large amounts of data into MongoDB Atlas and the Ditto Portal. This makes it an efficient way to test the Ditto MongoDB Connector.

## Setup Collection Settings with the MongoDB Shell

Ditto requires the planets collection to have change stream pre and post images enabled.  The following commands update the collection in order to enable [Change Stream Pre and Post Images](https://docs.ditto.live/cloud/mongodb-connector#create-mongodb-collections).  

With the MongoDB Shell installed, run the following commands, replacing the srv:// with the proper connection string for your cluster and <username> with a username that has admin rights to the cluster:

```sh
mongosh "mongodb+srv://freecluster.abcd1.mongodb.net/sample_guides" 
--apiVersion 1 --username <username> 
```

Once connected, run the following command to enable change stream pre and post images:

```sh
use sample_guides 
db.runCommand({ 
    collMod: "planets", 
    changeStreamPreAndPostImages: { enabled: true } 
})
```

Keep the MongoDB shell open as we will need it in future steps.

# Setup the Ditto MongoDB Connector

Currently, the Ditto MongoDB Connector will only work with documents that have been updated since the connector was created.  This means the workflow needs to be:

1. Create the Ditto MongoDB Connector in the Ditto Portal 
2. Use MongoDb Shell to update the planets collection with the `planetId`  and soft delete field `isArchived`
3. Validate in the Ditto Portal that the documents have been synced into Ditto with the `planetId` field


## Setup the Ditto MongoDB Connector in the Ditto Portal

**TODO**

## Updating the Planet with `planetId` and `isArchived` field

Go back to the MongoDb Shell.  Run the following command to add a unique planetId field to all documents in the planets collection and setting the soft delete field `isArchived` to false.  This should update all the documents in the collection, which should trigger the Ditto MongoDB Connector to sync the documents to Ditto:

```sh
db.planets.updateMany(
    { planetId: { $exists: false } },
    [
        { 
            $set: { 
                planetId: { $toString: "$_id" },
                isArchived: false 
            }
        }
    ]
)
```

This command will:
1. Find all documents that don't have a planetId field
2. Use the document's existing `_id` field (which is already a unique ObjectId)
3. Convert the ObjectId to a string
4. Add it as the planetId field
5. Add a isArchived field and set it to true for soft delete purposes with subscription 

You can verify the update by running:
```sh
db.planets.findOne()  
```
It should show a document with a planetId field, for example:

```json
{
  "_id": "621ff30d2a3e781873fcb65d",
  "_mdb": {
    "_id": "621ff30d2a3e781873fcb65d",
    "ct": [
      1737496378,
      185
    ],
    "tm": {
      "_id": 7
    }
  },
  "hasRings": true,
  "isArchived": false,
  "mainAtmosphere": [
    "H2",
    "He",
    "CH4"
  ],
  "name": "Uranus",
  "orderFromSun": 7,
  "planetId": "621ff30d2a3e781873fcb65d",
  "surfaceTemperatureC": {
    "max": null,
    "mean": -197.2,
    "min": null
  }
}
```

## Validate the documents have been updated with the planetId field

To validate that the documents are syncing in Ditto.

- Log into the [Ditto Portal](https://portal.ditto.live/).  
- Select your app.
- Click on the `Collections` tab
  - You should see the planets collection with the count of documents that were synced from MongoDb Atlas.  The count should be 8 documents.  
  - Click the `View` link for the planets collection to see the documents in the DQL Editor.


# Setup the SwiftUI App

## Setup the DittoConfig.plist file

Update the `dittoConfig.plist` file with the proper values for `appId` and `authToken`.  You can find these values in the Ditto Portal `Connect` tab listed as the App ID and Online Playground Authentication Token.

The endpointUrl in the config file is currently not used in the SwiftUI app.

## Run the SwiftUI App

Open the Guides.xcodeproj file in XCode that can be found in the Run the SwiftUI folder. 


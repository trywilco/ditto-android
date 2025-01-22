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

## Setup Collection Settings with the MongoDB Shell

Ditto requires the movies collection to have change stream pre and post images enabled.  The following commands update the collection in order to enable [Change Stream Pre and Post Images](https://docs.ditto.live/cloud/mongodb-connector#create-mongodb-collections).  

With the MongoDB Shell installed, run the following commands, replacing <username> with a username that has admin rights to the cluster:

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

# Setup the Ditto MongoDB Connector

Currently, the Ditto MongoDB Connector will only work with documents that have been updated since the connector was created.  This means the workflow needs to be:

1. Create the Ditto MongoDB Connector in the Ditto Portal 
2. Use MongoDb Shell to update the movies collection with the planetId field
3. Validate in the Ditto Portal that the documents have been updated with the planetId field


## Setup the Ditto MongoDB Connector in the Ditto Portal

**TODO**

## Updating the Planet with `planetId` and `isArchived` field

Next, run the following command to add a unique planetId field to all documents in the planets collection:

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

**TODO**

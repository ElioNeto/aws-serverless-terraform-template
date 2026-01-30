const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  console.log("Event received:", JSON.stringify(event));

  const body = JSON.parse(event.body || "{}");
  const itemId = Date.now().toString();

  const command = new PutCommand({
    TableName: process.env.TABLE_NAME,
    Item: {
      PK: "ITEM",
      SK: itemId,
      data: body,
      createdAt: new Date().toISOString(),
    },
  });

  try {
    await docClient.send(command);
    return {
      statusCode: 201,
      body: JSON.stringify({ message: "Item created", id: itemId }),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal Server Error" }),
    };
  }
};

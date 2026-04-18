import { MongoMemoryServer } from 'mongodb-memory-server';

export async function getMockDbUri() {
  const mongod = await MongoMemoryServer.create();
  const uri = mongod.getUri();
  console.log(`🍃 Mock Database (In-Memory) started at: ${uri}`);
  return uri;
}

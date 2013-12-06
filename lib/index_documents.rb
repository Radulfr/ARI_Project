require 'mongo'

include Mongo

@connection = MongoClient.new("localhost", "27017")
@db         = @connection.db("ARI")
@collection = @db.collection("stopWords")

all_files = Dir.entries('Docs') - ['.', '..']

#mongo_client = MongoClient.new("localhost", "27017")
#db = mongo_client.db("ARI")
#coll = db.collection("stopWords")


#puts coll.find({"word" => /\w/}, :fields => ["word"]).to_a

puts @collection.find.to_a[0].scan(/"\w"=>"\w"/)


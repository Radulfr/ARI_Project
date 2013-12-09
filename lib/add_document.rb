require 'mongo'

include Mongo

class Addoc

  def initialize
    @connection = MongoClient.new("localhost", "27017")
    @db         = @connection.db("TEST")
    @stopwords  = @db.collection("stopWords")
    @docs       = @db.collection("documents")
    @termscoll  = @db.collection("terms")
    @postings   = @db.collection("postings")
    @sw         = getSW
    @all_files  = Dir.entries('Docs') - ['.', '..']
    @terms      = Array.new
    @indexed    = Array.new
    @ID_INDEX   = 0
    @ID_VALUE   = 1
  end

  def index_words(file)
    file = File.open(file)
    puts "Processing document: ", file.absolute_path
    content = file.read
    content.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    #kind of words
    content = content.scan(/[a-zA-Z][a-zA-Z][a-zA-Z][a-zA-Z]+/)
    content.size.times { |i| content[i] = content[i].gsub(/\p{^Alnum}/, '').to_s.downcase}

    #Deleting StopWords
    content = content - @sw

    #warning
    self.getIndexedTerms

    #Deleting repeated
    content = content.uniq

    @indexed += content
    @indexed = @indexed.uniq
  end
  def getSW
    @sw = Array.new
    stopWords = @stopwords.find.to_a
    stopWords.size.times { |i| @sw[i] = stopWords[i].to_s.scan(/=>"[a-z]+"/)}
    @sw.size.times { |i| @sw[i].to_s.scan(/\w+/){ |w| @sw[i] = w} }
    return @sw
  end

end

a = Addoc.new
a.index_words(ARGV[0])


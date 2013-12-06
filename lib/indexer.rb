require 'mongo'

include Mongo

class Indexer

  #Constructor
  def initialize
    @connection = MongoClient.new("localhost", "27017")
    @db         = @connection.db("ARI_T2")
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

  #Get the indexed terms
  def getIndexedTerms
    @terms = Array.new
    indexedTerms = @termscoll.find.to_a
    indexedTerms.size.times { |i| @terms[i] = indexedTerms[i].to_a[1][1] }
  end

  #Recover the StopWords list
  def getSW
    @sw = Array.new
    stopWords = @stopwords.find.to_a
    stopWords.size.times { |i| @sw[i] = stopWords[i].to_s.scan(/=>"[a-z]+"/)}
    @sw.size.times { |i| @sw[i].to_s.scan(/\w+/){ |w| @sw[i] = w} }
    return @sw
  end

  #Indexing words of a document
  def index_words(file)
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

  #Count word in every doc
  def count_word
    @indexed = "" 
    self.getIndexedTerms
    ndocs = @all_files.size - 1

#    @terms = @terms[1..200]
    nterms = @terms.size - 1
    for i in 0..nterms
      puts "["+(i+1).to_s+"]\tword: "+@terms[i]
      re = Regexp.new(@terms[i])
      total_count = 0
      for j in 0..ndocs
        
        file = File.open('Docs/'+@all_files[j], 'r')
        content = file.read
        file.close

        content.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        file_count = content.scan(re).size
        total_count += file_count
        content = ""
        #insertion
        if file_count > 0
          self.insertDocumentValue(@terms[i], @all_files[j].gsub(/.txt/, ""), file_count)
        end
      end
      #update value terms
      self.updateTermValue(@terms[i], total_count)
    end
  end



############################################################################################################################
  def index_doc
    @docs.remove
    @all_files.each { |file| @docs.insert("docname" => file.gsub(/.txt/,""), "docpath" => File.absolute_path(file, 'Docs/'));
      count_words(file)
       }
  end
 
  def count_words(file)
    f = File.open('Docs/'+file, 'r')
    content = f.read
    content.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    content = content.downcase
    words_file = content.scan(/[a-z]+/)
    words_file -= @sw
    words = words_file.uniq
    puts "File: "+ file+ "... ("+ words_file.size.to_s+ " words)"
    words.each { |term| fdj = words_file.count(term); 
      self.insertDocumentValue(term, file.gsub(/.txt/,""), fdj);
    }
    f.close
    GC.start
  end 

  #Insert pair Term => doc/value , doc/value, ... 
  def insertDocumentValue(term, doc, value)
    exist = @postings.find({:term => term}).to_a

    if exist.size > 0
#      puts term + " does not exists"
      #Updating postings
      @postings.update({:term => term}, {"$set" => { doc => value }})      
      #Updating terms
      #-Querying terms; recover the last value and add
      prev_value = @termscoll.find_one({:term => term}).to_a
      prev_value = prev_value[2][1]
      value += prev_value
#      @termscoll.update({:term => term}, {"$set" => { :value => value }})
      updateTermValue(term,value)
    else
#      puts term + " exists!"
      #Creating in postings
      @postings.insert({"term" => term, doc => value})
      #Creating
      @termscoll.insert({"term" => term, "value" => value})
    end
  end

  #MAIN
  def start
#    @db.drop_database
    @postings.remove
    @termscoll.remove
    puts "Indexing docs..."
    index_doc
    puts "Done!"
    
#    @indexed.size.times { |i| @termscoll.insert("term" => @indexed[i], "value" => 0); @postings.insert("term" => @indexed[i])}
  end
####################################################################################################################################
  #Get the ID of a given term
  def getIdTerm(value)
    term_array = @termscoll.find_one({:term => value}).to_a
    return term_array[@ID_INDEX][@ID_VALUE]
  end

  #Get the ID of a given doc
  def getIdDoc(value)
    doc_array = @docs.find_one({:docname => value}).to_a
    return doc_array[@ID_INDEX][@ID_VALUE]
  end

  #Updating data in Terms table
  def updateTermValue(term,value)
    @termscoll.update({:term => term}, {"$set" => { :value => value }})
  end


  #for testing
  def test
    term_array = @termscoll.find_one({:term => "java"}).to_a
    puts term_array[2][1]
  end

end

#Main
t1 = Time.now 
a = Indexer.new
a.start
#a.insertDocumentValue("calimocho", "Java-Decompiler-HOWTO", 8000)
t2 = Time.now
puts "Total time: " + ((t2 - t1)/60).to_s + " minutes"




#let's change something

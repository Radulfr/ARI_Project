# -*- coding: utf-8 -*-
#delete stopwords
#recover terms - count - etc
require 'mongo'
require 'builder'
include Mongo

class Vectorial

  #Constructor
  def initialize
    @connection = MongoClient.new("localhost", "27017")
    @db         = @connection.db("ARI_TESTING")
    @stopwords  = @db.collection("stopWords")
    @postings   = @db.collection("postings")
    @docs       = @db.collection("documents")
    @sw         = getSW
    @question   = Array.new
    @docslist   = Array.new
    @ID_INDEX   = 0
    @ID_VALUE   = 1
    @INDEX_TITLE= 0
    @INDEX_ID   = 2
    @INDEX_PATH = 3
  end

  #Recover stopwords
  def getSW
    @sw = Array.new
    stopWords = @stopwords.find.to_a
    stopWords.size.times { |i| @sw[i] = stopWords[i].to_s.scan(/=>"[a-z]+"/)}
    @sw.size.times { |i| @sw[i].to_s.scan(/\w+/){ |w| @sw[i] = w} }
    return @sw
  end

  #get the question
  def getQuestion(q)
    q = q.downcase.scan(/\w+/)
    @question = q - @sw
  end

  #Vectorial
  def initVectorial
    docs = Array.new
    docs_names = Array.new
    terms = Array.new
    @question.each { |word| docs += (@postings.find_one({:term => word}).to_a) }
    for i in 0..@question.size-1
      terms[i] = @postings.find_one({:term => @question[i]}).to_a
    end
    for i in 0..docs.size-1
      docs_names[i] = docs[i][0]
    end
    docs_names = docs_names - ['_id', 'term']
    docs_names = docs_names.uniq
    data = Array.new(docs_names.size) { Array.new(terms.size, 0) }
    data_w = Array.new(docs_names.size) { Array.new(terms.size, 0) }
    for i in 0..docs_names.size-1
      for j in 0..terms.size-1
        for k in 0..terms[j].size-1
          if docs_names[i].eql?(terms[j][k][0])
            data[i][j] = terms[j][k][1]
          end
        end
      end
    end
#CONTAR.SI
    count_if = Array.new(@question.size, 0)
    log_count_if = Array.new(@question.size, 0)
    for j in 0..docs_names.size-1
      for i in 0..@question.size-1
        count_if[i] += data[j][i]
      end
    end
#LOGARITHM count_if
#--------------------------------
    log_count_if = Array.new(count_if.size, 0)
    for i in 0..count_if.size-1
      #WARNING HERE
      log_count_if[i] = Math.log10(count_if[i]) 
    end
#DATA_W--------------------------------
#MISSING Q¿?
    for i in 0..docs_names.size-1
      for j in 0..terms.size-1
        data_w[i][j] = data[i][j]/log_count_if[j]
      end
    end
#SUM---------------------------------
    sum = Array.new(docs_names.size,0)
    for i in 0..docs_names.size-1
      for j in 0..terms.size-1
        sum[i] += data_w[i][j]
      end
    end
#SUM---------------------------------
    e1 = Array.new(docs_names.size,0)
    for i in 0..docs_names.size-1
      for j in 0..terms.size-1
        e1[i] += (data_w[i][j])**2
      end
    end
    sum.each_index { |i| e1[i] += sum[i]**2 } 
#E2---------------------------------
    e2 = e1.collect{|item|  item*terms.size}
#SUMA/E2----------------------------
    ranking = Array.new(docs_names.size,0)
    results = Array.new(docs_names.size) { Array.new(4) }
    for i in 0..e1.size-1
      results[i][0] = docs_names[i]
      results[i][1] =  1 - sum[i]/e2[i]
      results[i][2] = getIdDoc(docs_names[i])
      results[i][3] = getDocPath(docs_names[i])
    end
    results = results.sort_by{|e| e[1]}
    results = results.reverse
    return results
  end

  #With a doc name recover path
  def getDocPath(value)
    doc_array = @docs.find_one({:docname => value}).to_a
    return doc_array[2][1]
  end

  #With a doc name recover id
  def getIdDoc(value)
    doc_array = @docs.find_one({:docname => value}).to_a
    return doc_array[@ID_INDEX][@ID_VALUE]
  end

  #for showing results
  def showResult(result)
    for i in 0..result.size-1
      puts i.to_s + "- \t(Doc ID: "+ result[i][2].to_s+") "+result[i][0].to_s + "\t\t\t"+ result[i][1].to_s
    end
  end

  #Main method - question is needed
  def start(question)
    puts "==== QUESTION ===="
    print getQuestion(question), "\n"
    puts "==== RESULTS ===="
    result = initVectorial
    #   showResult(result)
    resultsToXML(result)
    return result
  end

  #results  -> to XML File (Results.xml)
  def resultsToXML(result)
    xml  = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct! :xml, :encoding => "UTF-8"
    xml.declare! :DOCTYPE, :Resultado, :SYSTEM, "Resultados.dtd"
    xml.tag! 'xml-stylesheet', :type => "text/xsl", :href => "Resultados.xsl"
    xml.resultado do |r|
      xml.pregunta do |p|
        @question.each{ |q| p.item q }
      end
      result.each { 
        |r| xml.documento(:id => r[@INDEX_ID]) do |d| 
          d.titulo r[@INDEX_TITLE];
          perc = (r[1]*100).round(2).to_s;
          d.relevancia perc  + "%"; d.texto r[@INDEX_PATH]
        end 
      }
    end
    #UGLY CODE (removing extra <to_s/> from the xml builder)
    f = File.open("Results.xml", 'w')
    f.write(xml)
    f.close
    f = File.open("Results.xml", 'r')
    data = f.read
    data = data.gsub!("<to_s/>", "")
    f.close
    f = File.open("Results.xml", 'w')
    f.write(data)
    f.close
    return data
  end
end

#Init
a = Vectorial.new
#Quetion
a.start("I have a ruby compiler emacs")



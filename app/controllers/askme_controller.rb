class AskmeController < ApplicationController

  def index
    @data = params[:visitor_question]
    if @data == nil
      @data = ""
      @data_size = 0
    else
      @data = @data.downcase 
      ti = Time.now
      a = Vectorial.new
      tf = Time.now
      @time = (tf - ti).to_s
      @data = a.start(@data)
      @data_size = @data.size-1
    end
  end

  def download
    send_file "Results.xml"
  end

  def download_file
    @filename = params[:doc]
    send_file @filename
  end

end

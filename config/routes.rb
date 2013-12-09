Ariproject::Application.routes.draw do
  get "askme/index"
  root "askme#index"

  post '/askme/index', to: 'askme#index'
  get '/askme/download', to: 'askme#download'
  get '/askme/download_file', to: 'askme#download_file'
end

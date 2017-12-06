Rails.application.routes.draw do
  post 'collback' => "linebot#callback"
  get 'callback' => "linebot#get_callback"
end

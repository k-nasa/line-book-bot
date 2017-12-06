Rails.application.routes.draw do
  post 'callback' => "linebot#callback"
  get 'callback' => "linebot#get_callback"
end

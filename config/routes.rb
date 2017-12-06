Rails.application.routes.draw do
  post 'collback' => "linebot#callback"
end

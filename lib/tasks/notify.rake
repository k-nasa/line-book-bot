task :notify_task => :environment do
  webhook_controller = LinebotController.new
  webhook_controller.notify
end

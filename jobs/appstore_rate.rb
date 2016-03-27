require 'net/http'
require 'json'

require_relative '../lib/infrastructure/project_manager'
require_relative '../lib/infrastructure/project_model'
require_relative '../lib/appstore/rate_calculator'
require_relative '../lib/appstore/review_service'
require_relative '../lib/appstore/version_determinator'

SCHEDULER.every '1m', :first_in => 0 do |job|
  project_manager = Infrastructure::ProjectManager.new
  project_manager.obtain_all_projects.each do |project|
    service = AppStore::ReviewService.new
    service.fetch_reviews_for_app_id(project.appstore_id)

    rate_calculator = AppStore::RateCalculator.new
    reviews = service.obtain_reviews_for_app_id(project.appstore_id)

    version_determinator = AppStore::VersionDeterminator.new
    latest_version = version_determinator.determine_latest_version(reviews)
    rating = rate_calculator.calculate_average_rate_for_version(reviews, latest_version)

    widget_name = "appstore_rate_#{project.appstore_id}"
    send_event(widget_name, {
                                  'title' => rating.round(2).to_s,
                                  'text' => "#{project.display_name}, v.#{latest_version}"
                              }
    )
  end
end
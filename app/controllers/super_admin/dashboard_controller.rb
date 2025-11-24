class SuperAdmin::DashboardController < SuperAdmin::ApplicationController
  include ActionView::Helpers::NumberHelper

  def index
    begin
      @data = Conversation.unscoped.group_by_day(:created_at, range: 30.days.ago..2.seconds.ago).count.to_a
    rescue => e
      Rails.logger.error "Error in dashboard data: #{e.message}"
      @data = []
    end
    
    begin
      @accounts_count = number_with_delimiter(Account.count)
    rescue => e
      Rails.logger.error "Error counting accounts: #{e.message}"
      @accounts_count = "0"
    end
    
    begin
      @users_count = number_with_delimiter(User.count)
    rescue => e
      Rails.logger.error "Error counting users: #{e.message}"
      @users_count = "0"
    end
    
    begin
      @inboxes_count = number_with_delimiter(Inbox.count)
    rescue => e
      Rails.logger.error "Error counting inboxes: #{e.message}"
      @inboxes_count = "0"
    end
    
    begin
      @conversations_count = number_with_delimiter(Conversation.count)
    rescue => e
      Rails.logger.error "Error counting conversations: #{e.message}"
      @conversations_count = "0"
    end
  end
end

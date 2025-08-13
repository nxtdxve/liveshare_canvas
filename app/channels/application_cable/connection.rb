module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      # For now, we'll set current_user later when they join
      self.current_user = nil
    end

    def current_user=(user)
      @current_user = user
    end

    def current_user
      @current_user
    end
  end
end
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :set_cache_headers
  
  private
  
  def set_cache_headers
    if request.format.json?
      response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    else
      response.headers['Cache-Control'] = 'public, max-age=300'
      response.headers['Vary'] = 'Accept-Encoding'
    end
    
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
  end
end

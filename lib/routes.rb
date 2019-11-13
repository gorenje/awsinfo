module Routes
end

Dir[File.join(File.dirname(__FILE__), 'routes', '*.rb')].each do |f|
  require_relative f
end

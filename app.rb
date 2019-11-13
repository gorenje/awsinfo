['sinatra/base', 'haml', 'thin', 'base64'].map { |a| require(a) }

require_relative 'lib/extensions'
require_relative 'lib/constants'
require_relative 'lib/awsctl'
require_relative 'lib/helpers'
require_relative 'lib/routes'

class Webapp < Sinatra::Base
  set :show_exceptions, :after_handler

  helpers do
    include ViewHelpers
  end

  include Routes::R53::List
  include Routes::Ecs::List
  include Routes::Ecr::List
  include Routes::Ecr::Add
  include Routes::Ecr::Delete
  include Routes::Ssm::List
  include Routes::Ssm::Add
  include Routes::Ssm::Delete

  get '/' do
    haml ".text-center\n  %a{:href => '/list'} List"
  end

  error(404) do
    haml ".text-center\n  Action/Page not supported."
  end
end

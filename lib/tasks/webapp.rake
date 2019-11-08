# coding: utf-8
require_relative '../../app.rb'

namespace :webapp do
  desc "Start application"
  task :start, [:port] do |t,args|
    fork { exec("aws-mfa") }
    Thin::Server.new((args.port||ENV['PORT']||'3001').to_i).tap do |s|
      s.app = Webapp
    end.start
  end
end

module Routes
  module Ssm
    module List
      def self.included(app)
        app.get '/ssm/filter' do
          ## Would use the native filtering of AWS but that only has
          ## BeginsWith or exact match, no reg exp.
          regexp = /#{params[:by]}/

          names = Awsctl.run("ssm describe-parameters")["Parameters"].
                     select do |para|
            para["Name"] =~ regexp
          end.map { |a| a["Name"] }

          values = names.each_slice(10).to_a.map { |a| a.join(' ') }.
                     map do |names|
            Awsctl.run("ssm get-parameters --names #{names} --with-decryption")
          end.map { |a| a["Parameters"] }.flatten

          @allrows = [values.first.keys] + values.map(&:values)
          @actions = {
          }
          haml :table
        end

        app.get '/ssm/parameters' do
          paras = Awsctl.run("ssm describe-parameters")

          @allrows = [["Projects"]] + paras["Parameters"].
                                        group_by do |a|
            a["Name"] =~ /([^\/]+\/[^\/]+)\/.+/  ? $1 : a["Name"]
          end.keys.map { |a| [a] }

          @actions = {
            "add" => "stream"
          }
          haml :table
        end

        app.get '/ssm' do
          @links = [
            { title: "Parameters", icon: "stream", path: "parameters" },
            { title: "Filter - Postgres Url", icon: 'database',
              path: "filter?by=DATABASE_URL" },
            { title: "Filter - Rails MASTER_KEY", icon: 'road',
              path: "filter?by=MASTER_KEY" },
            { title: "Filter - Redis Url", icon: 'registered',
              path: "filter?by=REDIS_URL" },
          ]
          haml :links
        end
      end
    end

    module Delete
      def self.included(app)
        app.get '/ssm/parameters/add/delete' do
          Awsctl.run("ssm delete-parameter --name=\"#{params.c0}\"")

          prefix = params.c0.split(/\//)[1..2].join("/")

          redirect "/ssm/parameters/add?c[]=#{CGI.escape(prefix)}"
        end
      end
    end

    module Add
      def self.included(app)
        app.post '/ssm/parameters/add/clone' do
          paras  = Awsctl.run("ssm describe-parameters "+
                              "--filters \"Key=Name,Values="+
                              "#{params[:prefix]}\"")

          values = paras["Parameters"].map { |a| a["Name"] }.
                     each_slice(10).to_a.map { |a| a.join(' ') }.
                     map do |names|
            Awsctl.run("ssm get-parameters --names #{names} --with-decryption")
          end.map { |a| a["Parameters"] }.flatten

          values.each do |hsh|
            name = hsh["Name"].split(/\//).last
            Awsctl.run("ssm put-parameter --overwrite --type #{hsh['Type']} "+
                       "--name /#{params[:new_prefix]}/#{name} "+
                       "--value=\"#{hsh['Value']}\"")
          end

          redirect "/ssm/parameters/add?c[]=#{CGI.escape(params[:new_prefix])}"
        end

        app.post '/ssm/parameters/add/upsert' do
          Awsctl.run("ssm put-parameter --overwrite --type SecureString "+
                     "--name /#{params[:prefix]}/#{params[:name]} "+
                     "--value=\"#{params[:value]}\"")
          redirect "/ssm/parameters/add?c[]=#{CGI.escape(params[:prefix])}"
        end

        app.get '/ssm/parameters/add' do
          paras  = Awsctl.run("ssm describe-parameters "+
                              "--filters \"Key=Name,Values=#{params.c0}\"")

          values = paras["Parameters"].map { |a| a["Name"] }.
                     each_slice(10).to_a.map { |a| a.join(' ') }.
                     map do |names|
            Awsctl.run("ssm get-parameters --names #{names} --with-decryption")
          end.map { |a| a["Parameters"] }.flatten

          @allrows = [(values.first || {}).keys] + values.map(&:values)
          @actions = {
            "delete" => "minus-circle"
          }
          haml :add_parameter
        end
      end
    end
  end
end

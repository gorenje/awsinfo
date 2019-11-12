# coding: utf-8
module Routes
  module Ecr
    module Delete
      def self.included(app)
        app.get "/ecr/list/delete" do
          Awsctl.run("ecr delete-repository "+
                     "--repository-name #{params.c2} --force")
          redirect "/ecr/list"
        end

        app.get "/ecr/list/recreate" do
          Awsctl.run("ecr delete-repository "+
                     "--repository-name #{params.c2} --force")
          Awsctl.run("ecr create-repository "+
                     "--repository-name '#{params.c2}'")
          redirect "/ecr/list"
        end
      end
    end

    module Add
      def self.included(app)
        app.post "/ecr/list/create" do
          Awsctl.run("ecr create-repository "+
                     "--repository-name '#{params[:name]}'")
          redirect "/ecr/list"
        end
      end
    end

    module List
      def self.included(app)
        app.get '/ecr/list/images' do
          data = Awsctl.run("ecr list-images "+
                            "--repository-name #{params.c2}")["imageIds"]

          @allrows = [["repo"] +
                      data.map(&:keys).flatten.uniq] +
                     data.map(&:values).map { |a| [params.c2] + a }

          @actions = {
          }

          @title = params.c2
          haml :table
        end

        app.get '/ecr/list' do
          data = Awsctl.run("ecr describe-repositories")["repositories"]
          @allrows = [data.first.keys] + data.map(&:values)
          @actions = {
            "images"   => "stream",
            "delete"   => "minus-circle",
            "recreate" => "sync-alt"
          }
          haml :list_repositories
        end

        app.get '/ecr' do
          @links = [
            { title: 'Repositories', path: "list", icon: "stream" },
          ]
          haml :links
        end
      end
    end
  end

  module Ssm
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
  end

  module Ecs
    module List
      def self.included(app)

        app.get '/ecs/list/containers' do
          task_list = Awsctl.run("ecs list-tasks --cluster "+
                                 "#{params.c0}")["taskArns"].join(" ")

          tasks = Awsctl.run("ecs describe-tasks --cluster "+
                             "#{params.c0} --tasks #{task_list}")["tasks"]

          instances_list = tasks.map {|a| a["containerInstanceArn"]}.join(" ")

          data = Awsctl.run("ecs describe-container-instances "+
                            "--cluster #{params.c0} "+
                            "--container-instances "+
                            "#{instances_list}")["containerInstances"]

          @allrows = [data.first.keys] + data.map(&:values)
          @actions = {
          }

          puts(params.class)
          haml :table
        end

        app.get '/ecs/list/tasks' do
          task_list = Awsctl.run("ecs list-tasks "+
                                    "--cluster #{params.c0}")["taskArns"].
                        join(" ")

          data = Awsctl.run("ecs describe-tasks "+
                            "--cluster #{params.c0} "+
                            "--tasks #{task_list}")["tasks"]

          @allrows = [data.first.keys] + data.map(&:values)
          @actions = {
          }
          haml :table
        end

        app.get '/ecs/list/services/ips/terminal' do
          Awsctl.open_terminal("ssh #{params.c3}")
          redirect back
        end

        app.get '/ecs/list/services/ips' do
          task_list = Awsctl.run("ecs list-tasks --cluster #{params.c0} "+
                                 "--service #{params.c1}")["taskArns"].
                        join(" ")

          return haml("No tasks found") if task_list.blank?

          tasks = Awsctl.run("ecs describe-tasks --cluster #{params.c0} "+
                                "--tasks #{task_list}")["tasks"]

          containerToTask = {}
          instances_list = tasks.map do |task|
            containerToTask[task["containerInstanceArn"]] = task
            task["containerInstanceArn"]
          end.join(" ")

          data = Awsctl.run("ecs describe-container-instances "+
                            "--cluster #{params.c0} --container-instances "+
                            "#{instances_list}")["containerInstances"]

          contInst = Hash[data.map { |a| [a["containerInstanceArn"], a] }]

          ec2InstIds = tasks.map do |task|
            contInst[task["containerInstanceArn"]]["ec2InstanceId"]
          end.uniq

          data = Awsctl.run("ec2 describe-instances --instance-ids "+
                            "#{ec2InstIds.join(' ')}")

          ec2IdTwoIp = {}

          data["Reservations"].each do |res|
            res["Instances"].each do |inst|
              ec2IdTwoIp[inst["InstanceId"]] = [
                inst["PrivateDnsName"],
                inst["PublicDnsName"],
              ]
            end
          end

          @allrows = tasks.map do |task|
            cInstArn = task["containerInstanceArn"]
            ec2InstId = contInst[cInstArn]["ec2InstanceId"]
            [task["taskArn"], cInstArn, ec2InstId,
             ec2IdTwoIp[ec2InstId].first, ec2IdTwoIp[ec2InstId].last]
          end

          @allrows = [ ["tasks", "container", "ec2", "private", "public"] ] +
                     @allrows
          @actions = {
            "terminal" => "terminal"
          }
          haml :table
        end

        app.get '/ecs/list/services' do
          @allrows = Awsctl.run("ecs list-services --cluster "+
                                "#{params.c0}")["serviceArns"]
          @allrows = [ ["Cluster","Services"] ] +
                     @allrows.map { |a| [params.c0,a] }
          @actions = {
            "ips" => "file",
          }
          haml :table
        end

        app.get '/ecs/list' do
          @allrows = Awsctl.run("ecs list-clusters")["clusterArns"]
          @allrows = [["ClusterNames"]] + @allrows.map {|a|[a]}
          @actions = {
            "services"   => "stream",
            "tasks"      => "file",
            "containers" => "edit",
          }
          haml :table
        end

        app.get '/ecs' do
          @links = [
            { title: 'Clusters', path: "list", icon: "stream" },
          ]
          haml :links
        end
      end
    end
  end
end

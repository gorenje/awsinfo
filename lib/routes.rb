# coding: utf-8
module Routes
  module Ecr
    module List
      def self.included(app)
        app.get '/ecr/list/images' do
          data = Awsctl.run("ecr list-images "+
                            "--repository-name #{params.c2}")["imageIds"]

          @allrows = [data.map(&:keys).flatten.uniq] + data.map(&:values)
          @actions = {
          }
          haml :table
        end

        app.get '/ecr/list' do
          data = Awsctl.run("ecr describe-repositories")["repositories"]
          @allrows = [data.first.keys] + data.map(&:values)
          @actions = {
            "images"   => "stream",
          }
          haml :table
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
          Awsctl.run("ssm delete-parameter --name=\"#{params[:c].first}\"")

          prefix = params[:c].first.split(/\//)[1..2].join("/")

          redirect "/ssm/parameters/add?c[]=#{CGI.escape(prefix)}"
        end
      end
    end

    module Add
      def self.included(app)
        app.post '/ssm/parameters/add' do
          Awsctl.run("ssm put-parameter --overwrite --type SecureString "+
                     "--name /#{params[:prefix]}/#{params[:name]} "+
                     "--value=\"#{params[:value]}\"")
          redirect "#{request.path}?c[]=#{CGI.escape(params[:prefix])}"
        end

        app.get '/ssm/parameters/add' do
          paras  = Awsctl.run("ssm describe-parameters "+
                              "--filters \"Key=Name,Values="+
                              "#{params[:c].first}\"")

          values = paras["Parameters"].map { |a| a["Name"] }.
                     each_slice(10).to_a.map { |a| a.join(' ') }.
                     map do |names|
            Awsctl.run("ssm get-parameters --names #{names} --with-decryption")
          end.map { |a| a["Parameters"] }.flatten

          @allrows = [values.first.keys] + values.map(&:values)
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

        app.get '/ssm/parameters/list' do
          paras  = Awsctl.run("ssm describe-parameters "+
                              "--filters \"Key=Name,Values="+
                              "#{params[:c].first}\"")

          values = paras["Parameters"].map { |a| a["Name"] }.
                     each_slice(10).to_a.map { |a| a.join(' ') }.
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
            "list" => "stream",
            "add" => "plus-circle"
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

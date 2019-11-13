module Routes
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

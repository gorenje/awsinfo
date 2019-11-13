module Routes
  module Ecr
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
  end
end

module Routes
  module Log
    module List
      def self.included(app)
        app.get '/log' do
          @links = [
            { title: 'Domains', path: "list", icon: "stream" },
          ]
          haml :links
        end

        app.get '/log/list' do
          data = Awsctl.run("logs describe-log-groups")["logGroups"]

          @allrows = [ ["logGroupName", "arn" ] ] +
                     data.map do |hsh|
            [ hsh["logGroupName"], hsh["arn"] ]
          end

          @actions = {
            "streams" => "stream"
          }

          haml :table
        end

        app.get '/log/list/streams' do
          data = Awsctl.run("logs describe-log-streams "+
                            "--log-group-name #{params.c0}")["logStreams"]

          cols = [
            "logGroupName",
            "logStreamName",
            "creationTime",
            "firstEventTimestamp",
            "lastEventTimestamp",
            "lastIngestionTime",
            "storedBytes",
          ]

          @allrows = [ cols ] +
                     data.map do |hsh|
            hsh["logGroupName"] = params.c0
            cols.map { |colname| hsh[colname] }
          end

          @actions = {
            "events" => "scroll"
          }

          haml :table
        end

        app.get '/log/list/streams/events' do
          Awsctl.
            open_terminal("watch \\\"aws logs get-log-events "            +
                          "--output text --log-stream-name #{params.c1} " +
                          "--log-group-name #{params.c0} --limit 1000 "   +
                          "| tac\\\"")
          redirect back
        end
      end
    end
  end
end

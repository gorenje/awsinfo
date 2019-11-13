module Routes
  module R53
    module List
      def self.included(app)
        app.get '/r53' do
          @links = [
            { title: 'Domains', path: "list", icon: "stream" },
          ]
          haml :links
        end

        app.get '/r53/list' do
          data = Awsctl.run("route53 list-hosted-zones")["HostedZones"]

          @allrows = [ ["Id", "Name", "Count" ] ] +
                     data.map do |hsh|
            [ hsh["Id"], hsh["Name"], hsh["ResourceRecordSetCount"] ]
          end

          @actions = {
            "subdomains" => "stream"
          }

          haml :table
        end

        app.get '/r53/list/subdomains' do
          data = Awsctl.run("route53 list-resource-record-sets "+
                            "--hosted-zone-id #{params.c0}")["ResourceRecordSets"]

          @allrows = [ ["Name", "Type", "Data" ] ] +
                     data.map do |hsh|
            d = [ hsh["Name"], hsh["Type"] ]
            hsh.delete("Name")
            hsh.delete("Type")
            hsh.delete("TTL")
            d + [hsh.to_json]
          end

          @actions = {
          }

          haml :table
        end
      end
    end
  end
end

require 'json'

module Awsctl
  extend self

  def run(cmdline)
    result = `aws --region=eu-west-1 --output json #{cmdline}`
    begin
      JSON(result)
    rescue Exception => e
      puts("Parsing error: ----\n#{result}\n-----")
      nil
    end
  end

  def open_terminal(script)
    ## TODO don't add kbcfg if it's empty
    system("osascript -e 'tell application \"Terminal\" to do script " +
           "\"#{script}\"'")
  end
end

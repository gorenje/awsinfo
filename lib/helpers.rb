module ViewHelpers
  ActionWithIcons = {
      "delete"  => "trash-alt",
      "list"    => "stream",
      "desc"    => "file",
      "edit"    => "edit",
      "scale"   => "cloudscale",
      "shell"   => "terminal",
      "restart" => "power-off"
    }

  def perc(what,value,limits)
    return -1 if limits.nil? or limits[what.to_s].nil?
    max = limits[what.to_s].to_i
    ((value / max.to_f) * 100).to_i
  end

  def header_row(line)
    (line + ["Actions"]).map { |v| "<th>#{v.capitalize}</th>" }.join("\n")
  end

  def cell(value)
    o = value =~ /^([0-9]+)(m|Mi|Gi|%|d|h|Ki)/ ? Nrm.call($1,$2)
                                               : CGI.escape(value.to_s)
    "<td data-order='#{o}'>#{value}</td>"
  end

  def line_to_row(line)
    actions = @actions || ActionWithIcons
    (c = line).map { |v| cell(v) }.join("\n") + "<td>" +
      actions.keys.map do |v|
        paras = c.map { |p| "c[]=#{CGI.escape(p.to_s)}" }.join("&")
        "<a class='action _#{v} fas fa-#{actions[v]}' title='#{v}' "+
          "href='#{request.path}/#{v}?#{paras}'></a>"
      end.join("&nbsp;") + "</td>"
  end

  def gh(n,v)
    { :name => n, :value => v }
  end
end

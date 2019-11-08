class NilClass
  def empty?
    true
  end
  def blank?
    true
  end
end

class String
  def blank?
    empty? || self =~ /^\s+$/
  end
end

class Sinatra::IndifferentHash
  def method_missing(name,*args,&block)
    name.to_s =~ /^c([0-9]+)$/ ? self[:c][$1.to_i] : super
  end
end

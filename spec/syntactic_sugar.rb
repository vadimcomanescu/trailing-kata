module SyntacticSugar
  
  def method_missing method, *args
    method_parts = method.to_s.split("_")
    return method_parts[1].to_i if method_parts[0] =~ /only/
  end  
end

class Fixnum
  def seconds
    self
  end

  def some_currency
    self
  end
end

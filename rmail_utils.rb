module RmailUtils
  def confronta_liste(fn1, fn2, fn)
    fn = "#{fn1.parameterize}***#{fn2.parameterize}.txt" unless fn
    a1 = file2array(fn1)
    a2 = file2array(fn2)

    a = a1 & a2
    
    File.open(fn, 'w') {|f| f.write a.join("\n")}
  end

  def file2array(fn)
    []
  end

end

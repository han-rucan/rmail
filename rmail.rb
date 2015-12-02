# coding: utf-8
require 'net/pop'
require 'pp'

POP_USER = 'phyl02'
POP_PASS = 'td6u59Uxq'
POP_ADDR = 'mail2.eleusi.com'
POP_PORT = 110

def confronta_liste(fn1, fn2, fn=nil)
  fn = "#{fn1.gsub('.','-')}***#{fn2.gsub('.','-')}.txt" unless fn
  a1 = file2array(fn1)
  a2 = file2array(fn2)

  a = a1 & a2
  
  File.open(fn, 'w') {|f| f.write a.join("\n")}
end

def file2array(fn)
  a = []
  File.open(fn,'r').each_line {|l| a << get_address(l)}
  a
end

def get_subject(ss)
  get_header('Subject',ss)
end

def get_sender(ss)
  get_header('From',ss)
end

def get_header(hh,ss)
  head = ss.scan(/^#{hh}: (.*)$/)
  head && head.flatten[0] && head.flatten[0].chomp || ''  
end

def get_address(ss)
  appo = ss.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i)
  appo && appo[0]
end

def filter_by_sub(m, sub, testo, indirizzi, scan_head, del=false)
  if sub.match(testo)
    puts sub
    m.pop do |chunk|    # get a message little by little.
      m2 = chunk.match(scan_head)
      addr = get_address(chunk) if m2

      if addr
        puts addr
        unless indirizzi.include?(addr)
          indirizzi[addr] = 1
          puts "Aggiunto a lista #{testo}: #{addr}"
        else
          indirizzi[addr] += 1
        end
      end

    end
    m.delete if del # se incontra il criterio di filtro ed è stata
                    # richiesta la cancellazione elimino il messaggio
  end

end

def write_list(ln, fn)
  File.open(fn,'w') do |f|
    ln.each_key do |k|
      f.puts "#{k};#{ln[k]}"
    end
  end    
end

def write_array(ln, fn)
  File.open(fn,'w') do |f|
    ln.each do |s|
      f.puts s
    end
  end    
end

indirizzi = {}
rimozioni = {}
delivery_notifications = {}
subjects  = []

pop_addr = POP_ADDR
pop_port = POP_PORT
pop_user = POP_USER
pop_pass = POP_PASS

if ARGV.include?('confronta')
  ix = ARGV.index('confronta')
  fn1 = ARGV[ix+1]
  fn2 = ARGV[ix+2]
  fn3 = ARGV[ix+3]

  unless fn1 && fn2
    puts "rmail confronta file1 file2 file_esito"
    exit
  end

  confronta_liste(fn1, fn2, fn3)
  exit
end

Net::POP3.start(pop_addr, pop_port, pop_user, pop_pass) do |pop|
  if pop.mails.empty?
    puts 'NO MAIL.'
  else
    if ARGV.include?('check')
      puts "Messaggi: #{pop.mails.size}"

    else
      i = 0
      pop.each_mail do |m|   # or "apop.mails.each ..."
        sub = get_subject(m.header)

        subjects << sub unless subjects.include? sub

        filter_by_sub(m, sub, /Posta non consegnata(.*)/, indirizzi, /^To:/, true)
        filter_by_sub(m, sub, /Delivery Status Notification(.*)/, indirizzi, /RCPT TO:/, true)
        filter_by_sub(m, sub, /failure notice(.*)/, indirizzi, /^To:/, true)
        filter_by_sub(m, sub, /DELIVERY FAILURE(.*)/, indirizzi, /^To:/, true)
        filter_by_sub(m, sub, /Undelivered Mail Returned to Sender(.*)/, indirizzi, /^To:/, true)
        filter_by_sub(m, sub, /CHIEDO RIMOZIONE LISTA(.*)/, rimozioni, /^From:/)

        i += 1
      end

      write_list(indirizzi, 'indirizzi_errati.txt')
      write_list(rimozioni, 'rimozioni_lista.txt')
      write_array(subjects, 'subjects.txt')

      puts "#{pop.mails.size} mails popped."
    end
  end

end

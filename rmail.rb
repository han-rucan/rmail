require 'net/pop'
require 'pp'

def get_subject(ss)
  conta = 0
  sub = ss.scan(/^Subject: (.*)$/)
  sub && sub.flatten[0] && sub.flatten[0].chomp || ''
end

def get_sender(ss)
  conta = 0
  from = ss.scan(/^From: (.*)$/)
  from && from.flatten[0] && sub.flatten[0].chomp || ''
end

def get_address(ss)
  ss.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i)
end

def filter_by_sub(m, sub, testo, indirizzi, scan_head)

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
  end

end

indirizzi = {}
rimozioni = {}
subjects  = []

Net::POP3.start('mail2.eleusi.com', 110, 'phyl02', 'td6u59Uxq') do |pop|
  if pop.mails.empty?
    puts 'No mail.'
  else
    i = 0
    pop.each_mail do |m|   # or "apop.mails.each ..."
      sub = get_subject(m.header)

      subjects << sub unless subjects.include? sub

      filter_by_sub(m, sub, /Posta non consegnata (.*)/, indirizzi, /^To:/)
      filter_by_sub(m, sub, /CHIEDO RIMOZIONE LISTA (.*)/, rimozioni, /^From:/)

      i += 1
    end

    File.open('indirizzi_errati.txt','w') do |f|
      indirizzi.each_key do |i|
        f.puts "#{i};#{indirizzi[i]}"
      end
    end

    File.open('rimozioni_lista.txt','w') do |f|
      rimozioni.each_key do |i|
        f.puts "#{i};#{rimozioni[i]}"
      end
    end

    File.open('subjects.txt','w') do |f|
      subjects.each do |s|
        f.puts s
      end
    end
    
    puts "#{pop.mails.size} mails popped."
  end
end

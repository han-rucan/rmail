require 'mail'
require 'net/smtp'
require 'pp'
require 'yaml'

def load_conf(srv)
  y = YAML.load_file('setup.yml')

  puts "load server config #{srv}"  
  a = y[srv]

  Mail.defaults do
    delivery_method :smtp, {
                      address: a['address'],
                      port: a['port'],
                      user_name: a['user_name'],
                      password: a['password'],
                      authentication: a['authentication'],
                      enable_starttls_auto: a['enable_starttls_auto']
                    }
  end
  
end

def send_email appo, pfrom, psubj, email_body
  mail = Mail.deliver do
    bcc     appo
    from    pfrom
    subject psubj

    html_part do
      content_type 'text/html; charset=UTF-8'
      body email_body.to_s
    end
  end
end


srv = ARGV[0]

if srv == 'help'
  puts "Usage"

  puts "ruby smail.rb server_config_name addresses_file_name subject from interval undisclosed_groups"
  exit
end

load_conf(srv)

ebody = ARGV[1]

email_body = File.open(ebody,'r').read

addresses = ARGV[2]

psubj = ARGV[3]

pfrom = ARGV[4]

interval = ARGV[5] || 0

group_address = ARGV[6] && ARGV[6].to_i || 10

ln = "log-%s-%s"%[ebody,addresses]
ln.gsub!('.','-')
en = "err-%s-%s"%[ebody,addresses]
en.gsub!('.','-')

log_file = Logger.new File.join('log',ln + '.txt')
err_file = Logger.new File.join('log',en + '.txt')

conta = 0
err_count = 0
appo = []

indirizzif = File.open(addresses,'r')
indirizzif.each_line do |l|
  if l[0] == '#'
    err_file.error "skipping #{l}"
    next unless indirizzif.eof?
  else
    appo << l.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i)
    conta += 1
  end

  if appo.count == group_address || indirizzif.eof?
    begin
      indirizzi = appo.join(',')
      send_email indirizzi, pfrom, psubj, email_body
   rescue Exception => e
      err_count += 1
      puts e.message  
      puts e.backtrace.inspect
      err_file.error "%d %s %s"%[err_count, e.message, e.backtrace.inspect]
    end
    appo.clear

    #puts "email sent to #{indirizzi} of #{conta}"
    log_file.info "email sent to #{indirizzi} of #{conta}"    
    sleep interval.to_i      
  else
    next
  end


end

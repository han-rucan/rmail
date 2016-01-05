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

srv = ARGV[0]

if srv == 'help'
  puts "Usage"

  puts "ruby smail.rb server_config_name addresses_file_name subject from interval"
  exit
end

load_conf(srv)

ebody = ARGV[1]

email_body = File.open(ebody,'r').read

addresses = ARGV[2]

psubj = ARGV[3]

pfrom = ARGV[4]

interval = ARGV[5] || 0

conta = 0
indirizzi = File.open(addresses,'r').each_line do |l|
  conta += 1
  appo = l.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i)
  
  begin
    mail = Mail.deliver do
      to      appo
      from    pfrom
      subject psubj

      html_part do
        content_type 'text/html; charset=UTF-8'
        body email_body.to_s
      end
    end

    puts "email sent to #{appo} of #{conta}"
    sleep interval.to_i
  rescue Exception => e  
    puts e.message  
    puts e.backtrace.inspect
  end
end

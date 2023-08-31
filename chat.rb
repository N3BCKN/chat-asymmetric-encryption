require 'socket'

PORT = 2000

class Server
  def initialize 
    @server = TCPServer.open(PORT)    
    @clients = []
  end 

  def run
    loop do             
      Thread.start(@server.accept) do |client|
       @clients << client 
   
       client.puts 'Welcome to the chat!'
       client.puts "It's #{Time.now.utc.strftime("%d/%m/%Y %I:%M %p")} and currently there are #{@clients.size - 1} active users"
       client.puts 'What is your nickname?'
      
       nickname = client.gets.chomp
       client.puts "Hello #{nickname}, enjoy the conversation!"
       
       begin
        while message = client.gets.chomp
          broadcast(nickname, client, message)
        end
       rescue
        client.close
        @clients.delete(client)
        broadcast('SYSTEM', nil, "#{nickname} left chat" )
       end
      end
    end
  end

  private
  def broadcast(nickname, sender, message)
    @clients.each do |client|
      unless client == sender 
        client.puts "#{Time.now.utc.strftime("%I:%M %p")}, #{nickname}: #{message}"
      end 
    end 
  end

  def nickname_valid?(nickname)
    
  end 
end 


server = Server.new 
server.run


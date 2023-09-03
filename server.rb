require 'socket'

PORT = 2000
ConnectedClient = Struct.new(:socket, :username)

class Server
  def initialize 
    @server  = TCPServer.open(PORT)
    @clients = []
  end 

  def run
    loop do            
      Thread.start(@server.accept) do |client|   
        client.puts 'Welcome to the chat!'
        client.puts "It's #{server_time("%d/%m/%Y %I:%M %p")} and currently there are #{@clients.size} active users"
        client.puts 'What is your nickname?'
        nickname = ''
      
        loop do 
          nickname = client.gets.chomp
          break if nickname_valid?(nickname)
          client.puts 'invalid nickname. Please try again'
        end 

        client.puts "Hello #{nickname}, enjoy the conversation!"
        broadcast("SYSTEM: #{nickname} enters the chat")
        connected_client = ConnectedClient.new(client, nickname)
        @clients << connected_client
        
        begin
          while message = client.gets.chomp
            broadcast(connected_client, "#{nickname}: #{message}")
          end
        rescue
          client.close
          @clients.delete(connected_client)
          broadcast("SYSTEM: #{nickname} left chat" )
        end
      end
    end
  end

  private
  def broadcast(sender = nil, message)
    @clients.each do |client|
      unless client == sender 
        client.socket.puts "#{server_time}> #{message}"
      end 
    end 
  end

  def nickname_valid?(nickname)
    ((3...20).include? nickname.size) && (@clients.none? {|client| client.username == nickname})
  end 

  def server_time(format = "%I:%M %p")
    Time.now.utc.strftime(format)
  end 
end 


server = Server.new 
server.run


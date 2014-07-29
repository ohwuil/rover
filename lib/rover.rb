require 'socket'

include Socket::Constants

module Rover

  class Rover

    def initialize( host = "192.168.1.100", port = 80, target_id = 'AC13', target_password = 'AC13')
      @HOST = host
      @PORT = port
      @TARGET_ID = target_id
      @TARGET_PASSWORD = target_password
      setup_treads
      connect
    end

    def right_tread
      @right_tread
    end

    def left_tread
      @left_tread
    end

    def left_turn x
      direction = x > 0 ? -1 : 1

      x.abs.times do
        set_treads direction, 0
        sleep 2
      end

    end

    def right_turn x
      direction = x > 0 ? -1 : 1
      x.abs.times do
        set_treads 0, direction
        sleep 2
      end
    end

    def crawl x
      shimmy = x > 0 ? -1 : 1

      x.abs.times do
        set_treads shimmy, 0
        sleep 1
        set_treads 0, shimmy
        sleep 1
        set_treads 0, 0
      end
    end

    def connect
      begin
        do_connect
      rescue Exception => e
        puts "Rescue from connect::  #{e}"
      ensure

      end
    end

    def do_connect
      puts "Connecting...."
      setup_socket
      connect_with_rover
      #start_keep_alive_task
      setup_camera
      signal_connection
    end

    def disconnect
      @Socket.close
    end

    def set_treads left, right
      @left_tread.update(left)
      @right_tread.update(right)
    end

    def lights_on
      set_lights 8
    end

    def lights_off
      set_lights 9
    end

    def spin_wheels( wheeldir, speed )
      send_device_control_request( wheeldir, speed )
    end

    private

    def create_key reply
      camera_id = reply[25...37].force_encoding("utf-8")
      @TARGET_ID + ':' + camera_id + '-save-private:' + @TARGET_PASSWORD
    end

    def signal_connection
      lights_on
      sleep 1
      lights_off
      puts "===CONNECTED==="
    end

    def setup_socket(timeout = 1)
      @Socket.close if !@Socket.nil?
      puts "@HOST = #{@HOST}"
      addr = Socket.getaddrinfo(@HOST, nil)
      sockaddr = Socket.pack_sockaddr_in(@PORT, addr[0][3])

      @Socket = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0).tap do |socket|
        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

        begin
          socket.connect_nonblock(sockaddr)

        rescue IO::WaitWritable
          # IO.select will block until the socket is writable or the timeout
          # is exceeded - whichever comes first.
          if IO.select(nil, [socket], nil, timeout)
            begin
              # Verify there is now a good connection
              socket.connect_nonblock(sockaddr)
            rescue Errno::EISCONN
              # Good news everybody, the socket is connected!
            rescue
              # An unexpected exception was raised - the connection is no good.
              socket.close
              raise
            end
          else
            # IO.select returns nil when the socket is not ready before timeout
            # seconds have elapsed
            socket.close
            raise "Connection timeout"
          end
        end
      end
    end

    def set_lights onoff
      send_device_control_request onoff, 0
    end

    def bytes_to_int( bytes, offset)
      offset_plus_4 = offset+4
      bytes[offset..offset_plus_4].unpack("I").first
    end

    def start_keep_alive_task
      send_command_byte_request 255
    end

    def send_device_control_request(a, b)
      send_command_byte_request 250, [a, b]
    end

    #def _startKeepaliveTask(self,):
    #    self._sendCommandByteRequest(255)
    #   self.keepalive_timer = \
    #        threading.Timer(self.KEEPALIVE_PERIOD_SEC, self._startKeepaliveTask, [])
    #self.keepalive_timer.start()

    def send_command_byte_request(id, bytes=[])
      send_command_request(id, bytes.length, bytes)
    end

    def send_command_int_request(id, intvals)
      bytevals = []
      intvals.pack("L*").each_char { |i|  bytevals << i.ord }
      send_command_request(id, 4*intvals.size, bytevals)
    end

    def send_command_request(id, n, contents)
      send_request('O', id, n, contents)
    end

    def send_request(c, id, n, contents)
      bytes = ['M'.ord, 'O'.ord, '_'.ord, c.ord, id, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, n, 0, 0, 0, 0, 0, 0, 0]
      bytes = bytes + contents
      request = bytes.collect{ |b| b.chr}.join

      response = @Socket.send(request, 0)
    end

    def receive_command_reply(count)
      @Socket.recv(count)
    end

    def opening_rover_ping
      send_command_int_request(0, [0, 0, 0, 0])
      receive_command_reply(82)
    end

    def setup_treads
      @left_tread = RoverTread.new(self, 4)
      @right_tread = RoverTread.new(self, 1)
    end

    def connect_with_rover

      rover_response = opening_rover_ping
      key = create_key rover_response

      # Extract Blowfish inputs from rest of reply
      l1 = bytes_to_int(rover_response, 66)
      r1 = bytes_to_int(rover_response, 70)
      l2 = bytes_to_int(rover_response, 74)
      r2 = bytes_to_int(rover_response, 78)

      blowfish = Blowfish.new key

      l1,r1 = blowfish.encrypt(l1, r1)
      l2,r2 = blowfish.encrypt(l2, r2)

      # Send encrypted reply to Rover
      send_command_int_request(2, [l1, r1, l2, r2])

      # Ignore reply from Rover
      receive_command_reply(26)
    end

    def setup_camera
      ## TODO set up the camera

      # # Set up camera position
      # self.cameraIsMoving = False

      # # Send video-start request
      # self._sendCommandIntRequest(4, [1])

      # # Get reply from Rover
      # reply = receive_command_reply(29)

      # reply = self._receiveCommandReply(29)

      # # Create media socket connection to Rover
      # self.mediasock = self._newSocket()

      # # Send video-start request based on last four bytes of reply
      # self._sendRequest(self.mediasock, 'V', 0, 4, map(ord, reply[25:]))

      # # Send audio-start request
      # self._sendCommandByteRequest(8, [1])

      # # Ignore audio-start reply
      # self._receiveCommandReply(25)

      # # Receive images on another thread until closed
      # self.is_active = True
      # self.reader_thread = _MediaThread(self)
      # self.reader_thread.start()

    end
  end

end

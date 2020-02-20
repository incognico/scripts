#!/usr/bin/env python
import os, time, socket, datetime

# SETTINGS START

host = '127.0.0.1'
port = 27015

check_delay_seconds = 10
unresponsive_max_seconds = 60 * 5
unresponsive_command = 'kill $(pidof svends_i686) ; kill -9 $(pidof svends_i686)'

# SETTINGS END

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.settimeout(1.5) # Packets are only sent once with UDP, so this should just be the max expected latency to the server
sock.connect((host, int(port)))

last_responsive = time.time()
is_responsive = False
first_check = True
while True:
        curtime = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S") + "  "
        
        if is_responsive:
                last_responsive = time.time()
        
        try:
                sock.send(b'\xFF\xFF\xFF\xFFgetchallenge\n')
                sock.recv(32)
                if not is_responsive or first_check:
                        print("%s Server is responsive" % curtime)
                        is_responsive = True # don't flood the console
        except Exception as e:
                unresponsive_time = time.time() - last_responsive
                
                if unresponsive_time > unresponsive_max_seconds:
                        print("%s Server hasn't responded for %.1f minutes. Time to restart." % 
                                (curtime, (unresponsive_max_seconds/60.0)))
                        is_responsive = True
                        os.system(unresponsive_command)
                else:
                        if is_responsive or first_check:
                                is_responsive = False
                                print("%s %s" % (curtime, e))
                                print("%s Server not responding. %.1f minutes until restart." % (curtime, unresponsive_max_seconds / 60.0))
        
        first_check = False
        
        time.sleep(check_delay_seconds)

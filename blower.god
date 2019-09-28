God.watch do |w|
  w.name = 'Blower'
  w.start = 'ruby /home/pi/bathroom-blower-rpi/main.rb'
  w.log = '/home/pi/bathroom-blower-rpi/log/god-process.log'
  w.keepalive
end

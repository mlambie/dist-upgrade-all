#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
require 'shellwords'
require 'appscript'
require 'slop'

DEBUG = false

class Host
  attr_reader :name, :login
  def initialize(name, login = ENV['USER'])
    @name = name
    @login = login
  end
end

class Terminal
  include Appscript
  attr_reader :terminal, :current_window
  def initialize
    @terminal = app('Terminal')
    @current_window = terminal.windows.first
    yield self
  end

  def tab(command, mode = 't')
    app('System Events').application_processes['Terminal.app'].keystroke(mode, :using => :command_down)
    run command
  end

  def maximize
    # This depends on Divvy
    app('System Events').application_processes['Terminal.app'].keystroke('m', :using => [:command_down, :option_down, :control_down])
  end

  def run(command)
    command = command.shelljoin if command.is_a?(Array)
    if command && !command.empty?
      terminal.do_script(command, :in => current_window.tabs.last)
    end
  end
end

def hosts
  hosts = Array.new
  begin
    IO.readlines(File.join(File.dirname(__FILE__), 'hosts.conf')).each do |line|
      # Strip out anything that's a comment
      line = line.sub(/#.*/, "").strip
      next if line.empty?
      if line.include?("@")
        line = line.split("@")
        hosts << Host.new(line[1], line[0])
      else
        hosts << Host.new(line)
      end
    end
  rescue Exception => e
    abort "ERROR: #{e}"
  end
  hosts
end

def cmd_exec(login, name)
  if @opts.monit?
    monit_off = 'if [ -x "/usr/sbin/monit" ]; then echo "[MONIT] Unmonitoring all services" && sudo /usr/sbin/monit unmonitor all && sleep 10; fi'
    monit_on  = 'if [ -x "/usr/sbin/monit" ]; then echo "[MONIT] Monitoring all services" && sudo /usr/sbin/monit monitor all; fi'
  else
    monit_off = monit_on = 'echo -n'
  end
  aptitude = "sudo aptitude update && sudo aptitude dist-upgrade -y && sudo aptitude clean"
  
  "ssh #{login}@#{name} -t 'clear && #{monit_off} && #{aptitude} && #{monit_on} && exit' && exit"
end

def cmd_echo(login, name)
  "echo TRACE: ssh #{login}@#{name} && sleep 10 && exit"
end

if DEBUG
  alias :cmd :cmd_echo
else
  alias :cmd :cmd_exec
end

@opts = Slop.parse do
  on :m, :monit, 'Your password', :optional_argument => true
end

first = true
Terminal.new do |t|
  hosts.each do |h|
    sleep 1
    if first == true
      t.tab(cmd(h.login, h.name), 'n')
      t.maximize
      first = false
    else
      t.tab(cmd(h.login, h.name))
    end
  end
end

#!/usr/bin/env ruby

require 'rubygems'
require 'shellwords'
require 'appscript'

class Host
  attr_reader :name, :login
  def initialize(name, login = 'mlambie')
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

  def run(command)
    command = command.shelljoin if command.is_a?(Array)
    if command && !command.empty?
      terminal.do_script(command, :in => current_window.tabs.last)
    end
  end
end

def hosts
  hosts = Array.new
  servers = %w{arcee astrotrain blaster blitzwing broadside cliffjumper inferno ironhide jazz laserbeak mirage prime prowl ravage rumble}
  servers += %w{bizox csd cw-production cw-staging imeducate imports101 mg synaptor tapdoctor}
  servers += %w{ilca-lb ilca-db ilca-web-01 ilca-web-02}
  servers.each do |s|
    hosts << Host.new("#{s}.thefrontiergroup.net.au") 
  end
  6.times {|x| hosts << Host.new("ipv-app-0#{x + 1}.thefrontiergroup.net.au", 'ipv') }
  hosts << Host.new('mail.ilc.com.au')
end

first = true
Terminal.new do |t|
  hosts.each do |h|
    sleep 1
    cmd = "ssh #{h.login}@#{h.name} -t 'sudo aptitude update && sudo aptitude dist-upgrade -y && sudo aptitude clean && exit' && exit"
    if first == true
      t.tab(cmd, 'n')
      first = false
    else
      t.tab(cmd)
    end
  end
end

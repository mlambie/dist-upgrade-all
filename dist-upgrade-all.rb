#!/usr/bin/env ruby

require 'rubygems'
require 'shellwords'
require 'appscript'

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

  private
  def run(command)
    command = command.shelljoin if command.is_a?(Array)
    if command && !command.empty?
      terminal.do_script(command, :in => current_window.tabs.last)
    end
  end
end

Terminal.new do |t|
  t.tab("htop && exit")
  t.tab("htop && exit")
  t.tab("htop && exit")
end

#!/usr/bin/ruby
require 'xml/libxml'
require 'optparse'

class XML::Document
  def gather(path)
    ret = []
    self.find(path).each {|n| ret.push n}
    ret
  end
end

class XML::Node
  def children
    doc.gather(self.path + "/*")
  end
end

class Valsi
  attr_reader :node, :word, :type, :definition, :selmaho, :notes, :rafsi
  def initialize(node)
    @node = node
    @word = node['word']
    @type = node['type']
    @definition = nil
    @selmaho = nil
    @notes = nil
    @rafsi = []
    
    node.children.each do |child|
      case child.name
      when "definition"
        @definition = child.child.to_s.gsub(/\$([a-z])_\{?([0-9])\}?\$/) { |s| "#{$1}#{$2}"}
      when "selmaho"
        @selmaho = child.child.to_s
      when "notes"
        @notes = child.child.to_s
      when "rafsi"
        @rafsi.push child.child.to_s
      end
    end
  end
  
  def to_s
    case @type
    when "cmavo"
      "#{@word} (#{@selmaho}): #{@definition}"
    else
      "#{@word}: #{@definition}"
    end
  end
end

class Vlaste
  def initialize(filename)
    @doc = XML::Document.file(filename)
  end
  
  def find(what, type=nil)
    case type
    when :rafsi
      find_by_rafsi(what)
    when :valsi
      find_by_valsi(what)
    when :def
      find_in_definition(what)
    when :natword
      find_natword(what)
    else
      find_by_rafsi(what) + find_by_valsi(what) + find_in_definition(what) + find_natword(what)
    end
  end
  
  def find_by_rafsi(rafsi)
    @doc.gather("//valsi[rafsi=\"#{rafsi.gsub(/[Hh]/,"'")}\"]").map {|v| Valsi.new(v)}
  end
  
  def find_by_valsi(valsi)
    @doc.gather("//valsi[@word=\"#{valsi.gsub(/[Hh]/, "'")}\"]").map {|v| Valsi.new(v)}
  end
  
  def find_in_definition(what)
    @doc.gather("//valsi[contains(definition, \"#{what}\")]").map {|v| Valsi.new(v)}
  end
  
  def find_natword(word)
    @doc.gather("//nlword[@word=\"#{word}\"]").map {|n| find_by_valsi(n['valsi'])[0]}
  end
end

jvs = Vlaste.new('jbo-en.xml')

OptionParser.new do |o|
  o.banner = "Usage: jvs.rb [options]"
  
  o.on("-r", "--rafsi [rafsi]", "Perform lookup by rafsi.") do |r|
    jvs.find(r, :rafsi).each {|valsi| puts valsi}
    exit
  end
  
  o.on("-v", "--valsi [valsi]", "Perform lookup by valsi.") do |v|
    jvs.find(v, :valsi).each {|valsi| puts valsi}
    exit
  end
  
  o.on("-d", "--definition [what]", "Perform lookup by (partial) definition.") do |v|
    jvs.find(v, :def).each {|valsi| puts valsi}
  end
  
  o.on("-n", "--natword [word]", "Perform lookup by natword.") do |v|
    jvs.find(v, :natword).each {|valsi| puts valsi}
  end
  
  o.on("-a", "--all [word]", "Perform lookup by all methods.") do |v|
    jvs.find(v).each {|valsi| puts valsi}
  end
end.parse!

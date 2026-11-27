#!/usr/bin/env ruby
# Convert a DOCX to an XML-compatible HTML fragment using Pandoc.
require 'rexml/document'
require 'optparse'
require 'open3'

options = {}
parser = OptionParser.new do |opts|
  opts.banner = 'Usage: ruby docx_to_xml.rb [options] FILE.docx > fragment.xml'
  opts.on('--from TEXT', 'Include the top-level paragraph or heading matching TEXT') { |v| options[:from] = v }
  opts.on('--after TEXT', 'Start after the top-level paragraph or heading matching TEXT') { |v| options[:after] = v }
  opts.on('-h', '--help', 'Show this help') { puts opts; exit }
end
begin
  parser.parse!
  raise ArgumentError, parser.to_s unless ARGV.length == 1
  raise ArgumentError, 'Use either --from or --after, not both' if options[:from] && options[:after]
  html, errors, status = Open3.capture3('pandoc', ARGV.first, '--from=docx', '--to=html5', '--wrap=none')
  warn errors unless errors.empty?
  raise 'Pandoc conversion failed' unless status.success?
  # Parsing the wrapped fragment checks that it can be pasted into an XML file.
  doc = REXML::Document.new("<root>#{html}</root>")
  nodes = doc.root.elements.to_a
  marker = options[:from] || options[:after]
  if marker
    matches = nodes.each_index.select do |i|
      e = nodes[i]
      %w[p h1 h2 h3 h4 h5 h6].include?(e.name) && REXML::XPath.match(e, './/text()').map(&:value).join == marker
    end
    raise "Starting paragraph not found or not unique: #{marker.inspect}" unless matches.length == 1
    nodes = nodes.drop(matches.first + (options[:after] ? 1 : 0))
  end
  output = +''
  nodes.each { |node| node.write(output); output << "\n" }
  puts output
rescue StandardError => e
  warn "Error: #{e.message}"
  exit 1
end

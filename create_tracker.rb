require 'date'
require_relative 'tracker'

tracker = Tracker.new(parent_id: ENV['NOTION_PARENT_ID'])
tracker.run(Date.new(2022, 1, 1))

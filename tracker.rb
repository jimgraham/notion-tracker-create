require 'date'
require 'pp'
require 'notion'

class Tracker
  
  TITLE_EMOJI = "👟"
  
  # Add columns you want here
  CHECK_COLUMNS = [
    "🏃🏼‍♂️Exercise",
    "Stretch",
    "🧘🏽‍♀️Mindfulness",
    "✍🏼Write",
    "📕Read",
  ]
  
  def initialize(args)
    @client = Notion::Client.new(token: ENV['NOTION_API_TOKEN'])
    @parent_id = args[:parent_id]
  end
  
  def fetch_properties()
    #-- notion API orders properties alphabetically :(
    ordering = "a"
    properties = {
      "Day" => { "title" => {} },
      "#{ordering} Date" => { "date" => {}}
    }
    ordering.next!
    CHECK_COLUMNS.each do |col|
      properties[ordering + " " + col] = { "checkbox" => {} }
      ordering.next!
    end
    
    properties["#{ordering} Note"] = { "rich_text" => {} }
    properties
  end
  
  def fetch_filled_properties(date)
    #-- notion API orders properties alphabetically :(
    ordering = "a"
    properties = {
      "Day" => { "title" => [{"text": {"content": date.strftime("%A")}}]},
      "#{ordering} Date" => { "date" => {"start": date.to_s}},
    }
    ordering.next!
    CHECK_COLUMNS.each do |col|
      properties[ordering + " " + col] = { "checkbox" => false}
      ordering.next!
    end
    
    properties["#{ordering} Note"] = { "rich_text" => [{"text": {"content": ""}}] }
    properties
  end
    
  def create_track_databases(start_date)
    end_date = Date.new(start_date.year, -1, -1)
    while ( start_date < end_date)
      database_id = create_month_database start_date
      fill_month_database(database_id, start_date)
      
      start_date = start_date.next_month
    end
  end

  def create_month_database( start_date)
    first_of_month = Date.new(start_date.year, start_date.month, 1)

    title = [
      "type" => "text",
      "text" => {
        "content": first_of_month.strftime("%B %Y")
      }
    ]
    properties = fetch_properties
    response = @client.create_database(
      parent: { page_id: @parent_id },
      title: title,
      icon: { "type": "emoji", "emoji": TITLE_EMOJI },
      properties: properties
    )

    response["id"]
  end
  
  def fill_month_database(database_id, start_date)
    puts "Creating database for: " + start_date.strftime("%B %Y") + "\n\n"
    
    end_of_month = Date.new(start_date.year, start_date.month, -1)
    end_of_month.downto(start_date) do |day|
      puts "Creating page for: " + day.strftime("%A") + "\n"

      properties = fetch_filled_properties(day)
      @client.create_page(
        parent: { database_id: database_id },
        properties: properties
      )
    end
  end

  def run(start_date)
    create_track_databases(start_date)
  end
end

#Crawler

require 'net/http'
require 'win32ole'

class Crawler
  def initialize(server, username, password, sought_for)
    @server, @username, @password, @sought_for = 
      server, username, password, sought_for
  end
  
  def start_excel
    @@excel = WIN32OLE.new('Excel.Application')
    @@excel.Visible, @@excel.DisplayAlerts = false, false
  end
  
  def quit_excel
    @@excel.quit
  end
  
  def get_page(path)
    http = Net::HTTP.new(@server, 80)
    request = Net::HTTP::Get.new(path)
    request.basic_auth @username, @password   #remove if not necessary
    response = http.request(request)
    page = response.body
  end

  def get_links(page)
    links = []
    page.scan(/<A HREF="[^"]+">/).each { |link|
      links.push link[link.index('"') + 1 .. link.rindex('"') - 1]
    }
    links.delete_at 0
    links
  end

  def go(path, depth)
    print path, "\n"
    page = get_page(path)
    print page
    links = get_links(page)
    if (depth == 0)
      1.upto(links.size-37) do links.delete_at(0) end
    end
    links.each do |link|
      extension = link[-4..link.size-1].downcase
      if ".xls" == extension then
        open("current.xls", "wb") { |file| 
          file.write(get_page(link)) 
        }
        begin
          workbook = @@excel.Workbooks.Open(Dir.getwd + '/current.xls')
          1.upto(workbook.worksheets.count) { |i|
            if workbook.worksheets(i).cells.Find(@sought_for) then
              File.open("found.txt", "a") do |file|
                file.puts link
              end
            end
          }
          workbook.close
        rescue => error
          puts error
        end
      end
      if "/" == link[link.size-1..link.size-1] then
        go(link, depth + 1) if depth < 2
      end
    end
  end
end

crawler = Crawler.new("www.target.web-site.ru", 'username', 'password', "find_text")
crawler.start_excel
current_path = "~home"
crawler.go(current_path, 0)
crawler.quit_excel

require "javlibrary/version"

require 'mechanize'
require 'rest-client'
require 'nokogiri'
require 'mysql2'
require 'pp'

class Javlibrary
    JAVLIBRARY_URL = [ "jav11b.com", "javlibrary.com" ]

    def initialize(database_name = 'javlibrary', user = 'root', pwd = 'default')
        # Define client variable
        @database = database_name
        @username = user
        @password = pwd

        # Define default Javlibrary url
        @url = JAVLIBRARY_URL[1]
    end

    attr_accessor :database, :username, :password, :url

    def client()
        client = Mysql2::Client.new(:host => "127.0.0.1",
                                    :username => "#{@username}",
                                    :password => "#{@password}",
                                    :database => "#{@database}")
    end

    def downloader(identifer)
        baseurl = "http://www.#{@url}/cn/?v=#{identifer}"
        response = Mechanize.new
        response.user_agent = Mechanize::AGENT_ALIASES.values[rand(21)]
        begin
            response.get baseurl
        rescue Timeout::Error
            retry
        rescue
            return
        end

        doc = Nokogiri::HTML(response.page.body)

        video_title, details, video_genres, video_jacket_img = String.new, Array.new, String.new, String.new

        video_title = doc.search('div[@id="video_title"]/h3/a').children.text
        doc.search('//div[@id="video_info"]/div[@class="item"]/table/tr/td[@class="text"]').map do |row|
            details << row.children.text
        end

        doc.search('//div[@id="video_genres"]/table/tr/td[@class="text"]/span[@class="genre"]/a').each do |row|
            video_genres << row.children.text << " "
        end

        doc.search('//img[@id="video_jacket_img"]').each do |row|
            video_jacket_img = row['src']
        end

        # return data format: title$id$date$director$maker$label$cast$genres$img_url
        "#{video_title}$#{details[0]}$#{details[1]}$#{details[2]}$#{details[3]}$#{details[4]}$#{details[-1]}$#{video_genres}$#{video_jacket_img}"
        #result = Hash.new
        #result["title"] = video_title; result["id"] = details[0]; result["date"] = details[1]
        #result["director"] = details[2]; result["maker"] = details[3]; result["label"] = details[4]
        #result["cast"] = details[-1]; result["genres"] = video_genres; result["img_url"] = video_jacket_img
    end

    def video_info_insert(index, identifer, actor_hash, genres_hash)
        client = client()

        result = downloader(identifer)

        return nil if result == nil
        title, id, date, director, maker, label, cast_tmp, genres_tmp, img_url = result.split('$')
        cast = cast_tmp.split.reject(&:empty?)
        genres = genres_tmp.split.reject(&:empty?)
        begin
            client.query("INSERT INTO video (video_id,video_name,license,url,director,label,date,maker)
            VALUES (#{index},'#{title}','#{id}','#{img_url}','#{director}','#{label}','#{date}','#{maker}')")
        rescue
            client.query("UPDATE label SET video_download=1 WHERE video_num=#{index}")
            return nil
        end
        cast.each do |a|
            a_tmp = actor_hash[a]
            next if a_tmp == nil
            begin
                client.query("INSERT INTO v2a (v2a_fk_video,v2a_fk_actor) VALUES(#{index}, #{a_tmp.to_i})")
            rescue
                next
            end
        end

        genres.each do |g|
            g_tmp = genres_hash[g]
            next if g_tmp == nil
            begin
                client.query("INSERT INTO v2c (v2c_fk_video,v2c_fk_category) VALUES(#{index}, #{g_tmp.to_i})")
            rescue
                next
            end
        end

        client.query("UPDATE label SET video_download=1 WHERE video_num=#{index}")
        client.close
    end

    def download_all_videos_thread
        client = client()
        result = client.query("SELECT video_num, video_label FROM label WHERE video_download=0")
        client.close

        video_array = Array.new
        result.each do |item|
            video_array << item
        end

        video_array = video_array.each_slice(5000).to_a

        actor_hash = actor_hash()
        genre_hash = genre_hash()
        thread_pool = Array::new

        video_array.each do |group|
            # Create a download thread
            thread_temp = Thread.new {
                group.each do |item|
                    begin
                        video_info_insert(item['video_num'], item['video_label'],
                            actor_hash, genre_hash)
                    rescue
                        next
                    end
                end
            }
            thread_pool << thread_temp
        end

        thread_pool.map(&:join)
    end

    def download_all_videos
        client = client()
        result = client.query("SELECT * FROM label WHERE video_download=0")
        client.close
        actor_hash = actor_hash()
        genre_hash = genre_hash()
        result.each do |item|
            begin
                video_info_insert(item['video_num'], item['video_label'],
                    actor_hash, genre_hash)
            rescue
                next
            end
        end
    end

    def actor_hash
        client = client()
        actor_hash = Hash.new
        client.query("SELECT * FROM actor").each do |item|
            actor_hash["#{item['actor_name']}"] = item['actor_id']
        end
        client.close

        actor_hash
    end

    def genre_hash
        client = client()
        category_hash = Hash.new
        client.query("SELECT * FROM category").each do |item|
            category_hash["#{item['category_name']}"] = item['category_id']
        end
        client.close

        category_hash
    end

    def genres
        response = Mechanize.new; genres = Array.new
        begin
            response.get "http://www.#{@url}/cn/genres.php"
        rescue
            retry
        end

        Nokogiri::HTML(response.page.body).search('//div[@class="genreitem"]/a').each do |row|
            genres << row.children.text
        end
        genres.uniq
    end

    def genres_insert
        client = client()
        genres = genres()
        genres.each do |e|
            begin
                client.query("INSERT INTO category (category_name) VALUES ('#{e}')")
            rescue
                next
            end
        end

        client.close
    end

    alias download_all_genres genres_insert

    def author_page_num(nokogiri_doc)
        last_page = 1
        nokogiri_doc.search('//div[@class="page_selector"]/a[@class="page last"]').each do |row|
            last_page = row['href'].split("=")[-1].to_i
        end
        last_page
    end

    def get_all_actor
        firsturl = "http://www.#{@url}/cn/star_list.php?prefix="

        client = client()
        'A'.upto('Z') do |alphabet|
            tempurl = firsturl + alphabet
            begin
                response = RestClient.get tempurl
            rescue
                retry
            end

            doc = Nokogiri::HTML(response.body)
            last_page = author_page_num(doc)

            1.upto(last_page) do |page_num|
                temp_page_url = tempurl + "&page=#{page_num.to_s}"
                begin
                    response_page = RestClient.get temp_page_url
                rescue
                    retry
                end

                doc_page = Nokogiri::HTML(response_page.body)
                doc_page.search('//div[@class="starbox"]/div[@class="searchitem"]/a').each do |row|
                    # row.text Actor.name
                    # row['href'].split("=")[-1] Actor.label
                    name = row.text; label = row['href'].split("=")[-1]
                    begin
                        client.query("INSERT INTO actor (actor_name, actor_label, type)
                            VALUES ('#{name}', '#{label}', '#{alphabet}')")
                    rescue
                        next
                    end
                end
            end
        end

        client.close
    end

    alias download_all_actors get_all_actor

    def download_video_label(actor_id)
        firsturl = "http://www.#{@url}/ja/vl_star.php?s=#{actor_id}"
        baseurl = "http://www.#{@url}/ja/vl_star.php?&mode=&s=#{actor_id}&page="

        begin
            response = RestClient.get firsturl
        rescue
            retry
        end

        doc = Nokogiri::HTML(response.body)
        last_page = 1
        doc.search('//div[@class="page_selector"]/a[@class="page last"]').each do |row|
            last_page = row['href'].split("=")[-1].to_i
        end

        result = []
        1.upto(last_page) do |page|
            tempurl = baseurl + page.to_s
            begin
                response = RestClient.get tempurl
            rescue
                retry
            end

            Nokogiri::HTML(response.body).search('//div[@class="video"]/a').each do |row|
                # Data:
                # Video_label: row['href'].split("=")[-1]
                # Video_title: row['title']
                # client.query("INSERT INTO label (lable) VALUES ('#{row['href'].split("=")[-1]}')")
                result << row['href'].split("=")[-1]
            end
        end

        client = client()
        result.each do |e|
            begin
                client.query("INSERT INTO label (video_label, video_download) VALUES ('#{e}', '0')")
            rescue
                next
            end
        end
        client.close
    end

    def select_actor(type)
        client = client()
        result = client.query("SELECT actor_label FROM actor WHERE type='#{type}'")
        client.close

        result.each do |e|
            download_video_label(e["actor_label"])
        end
    end

    def download_all_video_labels
        thread_pool =[]
        'A'.upto('Z').each do |alphabet|
            thread_temp = Thread.new{
                select_actor(alphabet)
            }
            thread_pool << thread_temp
        end
        thread_pool.map(&:join)
    end

    # module_function :client
    # module_function :download_all_videos
    # module_function :actor_hash, :genre_hash
    # module_function :genres_insert(download_all_genres)
    # module_function :get_all_actor(download_all_actors)
    # module_function :download_all_video_labels
end

note
	description: "simple client retrieving and displaying data from the Church Calendar API"
	date: "$Date$"
	revision: "$Revision$"

	-- based on
	-- * https://github.com/EiffelSoftware/EiffelStudio/blob/master/Src/examples/cURL/get_in_memory/application.e
	-- * https://github.com/eiffelhub/json/blob/master/examples/basic/basic.e
class
	APPLICATION

create
	make

feature {NONE} -- Initialization

	make
			-- Run application.
		local
			l_result: INTEGER
			l_curl_string: CURL_STRING
			json_parser: JSON_PARSER
		do
			if curl.is_dynamic_library_exists then
				create l_curl_string.make_empty
				curl.global_init
				curl_handle := curl_easy.init
				curl_easy.setopt_string (curl_handle, {CURL_OPT_CONSTANTS}.curlopt_url, "http://calapi.inadiutorium.cz/api/v0/en/calendars/default/today")

				-- Send all data to default Eiffel curl write function
				curl_easy.set_write_function (curl_handle)

				-- pass our `l_curl_string''s object id to the callback function
				curl_easy.setopt_integer (curl_handle, {CURL_OPT_CONSTANTS}.curlopt_writedata, l_curl_string.object_id)

				-- curl_easy.setopt_integer (curl_handle, {CURL_OPT_CONSTANTS}.curlopt_verbose, 1)

				-- todo: set custom User-Agent

				l_result := curl_easy.perform (curl_handle)
				curl_easy.cleanup (curl_handle)

				-- print response body
				if not l_curl_string.is_empty then
					print (l_curl_string)
					print ("%N%N")
				end

				create json_parser.make_with_string (l_curl_string)
				json_parser.parse_content

				if
					json_parser.is_valid and then
					attached {JSON_OBJECT} json_parser.parsed_json_value as j_object
				then
					-- print date
					if attached {JSON_STRING} j_object.item ("date") as date then
						print ("Date: " + date.unescaped_string_8 + "%N")
					end

					-- print season
					if attached {JSON_STRING} j_object.item ("season") as season then
						print ("Liturgical season: " + season.unescaped_string_8 + "%N")
					end

					-- print celebrations
					if attached {JSON_ARRAY} j_object.item ("celebrations") as celebrations then
						across
							1 |..| celebrations.count as c
						loop
							if attached {JSON_OBJECT} celebrations.i_th (c.item) as celebration then
								if attached {JSON_STRING} celebration.item ("rank") as rank then
									print (rank.unescaped_string_8)
									print (", ")
								end
								if attached {JSON_STRING} celebration.item ("title") as title then
									print (title.unescaped_string_8)
								end
								print ("%N")
							end
						end
					end
				else
					io.error.put_string ("JSON parsing mishap.")
				end

				curl.global_cleanup
			else
				io.error.put_string ("cURL library not found!")
				io.error.put_new_line
			end
		end

feature {NONE} -- Implementation

	curl: CURL_EXTERNALS
			-- cURL externals
		once
			create Result
		end

	curl_easy: CURL_EASY_EXTERNALS
			-- cURL easy externals
		once
			create Result
		end

	curl_handle: POINTER;
			-- cURL handle

end
